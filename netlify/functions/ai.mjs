/*
 * API de SengueAI :  POST /api/ai
 *
 * Cette fonction tourne sur les serveurs de Netlify (fonction "serverless" :
 * pas de serveur à gérer, Netlify la lance à chaque requête).
 *
 * Corps de la requête : { "task": "recognizeProduct", "input": { ... } }
 * En-tête obligatoire  : Authorization: Bearer <jeton Firebase>
 * Réponse              : { "data": { ... } }  ou  { "error": "message" }
 *
 * Variables d'environnement à définir dans Netlify :
 *  - GEMINI_API_KEY      : la clé de l'API Gemini (secrète)
 *  - FIREBASE_PROJECT_ID : l'identifiant du projet Firebase
 *  - GEMINI_MODEL        : facultatif, "gemini-3.5-flash" par défaut
 *  - GEMINI_FALLBACK_MODEL : facultatif, modèle de secours si le premier est surchargé
 *  - GEMINI_THINKING_LEVEL : facultatif, 'low' pour des réponses plus rapides
 *  - ALLOWED_ORIGIN      : facultatif, adresse autorisée à appeler l'API depuis
 *                          un autre site (utile pour tester en local)
 */
import { AuthError, getBearerToken, verifyFirebaseToken } from '../lib/auth.mjs';
import { askGemini, GeminiError } from '../lib/gemini.mjs';
import { InputError, tasks } from '../lib/tasks.mjs';

/*
 * createHandler reçoit ses outils en paramètres (vérification du jeton,
 * appel à Gemini). En production on lui donne les vrais ; dans les tests
 * on lui donne des faux, pour tester sans internet.
 */
export function createHandler({ verifyUser, gemini, allowedOrigin = '' }) {
  return async function handler(request) {
    const headers = { 'Content-Type': 'application/json' };
    // CORS : autorise un autre site (par exemple localhost) à appeler l'API.
    if (allowedOrigin && request.headers.get('origin') === allowedOrigin) {
      headers['Access-Control-Allow-Origin'] = allowedOrigin;
      headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type';
    }
    const reply = (status, body) => new Response(JSON.stringify(body), { status, headers });

    // Le navigateur envoie une requête OPTIONS avant un appel depuis un autre site.
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
    if (request.method !== 'POST') return reply(405, { error: 'Méthode non autorisée' });

    try {
      // 1. Qui appelle ? Sans jeton valide, on s'arrête ici.
      const uid = await verifyUser(getBearerToken(request.headers.get('authorization')));

      // 2. Quelle tâche ?
      const body = await request.json().catch(() => null);
      const task = body && Object.hasOwn(tasks, body.task) ? tasks[body.task] : null;
      if (!task) throw new InputError('Tâche inconnue');

      // 3. On exécute la tâche.
      const data = await task(body.input ?? {}, gemini);
      console.log(`tâche=${body.task} utilisateur=${uid} ok`);
      return reply(200, { data });
    } catch (error) {
      if (error instanceof AuthError) return reply(401, { error: error.message });
      if (error instanceof InputError) return reply(400, { error: error.message });
      // Gemini surchargé : un message clair, l'utilisateur peut réessayer.
      if (error instanceof GeminiError && error.isBusy) {
        console.error(error.message);
        return reply(503, { error: 'Sengue est très demandée en ce moment. Réessaie dans quelques secondes.' });
      }
      // Erreur interne : on garde le détail dans les journaux Netlify,
      // mais on ne l'envoie pas à l'utilisateur.
      console.error(error);
      return reply(502, { error: "L'IA est momentanément indisponible. Réessaie." });
    }
  };
}

// Version utilisée en production par Netlify.
export default createHandler({
  verifyUser: (token) => verifyFirebaseToken(token, process.env.FIREBASE_PROJECT_ID),
  gemini: (options) =>
    askGemini({
      apiKey: process.env.GEMINI_API_KEY,
      // Le modèle principal, puis le modèle de secours s'il est défini.
      models: [process.env.GEMINI_MODEL || 'gemini-3.5-flash', process.env.GEMINI_FALLBACK_MODEL]
        .filter(Boolean),
      thinkingLevel: process.env.GEMINI_THINKING_LEVEL,
      ...options,
    }),
  allowedOrigin: process.env.ALLOWED_ORIGIN || '',
});

// Adresse de la fonction sur le site.
export const config = { path: '/api/ai' };
