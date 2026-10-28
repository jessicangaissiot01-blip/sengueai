// Faux fichier de configuration Firebase, utilisé seulement par GitHub Actions
// quand le vrai fichier n'est pas fourni. Il permet de lancer l'analyse et les tests.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: 'faux',
        appId: '1:000000000000:web:0000000000000000',
        messagingSenderId: '000000000000',
        projectId: 'sengueai-ci',
      );
}
