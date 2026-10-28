import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/categories.dart';
import '../models/ai_results.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Ajout d'un produit.
 *
 * 1. Le commerçant prend une photo (ou en choisit une dans la galerie).
 * 2. La photo est envoyée à l'IA, qui propose un nom, une catégorie et
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
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  late String _categoryId = widget.shop.categoryId;

  Uint8List? _photo;
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
   * Ouvre l'appareil photo ou la galerie.
   * On réduit la photo dès ici (600 pixels, qualité 70 %) : elle est plus
   * rapide à envoyer à l'IA et assez légère pour être enregistrée dans Firestore.
   * On lit la photo en octets (readAsBytes) : cela marche sur Android et sur le web.
   */
  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _photo = bytes;
      _guess = null;
    });
    await _recognize(bytes);
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

    if (_photo == null || name.isEmpty || price <= 0) {
      showMessage(context, tr('productRequired'));
      return;
    }

    final imageBase64 = base64Encode(_photo!);
    if (imageBase64.length > Product.maxImageLength) {
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
        imageBase64: imageBase64,
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPhotoArea(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _recognizing ? null : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: Text(tr('takePhoto')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _recognizing ? null : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(tr('gallery')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAiResult(),
          const SizedBox(height: 12),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildPhotoArea() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _photo == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(tr('photoHint'), textAlign: TextAlign.center),
              ),
            )
          : Image.memory(_photo!, fit: BoxFit.cover),
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
