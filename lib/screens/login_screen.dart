import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Écran de connexion et d'inscription.
 *
 * Un seul écran pour les deux : la variable _isRegister indique si on
 * affiche le formulaire d'inscription (avec le champ nom) ou de connexion.
 * Après une connexion réussie, on ne navigue pas : AuthGate (main.dart)
 * détecte l'utilisateur connecté et affiche l'écran suivant.
 */
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty || (_isRegister && name.isEmpty)) {
      setState(() => _error = tr('fillAll'));
      return;
    }

    await _run(() {
      if (_isRegister) {
        return _auth.register(name: name, email: email, password: password);
      }
      return _auth.login(email: email, password: password);
    });
  }

  /*
   * Exécute une action de connexion en affichant le chargement et les erreurs.
   * Utilisée pour l'email et pour Google, pour ne pas répéter le même code.
   */
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _error = AuthService.errorMessage(e.code);
    } catch (_) {
      _error = tr('errorUnknown');
    }
    // L'écran peut avoir disparu si la connexion a réussi.
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SengueAI'),
        actions: const [LanguageButton()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            // Sur un grand écran (web), le formulaire garde une largeur lisible.
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundImage: AssetImage('assets/images/sengue_avatar.png'),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('slogan'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                if (_isRegister) ...[
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: tr('name')),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: tr('email')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: tr('password')),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(tr(_isRegister ? 'register' : 'login')),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _isRegister = !_isRegister;
                    _error = null;
                  }),
                  child: Text(tr(_isRegister ? 'haveAccount' : 'noAccount')),
                ),
                const SizedBox(height: 8),
                Text(tr('or'), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _run(_auth.loginWithGoogle),
                  icon: const Icon(Icons.account_circle),
                  label: Text(tr('google')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
