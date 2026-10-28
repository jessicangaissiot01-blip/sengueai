import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sengue_ai/services/ai_service.dart';

/*
 * Tests du service IA sans réseau.
 * MockClient remplace le vrai serveur : il reçoit la requête et renvoie
 * une réponse préparée à l'avance.
 */
void main() {
  final endpoint = Uri.parse('https://exemple.test/api/ai');

  http.Response jsonResponse(Map<String, dynamic> body, int status) {
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  test('envoie le jeton de connexion et la photo en base64', () async {
    late http.Request sentRequest;
    final ai = AiService(
      endpoint: endpoint,
      getToken: () async => 'jeton-test',
      client: MockClient((request) async {
        sentRequest = request;
        return jsonResponse({
          'data': {'categoryId': 'clothing', 'confidence': 0.9, 'name': 'Robe wax', 'description': 'Belle robe'},
        }, 200);
      }),
    );

    final photo = Uint8List.fromList([1, 2, 3]);
    final guess = await ai.recognizeProduct(photo, 'fr');

    expect(sentRequest.headers['Authorization'], 'Bearer jeton-test');
    final body = jsonDecode(sentRequest.body) as Map<String, dynamic>;
    expect(body['task'], 'recognizeProduct');
    expect(body['input']['image'], base64Encode(photo));
    expect(guess.name, 'Robe wax');
  });

  test("n'appelle pas le serveur si l'utilisateur n'est pas connecté", () async {
    var called = false;
    final ai = AiService(
      endpoint: endpoint,
      getToken: () async => null,
      client: MockClient((request) async {
        called = true;
        return jsonResponse({}, 200);
      }),
    );

    await expectLater(ai.understandShop('Je vends des robes', 'fr'), throwsA(isA<AiException>()));
    expect(called, isFalse);
  });

  test("affiche le message d'erreur renvoyé par le serveur", () async {
    final ai = AiService(
      endpoint: endpoint,
      getToken: () async => 'jeton-test',
      client: MockClient((request) async => jsonResponse({'error': 'Jeton invalide'}, 401)),
    );

    await expectLater(
      ai.understandShop('Je vends des robes', 'fr'),
      throwsA(isA<AiException>().having((e) => e.message, 'message', 'Jeton invalide')),
    );
  });

  test('réessaie une fois quand Sengue est surchargée', () async {
    var calls = 0;
    final ai = AiService(
      endpoint: endpoint,
      getToken: () async => 'jeton-test',
      retryDelay: Duration.zero,
      client: MockClient((request) async {
        calls++;
        if (calls == 1) return jsonResponse({'error': 'Sengue est très demandée'}, 503);
        return jsonResponse({'data': {'answer': 'Bonjour !'}}, 200);
      }),
    );

    final data = await ai.understandShop('Je vends des robes', 'fr');
    expect(calls, 2);
    expect(data.name, '');
  });

  test('ne réessaie pas une erreur définitive (401)', () async {
    var calls = 0;
    final ai = AiService(
      endpoint: endpoint,
      getToken: () async => 'jeton-test',
      retryDelay: Duration.zero,
      client: MockClient((request) async {
        calls++;
        return jsonResponse({'error': 'Jeton invalide'}, 401);
      }),
    );

    await expectLater(ai.understandShop('Je vends des robes', 'fr'), throwsA(isA<AiException>()));
    expect(calls, 1);
  });
}
