import 'package:flutter_test/flutter_test.dart';
import 'package:sengue_ai/data/text_utils.dart';

/*
 * Tests du nettoyage du nom de boutique dicté à la voix.
 */
void main() {
  test('enlève le début de phrase et met des majuscules', () {
    expect(cleanShopName("ma boutique s'appelle aliya shop."), 'Aliya Shop');
  });

  test("accepte l'apostrophe typographique de la dictée", () {
    expect(cleanShopName('elle s’appelle chez fati'), 'Chez Fati');
  });

  test('marche aussi en anglais', () {
    expect(cleanShopName('my shop is called wara fashion'), 'Wara Fashion');
  });

  test('garde un nom simple tel quel', () {
    expect(cleanShopName('Boutique Bella'), 'Boutique Bella');
  });
}
