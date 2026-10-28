import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ai_results.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Discussion avec Sengue, l'assistante business.
 *
 * Les messages sont gardés dans la liste _messages. À chaque question, on
 * envoie aussi les messages précédents pour que Sengue suive la conversation.
 *
 * Le commerçant peut :
 *  - écrire (le champ passe à la ligne tout seul) ou parler (bouton micro) ;
 *  - copier ou supprimer n'importe quel message ;
 *  - écouter les réponses de Sengue.
 *
 * Sur ordinateur : Entrée envoie le message, Maj + Entrée passe à la ligne.
 */
class AssistantScreen extends StatefulWidget {
  final Shop shop;
  final List<Product> products;

  const AssistantScreen({super.key, required this.shop, required this.products});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _ai = AiService();
  final _voice = VoiceService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _waiting = false;
  bool _listening = false;

  String get _language => appLanguage.value;

  @override
  void dispose() {
    _voice.stopListening();
    _voice.stopSpeaking();
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _waiting) return;

    // L'historique est copié AVANT d'ajouter la nouvelle question,
    // car la question est envoyée séparément.
    final history = List<ChatMessage>.from(_messages);

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: question));
      _waiting = true;
      _textController.clear();
    });
    _scrollToBottom();

    String answer;
    try {
      answer = await _ai.askSengue(
        question: question,
        history: history,
        shop: widget.shop,
        products: widget.products,
        language: _language,
      );
    } on AiException catch (e) {
      answer = e.message;
    }

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(role: 'model', text: answer));
      _waiting = false;
    });
    _scrollToBottom();
  }

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
    setState(() => _listening = true);
    await _voice.listen(
      language: _language,
      onText: (text, isFinal) {
        if (!mounted) return;
        _textController.text = text;
        if (isFinal) {
          setState(() => _listening = false);
          _send(text);
        }
      },
    );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showMessage(context, tr('copied'));
  }

  void _delete(ChatMessage message) {
    setState(() => _messages.remove(message));
  }

  void _clearChat() {
    setState(() => _messages.clear());
  }

  /*
   * Entrée envoie le message ; Maj + Entrée laisse passer le retour à la ligne.
   * Sur téléphone, le clavier ajoute simplement une ligne.
   */
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (event is KeyDownEvent && isEnter && !HardwareKeyboard.instance.isShiftPressed) {
      _send(_textController.text);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // Fait défiler la liste jusqu'au dernier message, après l'affichage.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/sengue_avatar.png'),
            ),
            const SizedBox(width: 10),
            Text(tr('assistantTitle')),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: tr('clearChat'),
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Message d'accueil, affiché sans appeler l'IA.
                _buildBubble(ChatMessage(role: 'model', text: tr('assistantHello')), canDelete: false),
                if (_messages.isEmpty) _buildSuggestions(),
                ..._messages.map((message) => _buildBubble(message)),
                if (_waiting) _buildThinking(),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [tr('analyzeShop'), tr('suggestionPrice'), tr('suggestionWhatsapp')];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map((text) => ActionChip(label: Text(text), onPressed: () => _send(text)))
            .toList(),
      ),
    );
  }

  // Indicateur affiché pendant que Sengue prépare sa réponse.
  Widget _buildThinking() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(tr('thinking'), style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  /*
   * Une bulle de message, avec en dessous les boutons :
   * copier, écouter (seulement pour Sengue) et supprimer.
   */
  Widget _buildBubble(ChatMessage message, {bool canDelete = true}) {
    final fromUser = message.isFromUser;
    // Une bulle occupe au plus 75 % de la largeur, et jamais plus de 480 pixels.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = screenWidth * 0.75 > 480 ? 480.0 : screenWidth * 0.75;

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: fromUser ? AppColors.green : Colors.white,
                // Le coin pointu indique qui parle.
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(fromUser ? 16 : 4),
                  bottomRight: Radius.circular(fromUser ? 4 : 16),
                ),
              ),
              // SelectableText permet aussi de sélectionner une partie du texte.
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: fromUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _smallButton(Icons.copy, tr('copy'), () => _copy(message.text)),
                if (!fromUser)
                  _smallButton(Icons.volume_up, tr('listen'), () => _voice.speak(message.text, _language)),
                if (canDelete)
                  _smallButton(Icons.delete_outline, tr('deleteMessage'), () => _delete(message)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: Colors.black45),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: _listening ? tr('tapToStop') : tr('tapToSpeak'),
              icon: Icon(_listening ? Icons.stop_circle : Icons.mic),
              color: _listening ? Colors.red : AppColors.green,
              onPressed: _onMicPressed,
            ),
            Expanded(
              child: Focus(
                onKeyEvent: _onKey,
                child: TextField(
                  controller: _textController,
                  focusNode: _inputFocus,
                  // Le champ grandit jusqu'à 5 lignes, puis on fait défiler.
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _listening ? tr('listening') : tr('messageHint'),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: tr('messageHint'),
              icon: const Icon(Icons.send),
              color: AppColors.green,
              onPressed: _waiting ? null : () => _send(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}
