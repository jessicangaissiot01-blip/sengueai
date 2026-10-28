/*
 * Vérification de l'utilisateur qui appelle l'API.
 *
 * L'application envoie l'en-tête :  Authorization: Bearer <jeton>
 * Le jeton est un JWT créé par Firebase quand l'utilisateur se connecte.
 * Un JWT contient des informations (qui est l'utilisateur, quand le jeton
 * expire...) et une signature faite par Google.
 *
 * Pour être sûr que le jeton est vrai, on vérifie :
 *  - la signature, avec les clés publiques de Google ;
 *  - l'émetteur (iss) et l'audience (aud), qui doivent correspondre à
 *    notre projet Firebase ;
 *  - la date d'expiration.
 * La bibliothèque jose fait ces vérifications pour nous.
 */
import { createRemoteJWKSet, jwtVerify } from 'jose';

const GOOGLE_KEYS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

// Les clés publiques de Google sont téléchargées une fois puis gardées en mémoire.
const googleKeys = createRemoteJWKSet(new URL(GOOGLE_KEYS_URL));

export class AuthError extends Error {}

/*
 * Récupère le jeton dans l'en-tête "Authorization: Bearer xxx".
 */
export function getBearerToken(header) {
  if (!header || !header.startsWith('Bearer ')) {
    throw new AuthError('Jeton de connexion manquant');
  }
  return header.slice('Bearer '.length).trim();
}

/*
 * Vérifie le jeton et renvoie l'identifiant de l'utilisateur (uid).
 */
export async function verifyFirebaseToken(token, projectId) {
  try {
    const { payload } = await jwtVerify(token, googleKeys, {
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
    });
    return payload.sub;
  } catch {
    throw new AuthError('Jeton de connexion invalide ou expiré');
  }
}
