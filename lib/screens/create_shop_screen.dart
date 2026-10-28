import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/shop.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/voice_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Création de la boutique.
 *
 * Le commerçant peut :
 *  1. parler : on transforme sa voix en texte, puis l'IA remplit le formulaire ;
 *  2. ou remplir le formulaire à la main.
 * Dans les deux cas, il vérifie le formulaire puis appuie sur "Créer".
 * Quand la boutique est enregistrée, ShopGate (main.dart) affiche
 * automatiquement l'écran de la boutique.
 */
class CreateShopScreen extends StatefulWidget {
  final User user;
  const CreateShopScreen({super.key, required this.user});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _voice = VoiceService();
  final _ai = AiService();
  final _database = DatabaseService();

  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _categoryId = 'other';

  bool _listening = false;
  bool _analyzing = false;
  bool _saving = false;
  String _spokenText = '';
  String _summary = '';

  String get _language => appLanguage.value;

  @override
  void dispose() {
    _voice.stopListening();
    _nameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /*
   * Bouton micro : démarre ou arrête l'écoute.
   */
  Future<void> _onMicPressed() async {
    if (_listening) {
      await _voice.stopListening();
      setState(() => _listening = false);
      return;
    }

    final micReady = await _voice.init();
    if (!micReady) {
      if (mounted) showMessage(context, tr('micUnavailable'));
      return;
    }

    setState(() {
      _listening = true;
      _spokenText = '';
      _summary = '';
    });

    await _voice.listen(
      language: _language,
      onText: (text, isFinal) {
        if (!mounted) return;
        setState(() => _spokenText = text);
        if (isFinal) {
          setState(() => _listening = false);
          _analyzeSpokenText(text);
        }
      },
    );
  }

  /*
   * Envoie le texte à l'IA et remplit le formulaire avec la réponse.
   * On ne remplace un champ que si l'IA a trouvé une valeur.
   */
  Future<void> _analyzeSpokenText(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _analyzing = true);

    try {
      final guess = await _ai.understandShop(text, _language);
      setState(() {
        if (guess.name.isNotEmpty) _nameController.text = guess.name;
        if (guess.city.isNotEmpty) _cityController.text = guess.city;
        if (guess.country.isNotEmpty) _countryController.text = guess.country;
        _categoryId = categoryById(guess.categoryId).id;
        _descriptionController.text = text;
        _summary = guess.summary;
      });
      // Sengue confirme à voix haute ce qu'elle a compris.
      if (guess.summary.isNotEmpty) _voice.speak(guess.summary, _language);
    } on AiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _createShop() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showMessage(context, tr('shopNameRequired'));
      return;
    }

    setState(() => _saving = true);
    try {
      await _database.createShop(Shop(
        ownerId: widget.user.uid,
        name: name,
        categoryId: _categoryId,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        description: _descriptionController.text.trim(),
      ));
      // Pas de navigation ici : ShopGate voit la nouvelle boutique et change d'écran.
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
      appBar: AppBar(
        title: Text(tr('createShopTitle')),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: tr('logout'),
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildVoiceCard(),
          const SizedBox(height: 24),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildVoiceCard() {
    String status;
    if (_analyzing) {
      status = tr('analyzing');
    } else if (_listening) {
      status = tr('tapToStop');
    } else {
      status = tr('tapToSpeak');
    }

    return Card(
      color: AppColors.lightGreen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(tr('voiceIntro'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            // Le bouton devient rouge pendant l'écoute.
            FloatingActionButton.large(
              heroTag: 'mic',
              backgroundColor: _listening ? Colors.red : AppColors.green,
              foregroundColor: Colors.white,
              onPressed: _analyzing ? null : _onMicPressed,
              child: Icon(_listening ? Icons.stop : Icons.mic),
            ),
            const SizedBox(height: 8),
            Text(status),
            if (_analyzing) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (_spokenText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('"$_spokenText"', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (_summary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(tr('understood'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_summary, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: tr('shopName')),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // La clé force le champ à se mettre à jour quand l'IA change la catégorie.
          key: ValueKey(_categoryId),
          initialValue: _categoryId,
          decoration: InputDecoration(labelText: tr('category')),
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.label(_language))))
              .toList(),
          onChanged: (value) => setState(() => _categoryId = value ?? 'other'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cityController,
          decoration: InputDecoration(labelText: tr('city')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _countryController,
          decoration: InputDecoration(labelText: tr('country')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(labelText: tr('description')),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saving ? null : _createShop,
          child: Text(tr('createShop')),
        ),
      ],
    );
  }
}
