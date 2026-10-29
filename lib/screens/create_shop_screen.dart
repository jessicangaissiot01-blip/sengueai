import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../data/text_utils.dart';
import '../models/shop.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/photo_service.dart';
import '../services/voice_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Création de la boutique, guidée par Sengue.
 *
 * Sengue pose trois questions, l'une après l'autre :
 *   1. Que vends-tu ?            (voix, texte, ou une photo d'un article)
 *   2. Comment s'appelle ta boutique ?
 *   3. Où se trouve ta boutique ?
 * Après chaque réponse dite à voix haute, Sengue répète ce qu'elle a compris
 * et le commerçant confirme avec Oui (vert) ou Non (rouge).
 *
 * À la fin (étape 4), le commerçant voit le formulaire rempli, peut tout
 * corriger, puis appuie sur "Créer ma boutique".
 * Il peut aussi aller directement au formulaire, sans parler.
 *
 * Quand la boutique est enregistrée, on revient à l'écran d'accueil.
 */
class CreateShopScreen extends StatefulWidget {
  final User user;
  const CreateShopScreen({super.key, required this.user});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

// Les étapes de la création.
const int _stepWhat = 0;
const int _stepName = 1;
const int _stepPlace = 2;
const int _stepForm = 3;

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _voice = VoiceService();
  final _ai = AiService();
  final _photos = PhotoService();
  final _database = DatabaseService();

  // Champs du formulaire final.
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _categoryId = 'other';

  // Champ de réponse écrite, utilisé aux étapes 1 à 3.
  final _answerController = TextEditingController();

  int _step = _stepWhat;
  bool _listening = false;
  bool _working = false; // l'IA analyse ou la boutique est en cours d'enregistrement
  String _spokenText = '';
  Uint8List? _photo;

  /*
   * Ce que Sengue a compris et qui attend un Oui ou un Non.
   * null quand il n'y a rien à confirmer.
   */
  String? _proposal;
  // Ce qu'on fera si le commerçant répond Oui.
  VoidCallback? _onYes;
  // true après un Non à la première question : on montre la liste des catégories.
  bool _choosingCategory = false;

  String get _language => appLanguage.value;

  @override
  void initState() {
    super.initState();
    // Sengue pose la première question à voix haute dès l'ouverture.
    WidgetsBinding.instance.addPostFrameCallback((_) => _askQuestion());
  }

  @override
  void dispose() {
    _voice.stopListening();
    _voice.stopSpeaking();
    _nameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  /*
   * Navigation entre les étapes
   */

  String _questionText() {
    switch (_step) {
      case _stepWhat:
        return tr('stepWhat');
      case _stepName:
        return tr('stepName');
      case _stepPlace:
        return tr('stepPlace');
      default:
        return tr('stepForm');
    }
  }

  void _askQuestion() {
    if (mounted && _step != _stepForm) _voice.speak(_questionText(), _language);
  }

  void _goToStep(int step) {
    _voice.stopListening();
    setState(() {
      _step = step;
      _proposal = null;
      _onYes = null;
      _choosingCategory = false;
      _spokenText = '';
      _listening = false;
      _answerController.clear();
    });
    _askQuestion();
  }

  /*
   * Sengue montre ce qu'elle a compris, le lit à voix haute,
   * et attend Oui ou Non.
   */
  void _propose(String text, VoidCallback onYes) {
    setState(() {
      _proposal = text;
      _onYes = onYes;
    });
    _voice.speak('$text. ${tr('isItCorrect')}', _language);
  }

  void _answerYes() {
    final action = _onYes;
    setState(() {
      _proposal = null;
      _onYes = null;
    });
    action?.call();
  }

  void _answerNo() {
    setState(() {
      _proposal = null;
      _onYes = null;
      _spokenText = '';
      // À la première question, on laisse choisir la catégorie dans une liste.
      if (_step == _stepWhat) _choosingCategory = true;
    });
    if (_step != _stepWhat) _voice.speak(tr('sayAgain'), _language);
  }

  /*
   * Micro : démarre ou arrête l'écoute. Quand la personne a fini de
   * parler, on traite sa réponse selon l'étape.
   */
  Future<void> _onMicPressed() async {
    if (_listening) {
      await _voice.stopListening();
      setState(() => _listening = false);
      return;
    }
    if (!await _voice.init()) {
      if (mounted) showMessage(context, tr('micUnavailable'));
      return;
    }
    await _voice.stopSpeaking();
    setState(() {
      _listening = true;
      _spokenText = '';
      _proposal = null;
    });
    await _voice.listen(
      language: _language,
      onText: (text, isFinal) {
        if (!mounted) return;
        setState(() => _spokenText = text);
        if (isFinal) {
          setState(() => _listening = false);
          _handleAnswer(text, spoken: true);
        }
      },
    );
  }

  // Bouton "Valider" sous le champ de texte.
  void _onTypedAnswer() {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;
    _handleAnswer(text, spoken: false);
  }

  /*
   * Traite une réponse, dite ou écrite.
   * Une réponse écrite est déjà vérifiée par la personne : pas besoin de
   * demander confirmation. Une réponse dite peut avoir été mal entendue :
   * on demande Oui ou Non.
   */
  Future<void> _handleAnswer(String text, {required bool spoken}) async {
    if (text.trim().isEmpty) return;

    switch (_step) {
      case _stepWhat:
        await _understandWhatIsSold(text);
        break;

      case _stepName:
        final name = cleanShopName(text);
        if (name.isEmpty) return;
        void accept() {
          _nameController.text = name;
          _goToStep(_stepPlace);
        }
        spoken ? _propose('${tr('shopCalled')} $name', accept) : accept();
        break;

      case _stepPlace:
        await _understandPlace(text, spoken: spoken);
        break;
    }
  }

  /*
   * Étape 1 : l'IA lit la phrase ("je vends des robes en wax à Niamey...")
   * et trouve la catégorie. Si la personne a aussi dit le nom ou la ville,
   * on les garde pour les étapes suivantes.
   */
  Future<void> _understandWhatIsSold(String text) async {
    setState(() => _working = true);
    try {
      final guess = await _ai.understandShop(text, _language);
      if (!mounted) return;
      if (guess.name.isNotEmpty) _nameController.text = guess.name;
      if (guess.city.isNotEmpty) _cityController.text = guess.city;
      if (guess.country.isNotEmpty) _countryController.text = guess.country;
      _descriptionController.text = text;
      _proposeCategory(guess.categoryId);
    } on AiException catch (e) {
      // L'IA ne répond pas : on laisse choisir la catégorie dans la liste.
      if (mounted) {
        showMessage(context, e.message);
        setState(() => _choosingCategory = true);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /*
   * Étape 1, avec une photo : l'IA reconnaît l'article et en déduit la catégorie.
   */
  Future<void> _onPhotoPressed() async {
    final bytes = await _photos.pickPhoto(context);
    if (bytes == null || !mounted) return;

    setState(() {
      _photo = bytes;
      _working = true;
      _proposal = null;
    });
    try {
      final guess = await _ai.recognizeProduct(bytes, _language);
      if (!mounted) return;
      if (guess.name.isNotEmpty) _descriptionController.text = guess.name;
      _proposeCategory(guess.categoryId, productName: guess.name);
    } on AiException catch (e) {
      if (mounted) {
        showMessage(context, e.message);
        setState(() => _choosingCategory = true);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _proposeCategory(String categoryId, {String productName = ''}) {
    final category = categoryById(categoryId);
    // Avec une photo : "Je vois : Robe en wax. Tu vends : Vêtements et mode"
    final seen = productName.isEmpty ? '' : '${tr('iSee')} $productName. ';
    _propose('$seen${tr('youSell')} ${category.label(_language)}', () => _chooseCategory(category.id));
  }

  void _chooseCategory(String categoryId) {
    _categoryId = categoryId;
    // Si le nom a déjà été dit à l'étape 1, on le fait seulement confirmer.
    _goToStep(_stepName);
    if (_nameController.text.isNotEmpty) {
      final name = _nameController.text;
      _propose('${tr('shopCalled')} $name', () => _goToStep(_stepPlace));
    }
  }

  /*
   * Étape 3 : l'IA sépare la ville et le pays ("à Niamey au Niger").
   * Si l'IA ne répond pas, on met toute la phrase dans le champ ville.
   */
  Future<void> _understandPlace(String text, {required bool spoken}) async {
    setState(() => _working = true);
    var city = text;
    var country = '';
    try {
      final guess = await _ai.understandShop(text, _language);
      if (guess.city.isNotEmpty) city = guess.city;
      country = guess.country;
    } on AiException {
      // On garde le texte tel quel.
    }
    if (!mounted) return;
    setState(() => _working = false);

    void accept() {
      _cityController.text = city;
      _countryController.text = country;
      _goToStep(_stepForm);
    }

    final place = [city, country].where((part) => part.isNotEmpty).join(', ');
    spoken ? _propose('${tr('shopLocated')} $place', accept) : accept();
  }

  /*
   * Enregistrement de la boutique
   */
  Future<void> _createShop() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showMessage(context, tr('shopNameRequired'));
      return;
    }

    setState(() => _working = true);
    try {
      await _database.createShop(Shop(
        ownerId: widget.user.uid,
        name: name,
        categoryId: _categoryId,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        description: _descriptionController.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showMessage(context, tr('errorUnknown'));
        setState(() => _working = false);
      }
    }
  }

  /*
   * Affichage
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('createShopTitle')),
        actions: const [LanguageButton()],
      ),
      body: CenteredContent(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Barre de progression : étape 1, 2, 3 puis le formulaire.
            LinearProgressIndicator(value: (_step + 1) / 4),
            const SizedBox(height: 20),
            if (_step == _stepForm) ..._buildForm() else ..._buildQuestion(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestion() {
    return [
      // La question de Sengue, avec son avatar.
      Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/images/sengue_avatar.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_questionText(), style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(
            tooltip: tr('listen'),
            icon: const Icon(Icons.volume_up),
            onPressed: _askQuestion,
          ),
        ],
      ),
      if (_step == _stepWhat) ...[
        const SizedBox(height: 8),
        Text(tr('stepWhatHelp')),
      ],
      if (_step == _stepPlace) ...[
        const SizedBox(height: 8),
        Text(tr('stepPlaceHelp')),
      ],
      const SizedBox(height: 24),

      if (_working) ...[
        Text(tr('analyzing'), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const LinearProgressIndicator(),
      ] else if (_proposal != null)
        _buildConfirmation()
      else if (_choosingCategory)
        _buildCategoryChoice()
      else
        _buildAnswerInputs(),

      if (_photo != null && _step == _stepWhat) ...[
        const SizedBox(height: 16),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_photo!, height: 160, fit: BoxFit.cover),
          ),
        ),
      ],

      const SizedBox(height: 32),
      TextButton(
        onPressed: () => _goToStep(_stepForm),
        child: Text(tr('fillFormInstead')),
      ),
    ];
  }

  // Les moyens de répondre : micro, texte, et photo à la première question.
  Widget _buildAnswerInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: FloatingActionButton.large(
            heroTag: 'mic',
            backgroundColor: _listening ? Colors.red : AppColors.green,
            foregroundColor: Colors.white,
            onPressed: _onMicPressed,
            child: Icon(_listening ? Icons.stop : Icons.mic),
          ),
        ),
        const SizedBox(height: 8),
        Text(_listening ? tr('tapToStop') : tr('tapToSpeak'), textAlign: TextAlign.center),
        if (_spokenText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '"$_spokenText"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: _answerController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: tr('orType'),
            suffixIcon: IconButton(
              tooltip: tr('confirm'),
              icon: const Icon(Icons.check),
              onPressed: _onTypedAnswer,
            ),
          ),
          onSubmitted: (_) => _onTypedAnswer(),
        ),
        if (_step == _stepWhat) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _onPhotoPressed,
            icon: const Icon(Icons.add_a_photo),
            label: Text(tr('justTakePhoto')),
          ),
        ],
      ],
    );
  }

  // Ce que Sengue a compris, avec les boutons Oui (vert) et Non (rouge).
  Widget _buildConfirmation() {
    return Card(
      color: AppColors.lightGreen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_proposal!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(tr('isItCorrect'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _answerNo,
                    icon: const Icon(Icons.close),
                    label: Text(tr('no')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _answerYes,
                    icon: const Icon(Icons.check),
                    label: Text(tr('yes')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Après un Non à "Que vends-tu ?" : la personne choisit sa catégorie.
  Widget _buildCategoryChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('chooseCategory'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map((c) => ActionChip(
                    label: Text(c.label(_language)),
                    onPressed: () => _chooseCategory(c.id),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // Étape finale : le formulaire complet, rempli par les réponses.
  List<Widget> _buildForm() {
    return [
      Text(tr('stepForm'), style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: tr('shopName')),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
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
        onPressed: _working ? null : _createShop,
        child: Text(tr('createShop')),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => _goToStep(_stepWhat),
        child: Text(tr('useVoiceInstead')),
      ),
    ];
  }
}
