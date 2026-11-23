import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import 'mouvement_form.dart';
import 'produit_detail_screen.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  Future<void> _nouveau(BuildContext context) async {
    final produits = await AppDb.instance.produitsAvecStock();
    if (!context.mounted) return;
    await showMouvementSheet(context, produits);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      body: ValueListenableBuilder<int>(
        valueListenable: AppDb.instance.changes,
        builder: (context, _, __) => FutureBuilder<List<ProduitStock>>(
          future: AppDb.instance.produitsAvecStock(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final produits = snap.data!;
            final alertes = produits.where((p) => p.enAlerte).length;
            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                if (alertes > 0)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              '$alertes produit(s) sous le seuil d’alerte'),
                        ),
                      ],
                    ),
                  ),
                for (final p in produits)
                  ListTile(
                    leading: Icon(
                      p.enAlerte ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: p.enAlerte ? Colors.red : Colors.green,
                    ),
                    title: Text(p.nom),
                    subtitle: Text('Seuil d’alerte : ${fmtQte(p.seuil)} ${p.unite}'),
                    trailing: Text(
                      '${fmtQte(p.stock)} ${p.unite}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProduitDetailScreen(produitId: p.id)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nouveau(context),
        icon: const Icon(Icons.add),
        label: const Text('Mouvement'),
      ),
    );
  }
}
