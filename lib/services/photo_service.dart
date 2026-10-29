import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../strings.dart';

/*
 * Choix d'une photo, utilisé pour les produits et pour la création de boutique.
 *
 *  - Sur ordinateur (web) : il n'y a pas d'appareil photo, on ouvre
 *    directement la fenêtre pour choisir une image dans l'ordinateur.
 *  - Sur téléphone (Android) : on demande d'abord "Prendre une photo"
 *    ou "Choisir dans la galerie".
 *
 * La photo est réduite tout de suite (600 pixels, qualité 70 %) : elle est
 * plus rapide à envoyer à l'IA et assez légère pour être gardée dans Firestore.
 * On la lit en octets (readAsBytes), ce qui marche sur le web et sur Android.
 */
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  // Renvoie null si la personne annule.
  Future<Uint8List?> pickPhoto(BuildContext context) async {
    ImageSource? source = ImageSource.gallery;
    if (!kIsWeb) {
      source = await _askSource(context);
      if (source == null) return null;
    }

    final file = await _picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  // Petit menu en bas de l'écran : appareil photo ou galerie.
  Future<ImageSource?> _askSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(tr('takePhoto')),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(tr('gallery')),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

/*
 * Texte du bouton photo : "Choisir une photo" sur ordinateur,
 * "Prendre ou choisir une photo" sur téléphone.
 */
String photoButtonLabel() => kIsWeb ? tr('choosePhoto') : tr('takeOrChoosePhoto');
