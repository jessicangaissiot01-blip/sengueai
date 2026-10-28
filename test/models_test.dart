import 'package:flutter_test/flutter_test.dart';
import 'package:sengue_ai/data/categories.dart';
import 'package:sengue_ai/models/ai_results.dart';
import 'package:sengue_ai/models/product.dart';
import 'package:sengue_ai/models/shop.dart';
import 'package:sengue_ai/strings.dart';

/*
 * Tests des modèles et des petites fonctions qui ne dépendent pas de Firebase.
 * Lancer avec : flutter test
 */
void main() {
  test('categoryById renvoie "Autre" pour un identifiant inconnu', () {
    expect(categoryById('shoes').id, 'shoes');
    expect(categoryById('inconnu').id, 'other');
    expect(categoryById(null).id, 'other');
  });

  test('les identifiants de catégories sont uniques', () {
    final ids = categories.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('chaque texte existe en français et en anglais', () {
    expect(missingTranslations(), isEmpty);
  });

  test('ProductGuess limite la confiance entre 0 et 1', () {
    expect(ProductGuess.fromJson({'confidence': 1.8}).confidence, 1);
    expect(ProductGuess.fromJson({'confidence': -1}).confidence, 0);
    expect(ProductGuess.fromJson({'confidence': 0.87}).confidencePercent, '87 %');
  });

  test('ShopGuess accepte une réponse incomplète', () {
    final guess = ShopGuess.fromJson({'name': 'Aliya Shop'});
    expect(guess.name, 'Aliya Shop');
    expect(guess.categoryId, 'other');
    expect(guess.city, '');
  });

  test('Shop.fromMap utilise des valeurs par défaut', () {
    final shop = Shop.fromMap('uid1', {'name': 'Aliya Shop'});
    expect(shop.ownerId, 'uid1');
    expect(shop.categoryId, 'other');
  });

  test('Product calcule l\'état du stock', () {
    Product withStock(int stock) => Product(
          shopId: 's',
          name: 'Robe',
          categoryId: 'clothing',
          description: '',
          price: 5000,
          stock: stock,
          imageBase64: '',
        );
    expect(withStock(0).isOutOfStock, isTrue);
    expect(withStock(2).isLowStock, isTrue);
    expect(withStock(10).isLowStock, isFalse);
  });

  test('Product.imageBytes renvoie null si la photo est absente ou abîmée', () {
    final product = Product.fromMap('p1', {'imageBase64': 'pas du base64 !'});
    expect(product.imageBytes, isNull);
  });
}
