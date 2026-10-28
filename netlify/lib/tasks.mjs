/*
 * Les trois tâches que l'IA sait faire pour l'application.
 *
 *  - recognizeProduct : reconnaître un produit sur une photo
 *  - understandShop   : comprendre la description vocale d'une boutique
 *  - askSengue        : répondre aux questions du commerçant
 *
 * Pour chaque tâche :
 *  1. on vérifie les données reçues (on ne fait jamais confiance au client) ;
 *  2. on écrit les instructions (le "prompt") ici, sur le serveur ;
 *  3. on appelle Gemini ;
 *  4. on nettoie la réponse avant de la renvoyer.
 */
import { parseJson } from './gemini.mjs';

export class InputError extends Error {}

const MAX_IMAGE_LENGTH = 2 * 1024 * 1024; // environ 1,5 Mo d'image en base64

/* ---------- Vérification des données reçues ---------- */

function checkText(value, field, maxLength) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new InputError(`Le champ "${field}" est obligatoire`);
  }
  if (value.length > maxLength) {
    throw new InputError(`Le champ "${field}" est trop long`);
  }
  return value.trim();
}

function checkCategories(list) {
  if (!Array.isArray(list) || list.length === 0) {
    throw new InputError('La liste des catégories est obligatoire');
  }
  return list.map((c) => ({ id: String(c.id), label: String(c.label) }));
}

function languageName(language) {
  return language === 'en' ? 'English' : 'français';
}

// Si l'IA invente une catégorie qui n'existe pas, on la remplace par "other".
function knownCategory(id, categories) {
  return categories.some((c) => c.id === id) ? id : 'other';
}

function categoriesText(categories) {
  return categories.map((c) => `${c.id} : ${c.label}`).join('\n');
}

/* ---------- 1. Reconnaître un produit sur une photo ---------- */

export async function recognizeProduct(input, gemini) {
  const image = checkText(input.image, 'image', MAX_IMAGE_LENGTH);
  const categories = checkCategories(input.categories);
  const language = languageName(input.language);

  const prompt = `Tu aides des commerçants africains à mettre leurs produits en ligne.
Regarde la photo et identifie le produit.
Choisis la catégorie uniquement parmi ces identifiants :
${categoriesText(categories)}
Donne :
- categoryId : l'identifiant de la catégorie ("other" si aucune ne convient)
- confidence : ta certitude entre 0 et 1 (0.3 ou moins si la photo est floue)
- name : un nom de produit court, 2 à 5 mots
- description : une phrase simple pour donner envie d'acheter
Écris name et description en ${language}.`;

  const text = await gemini({
    parts: [{ text: prompt }, { inlineData: { mimeType: 'image/jpeg', data: image } }],
    schema: {
      type: 'OBJECT',
      properties: {
        categoryId: { type: 'STRING' },
        confidence: { type: 'NUMBER' },
        name: { type: 'STRING' },
        description: { type: 'STRING' },
      },
      required: ['categoryId', 'confidence', 'name', 'description'],
    },
  });

  const result = parseJson(text);
  return {
    categoryId: knownCategory(result.categoryId, categories),
    confidence: Math.min(1, Math.max(0, Number(result.confidence) || 0)),
    name: String(result.name ?? '').slice(0, 60),
    description: String(result.description ?? '').slice(0, 300),
  };
}

/* ---------- 2. Comprendre la description vocale d'une boutique ---------- */

export async function understandShop(input, gemini) {
  const spokenText = checkText(input.text, 'text', 1000);
  const categories = checkCategories(input.categories);
  const language = languageName(input.language);

  const prompt = `Un commerçant a décrit sa boutique à voix haute. Voici ce qu'il a dit :
"${spokenText}"

Extrais les informations suivantes :
- name : le nom de la boutique s'il le dit, sinon ""
- categoryId : un identifiant parmi cette liste ("other" si tu ne sais pas) :
${categoriesText(categories)}
- city : la ville, le quartier ou le marché, sinon ""
- country : le pays s'il le dit ou s'il est évident d'après la ville (Niamey donne Niger), sinon ""
- summary : une phrase courte en ${language} qui résume ce que tu as compris
N'invente aucune information qui n'est pas dans la phrase.`;

  const text = await gemini({
    parts: [{ text: prompt }],
    schema: {
      type: 'OBJECT',
      properties: {
        name: { type: 'STRING' },
        categoryId: { type: 'STRING' },
        city: { type: 'STRING' },
        country: { type: 'STRING' },
        summary: { type: 'STRING' },
      },
      required: ['name', 'categoryId', 'city', 'country', 'summary'],
    },
  });

  const result = parseJson(text);
  return {
    name: String(result.name ?? '').slice(0, 60),
    categoryId: knownCategory(result.categoryId, categories),
    city: String(result.city ?? '').slice(0, 60),
    country: String(result.country ?? '').slice(0, 60),
    summary: String(result.summary ?? '').slice(0, 300),
  };
}

/* ---------- 3. Répondre aux questions du commerçant ---------- */

export async function askSengue(input, gemini) {
  const question = checkText(input.question, 'question', 1000);
  const language = languageName(input.language);
  const shop = input.shop ?? {};
  const products = Array.isArray(shop.products) ? shop.products.slice(0, 20) : [];

  const productLines = products.length === 0
    ? 'aucun produit pour le moment'
    : products.map((p) => `- ${p.name} : ${p.price} FCFA, stock ${p.stock}`).join('\n');

  // Les instructions générales sont envoyées comme "instruction système".
  const systemText = `Tu es Sengue, une assistante business pour les commerçants africains.
Tu connais les marchés locaux, le franc CFA, le Mobile Money et la vente sur WhatsApp.
Réponds toujours en ${language}, de façon simple, concrète et chaleureuse, en 5 phrases maximum.
Si la question n'a aucun rapport avec le commerce, dis poliment que tu aides seulement pour la boutique.

Boutique : ${shop.name ?? ''} (${shop.category ?? ''}), ${shop.city ?? ''} ${shop.country ?? ''}
Produits :
${productLines}`;

  // Seuls les 10 derniers messages sont gardés, avec un rôle valide.
  const history = (Array.isArray(input.history) ? input.history : [])
    .filter((m) => (m.role === 'user' || m.role === 'model') && typeof m.text === 'string')
    .slice(-10)
    .map((m) => ({ role: m.role, parts: [{ text: m.text.slice(0, 2000) }] }));

  const answer = await gemini({ parts: [{ text: question }], history, systemText });
  return { answer: answer.trim() };
}

export const tasks = { recognizeProduct, understandShop, askSengue };
