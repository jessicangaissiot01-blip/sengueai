import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/*
 * La voix dans l'application.
 *
 *  - Reconnaissance vocale (speech to text) : transforme ce que dit le
 *    commerçant en texte. Sur Android elle utilise le moteur de Google,
 *    sur le web celui du navigateur (Chrome).
 *  - Synthèse vocale (text to speech) : Sengue lit une phrase à voix haute.
 */
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  bool get isListening => _speech.isListening;

  /*
   * Prépare le micro. Demande l'autorisation à l'utilisateur la première fois.
   * Renvoie false si le micro n'est pas disponible ou refusé.
   */
  Future<bool> init() async {
    if (_ready) return true;
    _ready = await _speech.initialize();
    return _ready;
  }

  /*
   * Démarre l'écoute. onText est appelé à chaque mot reconnu.
   * isFinal vaut true quand la personne a fini de parler.
   */
  Future<void> listen({
    required String language,
    required void Function(String text, bool isFinal) onText,
  }) async {
    if (!await init()) return;
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: language == 'en' ? 'en_US' : 'fr_FR',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
      onResult: (result) => onText(result.recognizedWords, result.finalResult),
    );
  }

  Future<void> stopListening() => _speech.stop();

  Future<void> speak(String text, String language) async {
    await _tts.setLanguage(language == 'en' ? 'en-US' : 'fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();
}
