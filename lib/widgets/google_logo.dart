import 'dart:math';

import 'package:flutter/material.dart';

/*
 * Le logo "G" de Google, dessiné avec quatre arcs de couleur et une barre.
 * On le dessine nous-mêmes (CustomPainter) au lieu d'ajouter une image :
 * il reste net à toutes les tailles et ne demande aucun fichier en plus.
 */
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  // Convertit des degrés en radians (Flutter dessine les arcs en radians).
  double _rad(double degrees) => degrees * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    // Le cercle est un peu plus petit que le carré pour que le trait ne dépasse pas.
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    /*
     * Les angles partent de la droite (0 degré) et tournent dans le sens
     * des aiguilles d'une montre. Le haut à droite reste ouvert : c'est
     * l'ouverture du "G".
     */
    canvas.drawArc(rect, _rad(0), _rad(45), false, arc(_blue));
    canvas.drawArc(rect, _rad(45), _rad(90), false, arc(_green));
    canvas.drawArc(rect, _rad(135), _rad(85), false, arc(_yellow));
    canvas.drawArc(rect, _rad(220), _rad(100), false, arc(_red));

    // La barre horizontale bleue, du centre vers la droite.
    final bar = Paint()..color = _blue;
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height / 2 - stroke / 2, size.width / 2, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
