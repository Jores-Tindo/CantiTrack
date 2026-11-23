import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import '../export.dart';
import '../theme.dart';
import '../widgets.dart';
import 'mouvement_form.dart';

class RegistreScreen extends StatefulWidget {
  const RegistreScreen({super.key});

  @override
  State<RegistreScreen> createState() => _RegistreScreenState();
}

class _RegistreScreenState extends State<RegistreScreen> {
  int _jours = 7; // 0 = toutes les opérations

  DateTime? get _debut {
    if (_jours == 0) return null;
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).subtract(Duration(days: _jours - 1));
  }

  String get _periode =>
      _jours == 0 ? 'Toutes les opérations' : (_jours == 1 ? 'Aujourd’hui' : '$_jours derniers jours');

  Future<void> _exporter() async {
    try {
      final liste = await AppDb.instance.registre(debut: _debut);
      final ecole = await AppDb.instance.param('ecole') ?? '';
      await exporterRegistrePdf(liste, ecole, _periode);
    } catch (e) {
      if (mounted) afficherMessage(context, 'Export impossible : ${messageErreur(e)}');
    }
  }

  void _details(Mouvement m) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Opération N° ${m.numero.toString().padLeft(4, '0')}',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${libelleType[m.type] ?? m.type} · ${m.produit}'),
            Text('${m.estEntree ? '+' : '−'}${fmtQte(m.quantite)} ${m.unite}'),
            Text(fmtDateHeure(m.date), style: styleSecondaire),
            if (m.auteur != null) Text('Saisie par ${m.auteur}', style: styleSecondaire),
            if (m.motif != null) Text('Motif / source : ${m.motif}', style: styleSecondaire),
            const SizedBox(height: 12),
            const Text(
              'Cette opération est validée : elle ne peut pas être modifiée ni supprimée. '
              'Pour corriger une erreur, enregistrez une rectification (nouvelle ligne avec son motif).',
              style: styleSecondaire,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final produits = await AppDb.instance.produitsAvecStock();
                if (!mounted) return;
                final p = produits.where((x) => x.id == m.produitId).firstOrNull;
                await showMouvementSheet(context, produits, produit: p, rectification: true);
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('Rectifier le stock'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registre numérique'),
        actions: [
          IconButton(
            tooltip: 'Exporter en PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exporter,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Wrap(
              spacing: 8,
              children: [
                for (final j in [1, 7, 30, 0])
                  ChoiceChip(
                    label: Text(j == 0 ? 'Tout' : (j == 1 ? 'Aujourd’hui' : '$j jours')),
                    selected: _jours == j,
                    onSelected: (_) => setState(() => _jours = j),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: AppDb.instance.changes,
              builder: (context, _, __) => FutureBuilder<List<Mouvement>>(
                future: AppDb.instance.registre(debut: _debut),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final liste = snap.data!;
                  if (liste.isEmpty) {
                    return const EtatVide(
                      icone: Icons.menu_book_outlined,
                      message: 'Aucune opération sur cette période.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: liste.length,
                    itemBuilder: (context, i) {
                      final m = liste[i];
                      final couleur = m.estEntree ? Couleurs.vert : Couleurs.alerte;
                      return Carte(
                        onTap: () => _details(m),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'N° ${m.numero.toString().padLeft(4, '0')} · ${libelleType[m.type] ?? m.type} · ${m.produit}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${fmtDateHeure(m.date)}${m.auteur != null ? ' · ${m.auteur}' : ''}'
                                    '${m.motif != null ? '\n${m.motif}' : ''}',
                                    style: styleSecondaire,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${m.estEntree ? '+' : '−'}${fmtQte(m.quantite)} ${m.unite}',
                              style: TextStyle(fontWeight: FontWeight.w700, color: couleur),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
