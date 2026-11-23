import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_db.dart';
import '../theme.dart';

String hacherPin(String pin) => sha256.convert(utf8.encode('cantitrack:$pin')).toString();

class LoginScreen extends StatefulWidget {
  final bool premiereFois;
  final VoidCallback onSuccess;

  const LoginScreen({super.key, required this.premiereFois, required this.onSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nom = TextEditingController();
  final _ecole = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  String? _utilisateur;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    if (!widget.premiereFois) {
      AppDb.instance.param('utilisateur').then((v) {
        if (mounted) setState(() => _utilisateur = v);
      });
    }
  }

  @override
  void dispose() {
    _nom.dispose();
    _ecole.dispose();
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final pin = _pin.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _erreur = 'Le code doit contenir 4 chiffres');
      return;
    }
    if (widget.premiereFois) {
      if (_nom.text.trim().isEmpty || _ecole.text.trim().isEmpty) {
        setState(() => _erreur = 'Renseignez votre nom et le nom de l’école');
        return;
      }
      if (pin != _pin2.text.trim()) {
        setState(() => _erreur = 'Les deux codes ne sont pas identiques');
        return;
      }
      await AppDb.instance.setParam('utilisateur', _nom.text.trim());
      await AppDb.instance.setParam('ecole', _ecole.text.trim());
      await AppDb.instance.setParam('pin_hash', hacherPin(pin));
      widget.onSuccess();
    } else {
      final attendu = await AppDb.instance.param('pin_hash');
      if (attendu == hacherPin(pin)) {
        widget.onSuccess();
      } else {
        setState(() => _erreur = 'Code incorrect');
      }
    }
  }

  Widget _champCode(TextEditingController c, String label) => TextField(
        controller: c,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        onSubmitted: (_) => _valider(),
      );

  Widget _champTexte(TextEditingController c, String label) => TextField(
        controller: c,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Couleurs.vert,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('CantiTrack',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Couleurs.vertFonce)),
                  const SizedBox(height: 4),
                  Text(
                    widget.premiereFois
                        ? 'Créez votre accès sur ce téléphone'
                        : (_utilisateur == null ? 'Entrez votre code' : 'Bonjour $_utilisateur'),
                    textAlign: TextAlign.center,
                    style: styleSecondaire,
                  ),
                  const SizedBox(height: 24),
                  if (widget.premiereFois) ...[
                    _champTexte(_nom, 'Votre nom'),
                    const SizedBox(height: 12),
                    _champTexte(_ecole, 'Nom de l’école'),
                    const SizedBox(height: 12),
                  ],
                  _champCode(_pin, widget.premiereFois ? 'Code à 4 chiffres' : 'Code'),
                  if (widget.premiereFois) ...[
                    const SizedBox(height: 12),
                    _champCode(_pin2, 'Confirmez le code'),
                  ],
                  if (_erreur != null) ...[
                    const SizedBox(height: 12),
                    Text(_erreur!, style: const TextStyle(color: Couleurs.alerte)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _valider,
                    child: Text(widget.premiereFois ? 'Créer mon accès' : 'Se connecter'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Le code protège les données sur ce téléphone. La connexion au serveur central viendra avec la synchronisation.',
                    textAlign: TextAlign.center,
                    style: styleSecondaire,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
