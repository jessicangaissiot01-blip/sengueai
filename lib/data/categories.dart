import 'package:flutter/material.dart';

/*
 * Liste des catégories de boutiques et de produits.
 *
 * Chaque catégorie a un identifiant (id) qui est enregistré dans la base
 * de données, un nom affiché en français et en anglais, et une icône
 * (utilisée dans la barre des catégories de l'accueil).
 * L'IA reçoit cette liste et doit toujours répondre avec un de ces id.
 */

class Category {
  final String id;
  final String french;
  final String english;
  final IconData icon;

  const Category(this.id, this.french, this.english, this.icon);

  String label(String language) => language == 'en' ? english : french;
}

const List<Category> categories = [
  Category('clothing', 'Vêtements et mode', 'Clothing and fashion', Icons.checkroom),
  Category('shoes', 'Chaussures', 'Shoes', Icons.directions_walk),
  Category('beauty', 'Beauté et cosmétiques', 'Beauty and cosmetics', Icons.face_retouching_natural),
  Category('hair', 'Coiffure et soins des cheveux', 'Hair care', Icons.content_cut),
  Category('jewelry', 'Bijoux et accessoires', 'Jewellery and accessories', Icons.diamond),
  Category('bags', 'Sacs', 'Bags', Icons.shopping_bag),
  Category('food', 'Plats cuisinés', 'Cooked food', Icons.restaurant),
  Category('groceries', 'Alimentation et épicerie', 'Groceries', Icons.local_grocery_store),
  Category('drinks', 'Boissons', 'Drinks', Icons.local_drink),
  Category('phones', 'Téléphones et accessoires', 'Phones and accessories', Icons.smartphone),
  Category('electronics', 'Électronique', 'Electronics', Icons.devices),
  Category('home', 'Maison et décoration', 'Home and decoration', Icons.chair),
  Category('crafts', 'Artisanat', 'Crafts', Icons.palette),
  Category('books', 'Livres et fournitures', 'Books and supplies', Icons.menu_book),
  Category('other', 'Autre', 'Other', Icons.category),
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
