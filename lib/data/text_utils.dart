/*
 * Petites fonctions pour nettoyer le texte dicté à la voix.
 */

/*
 * Garde seulement le nom de la boutique dans une phrase dite à voix haute.
 *
 * Exemples :
 *   "ma boutique s'appelle aliya shop."  ->  "Aliya Shop"
 *   "elle s'appelle chez fati"           ->  "Chez Fati"
 *   "my shop is called wara fashion"     ->  "Wara Fashion"
 */
String cleanShopName(String spoken) {
  var name = spoken.trim();

  // Débuts de phrase fréquents, en français et en anglais.
  // ['’] accepte les deux sortes d'apostrophe que peut écrire la dictée.
  final prefixes = RegExp(
    r"^(ma boutique s['’]appelle|ma boutique se nomme|elle s['’]appelle|le nom c['’]est|"
    r"c['’]est|my shop is called|my shop['’]s name is|it['’]s called|it is called)\s+",
    caseSensitive: false,
  );
  name = name.replaceFirst(prefixes, '');

  // On enlève la ponctuation à la fin (la dictée ajoute souvent un point).
  name = name.replaceAll(RegExp(r'[.!?,;]+$'), '').trim();

  // Une majuscule au début de chaque mot.
  return name
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
