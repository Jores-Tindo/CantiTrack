import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'mouvement_form.dart';

class ProduitDetailScreen extends StatelessWidget {
  final int produitId;

  const ProduitDetailScreen({super.key, required this.produitId});

  Future<(List<ProduitStock>, List<Mouvement>)> _charger() async {
    final produits = await AppDb.instance.produitsAvecStock();
    final mouvements = await AppDb.instance.registre(produitId: produitId, limite: 100);
    return (produits, mouvements);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppDb.instance.changes,
      builder: (context, _, __) => FutureBuilder<(List<ProduitStock>, List<Mouvement>)>(
        future: _charger(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Scaffold(
              appBar: AppBar(title: const Text('Produit')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          final (produits, mouvements) = snap.data!;
          final p = produits.firstWhere((x) => x.id == produitId);
          return Scaffold(
            appBar: AppBar(title: Text(p.nom)),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Carte(
                  couleur: p.enAlerte ? Couleurs.alerteFond : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stock actuel', style: styleSecondaire),
                      Text('${fmtQte(p.stock)} ${p.unite}',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: p.enAlerte ? Couleurs.alerte : Couleurs.vertFonce)),
                      Text('Seuil d’alerte : ${fmtQte(p.seuil)} ${p.unite}'
                          '${p.enAlerte ? ' · sous le seuil' : ''}',
                          style: styleSecondaire),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      for (final t in ['ENTREE', 'SORTIE', 'PERTE']) ...[
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                            onPressed: () =>
                                showMouvementSheet(context, produits, produit: p, type: t),
                            child: Text(libelleType[t]!),
                          ),
                        ),
                        if (t != 'PERTE') const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Historique du produit', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (mouvements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun mouvement pour ce produit.', style: styleSecondaire),
                  ),
                for (final m in mouvements)
                  Carte(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('N° ${m.numero.toString().padLeft(4, '0')} · ${libelleType[m.type] ?? m.type}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '${fmtDateHeure(m.date)}${m.motif != null ? '\n${m.motif}' : ''}',
                                style: styleSecondaire,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${m.estEntree ? '+' : '−'}${fmtQte(m.quantite)} ${m.unite}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: m.estEntree ? Couleurs.vert : Couleurs.alerte),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
