/*
 * Liste des catégories de boutiques et de produits.
 *
 * Chaque catégorie a un identifiant (id) qui est enregistré dans la base
 * de données, et un nom affiché en français et en anglais.
 * L'IA reçoit cette liste et doit toujours répondre avec un de ces id.
 */

class Category {
  final String id;
  final String french;
  final String english;

  const Category(this.id, this.french, this.english);

  String label(String language) => language == 'en' ? english : french;
}

const List<Category> categories = [
  Category('clothing', 'Vêtements et mode', 'Clothing and fashion'),
  Category('shoes', 'Chaussures', 'Shoes'),
  Category('beauty', 'Beauté et cosmétiques', 'Beauty and cosmetics'),
  Category('hair', 'Coiffure et soins des cheveux', 'Hair care'),
  Category('jewelry', 'Bijoux et accessoires', 'Jewellery and accessories'),
  Category('bags', 'Sacs', 'Bags'),
  Category('food', 'Plats cuisinés', 'Cooked food'),
  Category('groceries', 'Alimentation et épicerie', 'Groceries'),
  Category('drinks', 'Boissons', 'Drinks'),
  Category('phones', 'Téléphones et accessoires', 'Phones and accessories'),
  Category('electronics', 'Électronique', 'Electronics'),
  Category('home', 'Maison et décoration', 'Home and decoration'),
  Category('crafts', 'Artisanat', 'Crafts'),
  Category('books', 'Livres et fournitures', 'Books and supplies'),
  Category('other', 'Autre', 'Other'),
];

/*
 * Retrouve une catégorie à partir de son id.
 * Si l'id est inconnu, on renvoie la catégorie "Autre".
 */
Category categoryById(String? id) {
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return categories.last;
}
