import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/categories.dart';
import '../models/ai_results.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/photo_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Ajout d'un produit.
 *
 * 1. Le commerçant ajoute 1 à 4 photos du produit.
 * 2. La première photo est envoyée à l'IA, qui propose un nom, une catégorie et
 *    une description. Le commerçant peut tout modifier.
 * 3. Il indique le prix et le stock, puis enregistre.
 */
class AddProductScreen extends StatefulWidget {
  final Shop shop;
  const AddProductScreen({super.key, required this.shop});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _ai = AiService();
  final _database = DatabaseService();
  final _photos = PhotoService();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  late String _categoryId = widget.shop.categoryId;

  // Les photos choisies, la première est la photo principale.
  final List<Uint8List> _pickedPhotos = [];
  ProductGuess? _guess;
  bool _recognizing = false;
  bool _saving = false;

  String get _language => appLanguage.value;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /*
   * Ajoute une photo (voir PhotoService), jusqu'à 4.
   * Seule la première photo est envoyée à l'IA pour reconnaître le produit.
   */
  Future<void> _pickPhoto() async {
    if (_pickedPhotos.length >= Product.maxPhotos) return;
    final bytes = await _photos.pickPhoto(context);
    if (bytes == null || !mounted) return;
    final isFirst = _pickedPhotos.isEmpty;
    setState(() => _pickedPhotos.add(bytes));
    if (isFirst) await _recognize(bytes);
  }

  void _removePhoto(int index) {
    setState(() {
      _pickedPhotos.removeAt(index);
      if (_pickedPhotos.isEmpty) _guess = null;
    });
  }

  Future<void> _recognize(Uint8List photo) async {
    setState(() => _recognizing = true);
    try {
      final guess = await _ai.recognizeProduct(photo, _language);
      setState(() {
        _guess = guess;
        _categoryId = categoryById(guess.categoryId).id;
        if (guess.name.isNotEmpty) _nameController.text = guess.name;
        if (guess.description.isNotEmpty) _descriptionController.text = guess.description;
      });
    } on AiException catch (e) {
      // Si l'IA ne répond pas, le commerçant remplit le formulaire lui-même.
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;

    if (_pickedPhotos.isEmpty || name.isEmpty || price <= 0) {
      showMessage(context, tr('productRequired'));
      return;
    }

    // Toutes les photos ensemble doivent rester sous la limite de taille.
    final images = _pickedPhotos.map(base64Encode).toList();
    final totalLength = images.fold<int>(0, (sum, image) => sum + image.length);
    if (totalLength > Product.maxImageLength) {
      showMessage(context, tr('imageTooBig'));
      return;
    }

    setState(() => _saving = true);
    try {
      await _database.addProduct(Product(
        shopId: widget.shop.ownerId,
        name: name,
        categoryId: _categoryId,
        description: _descriptionController.text.trim(),
        price: price,
        stock: stock,
        imageBase64: images.first,
        extraImages: images.skip(1).toList(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showMessage(context, tr('errorUnknown'));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('addProduct'))),
      body: CenteredContent(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPhotoArea(),
            const SizedBox(height: 12),
            if (_pickedPhotos.length < Product.maxPhotos)
              OutlinedButton.icon(
                onPressed: _recognizing ? null : _pickPhoto,
                icon: const Icon(Icons.add_a_photo),
                label: Text(_pickedPhotos.isEmpty ? photoButtonLabel() : tr('addAnotherPhoto')),
              ),
            const SizedBox(height: 12),
            _buildAiResult(),
            const SizedBox(height: 12),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  /*
   * Zone des photos : la photo principale en grand, puis les autres en petit.
   * Chaque photo a une croix pour la retirer.
   */
  Widget _buildPhotoArea() {
    if (_pickedPhotos.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(tr('photoHint'), textAlign: TextAlign.center),
          ),
        ),
      );
    }
    return Column(
      children: [
        _photoWithRemove(0, height: 220),
        if (_pickedPhotos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i < _pickedPhotos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(width: 90, child: _photoWithRemove(i, height: 90)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _photoWithRemove(int index, {required double height}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(_pickedPhotos[index], height: height, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.black54,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              tooltip: tr('delete'),
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => _removePhoto(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiResult() {
    if (_recognizing) {
      return Column(
        children: [
          Text(tr('analyzing')),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      );
    }
    final guess = _guess;
    if (guess == null) return const SizedBox.shrink();

    final category = categoryById(guess.categoryId).label(_language);
    return Text(
      '${tr('recognized')} : $category (${guess.confidencePercent} ${tr('confidence')})',
      style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: tr('productName')),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_categoryId),
          initialValue: _categoryId,
          decoration: InputDecoration(labelText: tr('category')),
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.label(_language))))
              .toList(),
          onChanged: (value) => setState(() => _categoryId = value ?? 'other'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                // On n'accepte que des chiffres.
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: tr('price')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: tr('stock')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(labelText: tr('description')),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: (_saving || _recognizing) ? null : _save,
          child: Text(tr('save')),
        ),
      ],
    );
  }
}
