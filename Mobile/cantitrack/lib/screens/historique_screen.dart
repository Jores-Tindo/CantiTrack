import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';

class HistoriqueScreen extends StatelessWidget {
  const HistoriqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: ValueListenableBuilder<int>(
        valueListenable: AppDb.instance.changes,
        builder: (context, _, __) => FutureBuilder<List<Mouvement>>(
          future: AppDb.instance.historique(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final liste = snap.data!;
            if (liste.isEmpty) {
              return const Center(child: Text('Aucun mouvement enregistré.'));
            }
            return ListView.separated(
              itemCount: liste.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = liste[i];
                final couleur = m.estEntree ? Colors.green : Colors.red;
                final signe = m.estEntree ? '+' : '−';
                return ListTile(
                  leading: Icon(
                    m.estEntree ? Icons.south_west : Icons.north_east,
                    color: couleur,
                  ),
                  title: Text('${libelleType[m.type] ?? m.type} · ${m.produit}'),
                  subtitle: Text(
                    '${fmtDateHeure(m.date)}${m.motif != null ? '\n${m.motif}' : ''}',
                  ),
                  isThreeLine: m.motif != null,
                  trailing: Text(
                    '$signe${fmtQte(m.quantite)} ${m.unite}',
                    style: TextStyle(color: couleur, fontWeight: FontWeight.bold),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
