import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'mouvement_form.dart';
import 'sauvegarde_screen.dart';

class _Donnees {
  final String ecole;
  final List<ProduitStock> produits;
  final MenuJour? prochain;
  final int enAttente;

  const _Donnees(this.ecole, this.produits, this.prochain, this.enAttente);
}

class AccueilScreen extends StatelessWidget {
  final void Function(int) allerA;

  const AccueilScreen({super.key, required this.allerA});

  Future<_Donnees> _charger() async {
    final db = AppDb.instance;
    final produits = await db.produitsAvecStock();
    final menus = await db.menus();
    final n = DateTime.now();
    final aujourdhui = DateTime(n.year, n.month, n.day);
    MenuJour? prochain;
    for (final m in menus.reversed) {
      if (m.statut == 'PREVU' && !m.date.isBefore(aujourdhui)) {
        prochain = m;
        break;
      }
    }
    return _Donnees(
      await db.param('ecole') ?? '',
      produits,
      prochain,
      await db.operationsEnAttente(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppDb.instance.changes,
      builder: (context, _, __) => FutureBuilder<_Donnees>(
        future: _charger(),
        builder: (context, snap) {
          final d = snap.data;
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CantiTrack', style: TextStyle(fontWeight: FontWeight.w700)),
                  if (d != null && d.ecole.isNotEmpty)
                    Text(d.ecole, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            body: d == null
                ? const Center(child: CircularProgressIndicator())
                : _contenu(context, d),
          );
        },
      ),
    );
  }

  Widget _contenu(BuildContext context, _Donnees d) {
    final alertes = d.produits.where((p) => p.enAlerte).toList();
    final prochain = d.prochain;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (alertes.isNotEmpty)
          Carte(
            couleur: Couleurs.alerteFond,
            onTap: () => allerA(1),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Couleurs.alerte),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${alertes.length} produit(s) sous le seuil',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(alertes.map((p) => p.nom).join(', '), style: styleSecondaire),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          )
        else
          Carte(
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Couleurs.vert),
                SizedBox(width: 12),
                Expanded(child: Text('Aucun produit sous le seuil d’alerte')),
              ],
            ),
          ),
        Carte(
          onTap: () => allerA(2),
          child: Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Couleurs.vert),
              const SizedBox(width: 12),
              Expanded(
                child: prochain == null
                    ? const Text('Aucun menu programmé. Appuyez pour en ajouter.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prochain menu · ${fmtDate(prochain.date)}', style: styleSecondaire),
                          Text(prochain.plat, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${prochain.effectifPrevu} élèves prévus', style: styleSecondaire),
                        ],
                      ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        Carte(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SauvegardeScreen())),
          child: Row(
            children: [
              Icon(d.enAttente == 0 ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                  color: d.enAttente == 0 ? Couleurs.vert : Couleurs.texteSecondaire),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sauvegarde', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      d.enAttente == 0
                          ? 'Tout est envoyé au serveur'
                          : '${d.enAttente} opération(s) pas encore envoyée(s) au serveur',
                      style: styleSecondaire,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FilledButton.icon(
            onPressed: () async {
              final produits = await AppDb.instance.produitsAvecStock();
              if (!context.mounted) return;
              await showMouvementSheet(context, produits);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nouveau mouvement'),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: OutlinedButton.icon(
            onPressed: () => allerA(2),
            icon: const Icon(Icons.restaurant),
            label: const Text('Servir le repas du jour'),
          ),
        ),
      ],
    );
  }
}
