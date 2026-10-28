/*
 * Appel à l'API Google Gemini.
 *
 * La clé GEMINI_API_KEY vient des variables d'environnement de Netlify.
 * Elle n'est jamais envoyée à l'application.
 *
 * Google arrête régulièrement ses anciens modèles (gemini-1.5-flash, puis
 * gemini-2.5-flash pour les nouveaux comptes). Le nom du modèle est donc
 * réglable sans toucher au code, avec la variable GEMINI_MODEL dans Netlify.
 *
 * Quand Gemini est surchargé, il répond avec le code 503 (ou 429 si on envoie
 * trop de demandes), ou il ne répond pas du tout. Dans ce cas on passe au
 * modèle de secours (GEMINI_FALLBACK_MODEL) s'il est défini.
 */

export class GeminiError extends Error {
  constructor(message, status = 502) {
    super(message);
    this.status = status;
  }

  // true si Gemini est seulement surchargé : la demande pourra marcher plus tard.
  get isBusy() {
    return this.status === 503 || this.status === 429;
  }
}

// Netlify arrête une fonction au bout de 10 secondes : on garde une marge.
const TIME_LIMIT_MS = 9000;

// Temps maximum laissé au premier modèle. Il répond en général en 5 à 6
// secondes : on lui laisse 8 secondes. Le secours sert surtout quand le
// premier modèle refuse tout de suite (erreur 503, surcharge).
const FIRST_TRY_MS = 8000;

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/*
 * Envoie une demande à Gemini et renvoie le texte de la réponse.
 *
 * parts : le contenu envoyé (texte et éventuellement une image)
 * schema : si on le donne, Gemini doit répondre en JSON avec cette forme
 * models : la liste des modèles à essayer, dans l'ordre
 * thinkingLevel : facultatif, niveau de "réflexion" du modèle ('low' = plus rapide)
 */
export async function askGemini({ apiKey, models, parts, history = [], systemText, schema, thinkingLevel }) {
  const body = {
    contents: [...history, { role: 'user', parts }],
    generationConfig: {
      temperature: schema ? 0.2 : 0.7,
      // Les modèles récents "réfléchissent" avant de répondre, et cette réflexion
      // compte dans la limite : on laisse donc assez de place pour la réponse.
      maxOutputTokens: 4096,
    },
  };
  if (systemText) {
    body.systemInstruction = { parts: [{ text: systemText }] };
  }
  if (thinkingLevel) {
    body.generationConfig.thinkingConfig = { thinkingLevel };
  }
  if (schema) {
    body.generationConfig.responseMimeType = 'application/json';
    body.generationConfig.responseSchema = schema;
  }

  // On essaie les modèles dans l'ordre : le principal, puis le secours.
  const deadline = Date.now() + TIME_LIMIT_MS;
  let lastError;

  for (let i = 0; i < models.length; i++) {
    const isLast = i === models.length - 1;
    const timeLeft = deadline - Date.now();
    if (timeLeft < 1000) break;

    // S'il reste un modèle après celui-ci, on ne lui laisse pas tout le temps.
    const timeForThisModel = isLast ? timeLeft : Math.min(timeLeft, FIRST_TRY_MS);

    try {
      return await callModel({ apiKey, model: models[i], body, timeLeft: timeForThisModel });
    } catch (error) {
      lastError = error;
      // Une erreur autre que "surchargé" ne sert à rien de réessayer.
      if (!error.isBusy) throw error;
      if (!isLast) await wait(300);
    }
  }
  throw lastError ?? new GeminiError('Gemini n\'a pas répondu à temps', 503);
}

/*
 * Un seul appel à un modèle, arrêté s'il dépasse le temps restant.
 */
async function callModel({ apiKey, model, body, timeLeft }) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

  let response;
  try {
    response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeLeft),
    });
  } catch {
    // Temps dépassé ou problème réseau : on le traite comme une surcharge.
    throw new GeminiError(`Pas de réponse du modèle ${model}`, 503);
  }

  if (!response.ok) {
    const details = await response.text();
    throw new GeminiError(
      `Le modèle ${model} a répondu ${response.status} : ${details.slice(0, 200)}`,
      response.status,
    );
  }

  const result = await response.json();
  // On ignore les éventuelles parties "réflexion" (thought) du modèle.
  const text = (result.candidates?.[0]?.content?.parts ?? [])
    .filter((part) => !part.thought)
    .map((part) => part.text ?? '')
    .join('');
  if (!text) {
    throw new GeminiError(`Réponse vide du modèle ${model}`);
  }
  return text;
}

/*
 * Transforme la réponse texte de Gemini en objet JSON.
 */
export function parseJson(text) {
  try {
    return JSON.parse(text);
  } catch {
    throw new GeminiError('Gemini n\'a pas renvoyé un JSON valide');
  }
}
