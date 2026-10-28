import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/categories.dart';
import '../models/ai_results.dart';
import '../models/product.dart';
import '../models/shop.dart';

/*
 * Communication avec notre API d'intelligence artificielle.
 *
 * L'application n'appelle jamais Gemini directement. Le chemin est :
 *   application  ->  notre API /api/ai (Netlify)  ->  Gemini (Google)
 *
 * Pourquoi ? Si la clé Gemini était dans l'application, n'importe qui
 * pourrait la récupérer en ouvrant l'APK ou le code du site web.
 * Ici, la clé reste sur le serveur. L'application envoie seulement le
 * jeton de connexion Firebase de l'utilisateur, que le serveur vérifie.
 *
 * Chaque requête a la forme : { "task": "...", "input": { ... } }
 * Chaque réponse a la forme : { "data": { ... } } ou { "error": "..." }
 */

class AiException implements Exception {
  final String message;

  // true quand le serveur est seulement surchargé : on peut réessayer.
  final bool canRetry;

  const AiException(this.message, {this.canRetry = false});

  @override
  String toString() => message;
}

class AiService {
  /*
   * Adresse de l'API.
   * Sur le site web, l'API est sur le même site : on utilise juste /api/ai.
   * Pour Android, on donne l'adresse au lancement :
   *   flutter run --dart-define=API_URL=https://ton-site.netlify.app
   */
  static const String _apiUrl = String.fromEnvironment('API_URL');

  final http.Client _client;
  final Future<String?> Function() _getToken;
  final Uri _endpoint;
  final Duration _retryDelay;

  /*
   * Les paramètres client, getToken, endpoint et retryDelay servent aux
   * tests : on peut remplacer le vrai réseau et le vrai Firebase par des faux.
   */
  AiService({
    http.Client? client,
    Future<String?> Function()? getToken,
    Uri? endpoint,
    Duration retryDelay = const Duration(seconds: 1),
  })  : _client = client ?? http.Client(),
        _getToken = getToken ?? _firebaseToken,
        _endpoint = endpoint ?? _defaultEndpoint(),
        _retryDelay = retryDelay;

  static Uri _defaultEndpoint() {
    if (_apiUrl.isNotEmpty) return Uri.parse('$_apiUrl/api/ai');
    return Uri.base.resolve('/api/ai');
  }

  static Future<String?> _firebaseToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /*
   * Envoie une tâche à l'API et renvoie le contenu de "data".
   * Toutes les erreurs sont transformées en AiException avec un message
   * que l'on peut afficher directement à l'utilisateur.
   */
  Future<Map<String, dynamic>> _send(String task, Map<String, dynamic> input) async {
    // L'IA est parfois surchargée quelques secondes. Plutôt que d'afficher
    // une erreur tout de suite, on réessaie une fois automatiquement.
    try {
      return await _sendOnce(task, input);
    } on AiException catch (error) {
      if (!error.canRetry) rethrow;
      await Future.delayed(_retryDelay);
      return _sendOnce(task, input);
    }
  }

  Future<Map<String, dynamic>> _sendOnce(String task, Map<String, dynamic> input) async {
    final token = await _getToken();
    if (token == null) {
      throw const AiException('Connecte-toi pour utiliser Sengue.');
    }

    http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'task': task, 'input': input}),
          )
          .timeout(const Duration(seconds: 40));
    } on TimeoutException {
      throw const AiException('Sengue met trop de temps à répondre. Réessaie.');
    } catch (_) {
      throw const AiException('Pas de connexion internet.');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      // Netlify renvoie une page d'erreur (pas du JSON) si la fonction a été coupée.
      throw AiException(
        'Sengue ne répond pas pour le moment. Réessaie.',
        canRetry: response.statusCode >= 500,
      );
    }

    if (response.statusCode != 200) {
      throw AiException(
        body['error'] as String? ?? 'Erreur ${response.statusCode}',
        // 502, 503, 504 : problème passager côté serveur ou IA.
        canRetry: response.statusCode >= 500,
      );
    }
    return body['data'] as Map<String, dynamic>;
  }

  /*
   * Envoie la photo d'un produit. L'IA renvoie la catégorie, un nom et une
   * description. On envoie aussi la liste des catégories pour que l'IA
   * choisisse forcément parmi elles.
   */
  Future<ProductGuess> recognizeProduct(Uint8List photo, String language) async {
    final data = await _send('recognizeProduct', {
      'image': base64Encode(photo),
      'categories': _categoryList(language),
      'language': language,
    });
    return ProductGuess.fromJson(data);
  }

  /*
   * Envoie la phrase dite par le commerçant (déjà transformée en texte par
   * la reconnaissance vocale). L'IA en extrait les infos de la boutique.
   */
  Future<ShopGuess> understandShop(String spokenText, String language) async {
    final data = await _send('understandShop', {
      'text': spokenText,
      'categories': _categoryList(language),
      'language': language,
    });
    return ShopGuess.fromJson(data);
  }

  /*
   * Pose une question à Sengue.
   * history contient les messages précédents pour que Sengue suive la
   * conversation. On envoie aussi les infos de la boutique et des produits
   * pour que les conseils soient adaptés.
   */
  Future<String> askSengue({
    required String question,
    required List<ChatMessage> history,
    required Shop shop,
    required List<Product> products,
    required String language,
  }) async {
    final data = await _send('askSengue', {
      'question': question,
      'history': history.map((message) => message.toJson()).toList(),
      'language': language,
      'shop': {
        'name': shop.name,
        'category': categoryById(shop.categoryId).label(language),
        'city': shop.city,
        'country': shop.country,
        'products': products
            .take(20)
            .map((p) => {'name': p.name, 'price': p.price, 'stock': p.stock})
            .toList(),
      },
    });
    return data['answer'] as String? ?? '';
  }

  List<Map<String, String>> _categoryList(String language) {
    return categories.map((c) => {'id': c.id, 'label': c.label(language)}).toList();
  }
}
