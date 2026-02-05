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

  // Stile coerente con HomeScreen e LoginScreen
  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: icon == null ? null : Icon(icon, color: Colors.grey.shade400),
      labelStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardWidth = w < 560 ? w - 32 : 520.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Torna al login', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: SizedBox(
            width: cardWidth,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              elevation: 0, // Uso boxshadow manuale per coerenza
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.storefront_outlined, color: Colors.black),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crea la tua lavanderia',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Compila i dati aziendali',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        border: Border.all(color: Colors.blue.shade100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Questi dati verranno usati automaticamente per generare gli scontrini.',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dati attività
                    const Text('DATI ATTIVITÀ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _companyCtrl,
                      decoration: _dec(
                        'Nome lavanderia',
                        hint: 'Es. Lavanderia Pulito & Profumato',
                        icon: Icons.business_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // placeholder SOLO UI (non firestore)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_laundry_service_outlined, color: Colors.black.withOpacity(0.55)),
                          const SizedBox(width: 12),
                          Text(
                            'Smacchiatoria',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'PREDEFINITO',
                            style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.black.withOpacity(0.4)
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('INTESTAZIONE SCONTRINO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 12),

                    // Dati scontrino
                    TextField(
                      controller: _ownerCtrl,
                      decoration: _dec('Nome e cognome Titolare', icon: Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _streetCtrl,
                      decoration: _dec('Via + n° civico', icon: Icons.location_on_outlined),
                    ),
                    const SizedBox(height: 12),
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
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _cityCtrl,
                            decoration: _dec('Località / Città'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _dec('Telefono Titolare', icon: Icons.call_outlined),
                    ),

                    const SizedBox(height: 24),
                    const Text('CREDENZIALI ACCESSO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 12),

                    // Account
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dec('Email', icon: Icons.alternate_email),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: _dec('Password', icon: Icons.lock_outline),
                    ),

                    const SizedBox(height: 24),

                    if (_error != null)
                       Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600, fontSize: 13))),
                          ],
                        ),
                      ),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _register,
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          _loading ? 'Creazione in corso...' : 'Completa Registrazione',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
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