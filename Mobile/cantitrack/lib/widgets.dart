import 'package:flutter/material.dart';

import 'theme.dart';

class Carte extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? couleur;
  final VoidCallback? onTap;

  const Carte({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.couleur,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Material(
        color: couleur ?? Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Couleurs.bordure),
        ),
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class Pastille extends StatelessWidget {
  final String texte;
  final Color couleur;
  final Color fond;

  const Pastille({
    super.key,
    required this.texte,
    this.couleur = Couleurs.vert,
    this.fond = Couleurs.vertClair,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(8)),
      child: Text(texte,
          style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class EtatVide extends StatelessWidget {
  final IconData icone;
  final String message;

  const EtatVide({super.key, required this.icone, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: Couleurs.texteSecondaire),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: styleSecondaire),
          ],
        ),
      ),
    );
  }
}

void afficherMessage(BuildContext context, String texte) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texte)));
}

String messageErreur(Object e) => e.toString().replaceFirst('Exception: ', '');

double? lireNombre(String texte) => double.tryParse(texte.trim().replaceAll(',', '.'));
