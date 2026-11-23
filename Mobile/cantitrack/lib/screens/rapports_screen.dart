import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import '../theme.dart';
import '../widgets.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  int _jours = 7;

  DateTime get _debut {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).subtract(Duration(days: _jours - 1));
  }

  DateTime get _fin {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).add(const Duration(days: 1));
  }

  String _periode() => _jours == 1
      ? fmtDate(_debut)
      : '${fmtDate(_debut)} au ${fmtDate(_fin.subtract(const Duration(days: 1)))}';

  Future<void> _partager(Rapport r) async {
    final ecole = await AppDb.instance.param('ecole') ?? '';
    final auteur = await AppDb.instance.param('utilisateur') ?? '';
    final b = StringBuffer()
      ..writeln('Rapport cantine - $ecole')
      ..writeln('Période : ${_periode()}')
      ..writeln('Repas servis : ${r.repas} (${r.eleves} élèves servis au total)')
      ..writeln('')
      ..writeln('Produits :');
    for (final l in r.lignes) {
      b.writeln('- ${l.nom} : entrées ${fmtQte(l.entrees)} ${l.unite}, '
          'sorties ${fmtQte(l.sorties)} ${l.unite}, pertes ${fmtQte(l.pertes)} ${l.unite}, '
          'stock ${fmtQte(l.stock)} ${l.unite}');
    }
    b
      ..writeln('')
      ..writeln('Établi par : $auteur (CantiTrack)');
    await Share.share(b.toString(), subject: 'Rapport cantine - $ecole');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Wrap(
              spacing: 8,
              children: [
                for (final j in [1, 7, 30])
                  ChoiceChip(
                    label: Text(j == 1 ? 'Aujourd’hui' : '$j jours'),
                    selected: _jours == j,
                    onSelected: (_) => setState(() => _jours = j),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: AppDb.instance.changes,
              builder: (context, _, __) => FutureBuilder<Rapport>(
                future: AppDb.instance.rapport(_debut, _fin),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final r = snap.data!;
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Row(
                        children: [
                          Expanded(child: _stat('Repas servis', '${r.repas}')),
                          Expanded(child: _stat('Élèves servis', '${r.eleves}')),
                        ],
                      ),
                      for (final l in r.lignes)
                        Carte(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                'Entrées ${fmtQte(l.entrees)} · Sorties ${fmtQte(l.sorties)} · '
                                'Pertes ${fmtQte(l.pertes)} ${l.unite}',
                                style: styleSecondaire,
                              ),
                              Text('Stock actuel : ${fmtQte(l.stock)} ${l.unite}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: FilledButton.icon(
                          onPressed: () => _partager(r),
                          icon: const Icon(Icons.share),
                          label: const Text('Partager (WhatsApp, SMS…)'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String titre, String valeur) => Carte(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: styleSecondaire),
            Text(valeur,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w700, color: Couleurs.vertFonce)),
          ],
        ),
      );
}
