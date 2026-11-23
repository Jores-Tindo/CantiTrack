import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import 'inventaire_screen.dart';
import 'livraisons_screen.dart';
import 'rapports_screen.dart';
import 'reglages_screen.dart';
import 'sauvegarde_screen.dart';

class PlusScreen extends StatelessWidget {
  final VoidCallback onVerrouiller;

  const PlusScreen({super.key, required this.onVerrouiller});

  Widget _tuile(BuildContext context, IconData icone, String titre, String sous, Widget page) {
    return Carte(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icone, color: Couleurs.vert),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sous, style: styleSecondaire),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _tuile(context, Icons.local_shipping_outlined, 'Livraisons',
              'Livraisons attendues et réception', const LivraisonsScreen()),
          _tuile(context, Icons.fact_check_outlined, 'Inventaire',
              'Comparer le stock réel au registre', const InventaireScreen()),
          _tuile(context, Icons.assessment_outlined, 'Rapports',
              'Résumé à partager avec la hiérarchie', const RapportsScreen()),
          _tuile(context, Icons.cloud_sync_outlined, 'Sauvegarde et restauration',
              'État de la sauvegarde, copie du registre', const SauvegardeScreen()),
          _tuile(context, Icons.settings_outlined, 'Réglages',
              'École, effectif, seuils d’alerte', const ReglagesScreen()),
          Carte(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: Couleurs.vert),
              title: const Text('Verrouiller', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Redemander le code', style: styleSecondaire),
              onTap: onVerrouiller,
            ),
          ),
        ],
      ),
    );
  }
}
