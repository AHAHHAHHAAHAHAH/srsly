import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  // nuovi campi companies (scontrino)
  final _ownerCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  final AuthService _auth = AuthService.instance;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _companyCtrl.dispose();

    _ownerCtrl.dispose();
    _streetCtrl.dispose();
    _capCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.registerWithCompany(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        companyName: _companyCtrl.text.trim(),
        ownerFullName: _ownerCtrl.text.trim(),
        addressStreet: _streetCtrl.text.trim(),
        addressCap: _capCtrl.text.trim(),
        addressCity: _cityCtrl.text.trim(),
        ownerPhone: _phoneCtrl.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Errore durante la registrazione');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardWidth = w < 560 ? w - 32 : 520.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione')),
      body: Center(
        child: SizedBox(
          width: cardWidth,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront_outlined),
                        SizedBox(width: 10),
                        Text(
                          'Crea la tua lavanderia',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Questi dati verranno usati anche nello scontrino.',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dati attività
                    TextField(
                      controller: _companyCtrl,
                      decoration: _dec(
                        'Nome lavanderia',
                        hint: 'Es. Kappa5CristoLaMadonna',
                        icon: Icons.business_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // placeholder SOLO UI (non firestore)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_laundry_service_outlined, color: Colors.black.withOpacity(0.55)),
                          const SizedBox(width: 10),
                          Text(
                            'Smacchiatoria',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Dati scontrino
                    TextField(
                      controller: _ownerCtrl,
                      decoration: _dec('Nome e cognome OWNER', icon: Icons.person_outline),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _streetCtrl,
                      decoration: _dec('Via + n° civico', icon: Icons.location_on_outlined),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _capCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _dec('CAP'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _cityCtrl,
                            decoration: _dec('Località / Città'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _dec('Telefono OWNER', icon: Icons.call_outlined),
                    ),

                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Account
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dec('Email', icon: Icons.alternate_email),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: _dec('Password', icon: Icons.lock_outline),
                    ),

                    const SizedBox(height: 14),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                        ),
                      ),

                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _register,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_loading ? 'Creazione...' : 'Crea account'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
