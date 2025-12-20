import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegister = false;
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        (_isRegister && _companyController.text.isEmpty)) {
      _showError('Compila tutti i campi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isRegister) {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final uid = cred.user!.uid;

        await _db.collection('companies').doc(uid).set({
          'name': _companyController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Errore di autenticazione');
    } catch (_) {
      _showError('Errore imprevisto');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isRegister ? 'Registrazione Azienda' : 'Accesso',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),

                if (_isRegister)
                  TextField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Nome azienda',
                    ),
                  ),

                if (_isRegister) const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isRegister ? 'Registrati' : 'Accedi'),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _isRegister = !_isRegister),
                  child: Text(
                    _isRegister
                        ? 'Hai già un account? Accedi'
                        : 'Non hai un account? Registrati',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
