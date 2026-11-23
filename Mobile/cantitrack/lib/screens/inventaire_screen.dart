import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import '../theme.dart';
import '../widgets.dart';

class InventaireScreen extends StatelessWidget {
  const InventaireScreen({super.key});

  Future<void> _details(BuildContext context, InventaireResume inv) async {
    final lignes = await AppDb.instance.lignesInventaire(inv.id);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inventaire du ${fmtDate(inv.date)}', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final l in lignes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(l.produit)),
                      Text(
                        '${fmtQte(l.theorique)} → ${fmtQte(l.reel)} ${l.unite}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (l.reel - l.theorique).abs() > 0.0005
                              ? Couleurs.alerte
                              : Couleurs.vert,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventaire')),
      body: ValueListenableBuilder<int>(
        valueListenable: AppDb.instance.changes,
        builder: (context, _, __) => FutureBuilder<List<InventaireResume>>(
          future: AppDb.instance.inventaires(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final liste = snap.data!;
            if (liste.isEmpty) {
              return const EtatVide(
                icone: Icons.fact_check_outlined,
                message: 'Aucun inventaire.\nComptez votre stock réel et comparez-le au stock du registre.',
              );
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                for (final inv in liste)
                  Carte(
                    onTap: () => _details(context, inv),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Inventaire du ${fmtDate(inv.date)}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        inv.ecarts == 0
                            ? const Pastille(texte: 'Aucun écart')
                            : Pastille(
                                texte: '${inv.ecarts} écart(s)',
                                couleur: Couleurs.alerte,
                                fond: Couleurs.alerteFond),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const NouvelInventaireScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel inventaire'),
      ),
    );
  }
}

class NouvelInventaireScreen extends StatefulWidget {
  const NouvelInventaireScreen({super.key});

  @override
  State<NouvelInventaireScreen> createState() => _NouvelInventaireScreenState();
}

class _NouvelInventaireScreenState extends State<NouvelInventaireScreen> {
  List<ProduitStock> _produits = [];
  final _reel = <int, TextEditingController>{};
  bool _chargement = true;
  bool _saving = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    AppDb.instance.produitsAvecStock().then((p) {
      if (!mounted) return;
      setState(() {
        _produits = p;
        for (final x in p) {
          _reel[x.id] = TextEditingController();
        }
        _chargement = false;
      });
    });
  }

  @override
  void dispose() {
    for (final c in _reel.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _valider() async {
    final lignes = <LigneInventaire>[];
    for (final p in _produits) {
      final r = lireNombre(_reel[p.id]!.text);
      if (r == null || r < 0) {
        setState(() => _erreur = 'Saisissez le stock réel de ${p.nom}');
        return;
      }
      lignes.add(LigneInventaire(produitId: p.id, theorique: p.stock, reel: r));
    }
    final ecarts = lignes.where((l) => (l.reel - l.theorique).abs() > 0.0005).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider l’inventaire ?'),
        content: Text(ecarts == 0
            ? 'Aucun écart constaté.'
            : '$ecarts écart(s) constaté(s). Un ajustement tracé sera ajouté au registre pour chacun.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _saving = true;
      _erreur = null;
    });
    try {
      await AppDb.instance.enregistrerInventaire(lignes);
      if (!mounted) return;
      Navigator.pop(context);
      afficherMessage(context, 'Inventaire enregistré');
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _erreur = messageErreur(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel inventaire')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Comptez chaque produit et saisissez la quantité réellement présente.',
                      style: styleSecondaire),
                ),
                for (final p in _produits)
                  Carte(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Registre : ${fmtQte(p.stock)} ${p.unite}', style: styleSecondaire),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _reel[p.id],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                                labelText: 'Réel (${p.unite})', border: const OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_erreur != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(_erreur!, style: const TextStyle(color: Couleurs.alerte)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _valider,
                    icon: const Icon(Icons.fact_check),
                    label: const Text('Valider l’inventaire'),
                  ),
                ),
              ],
            ),
    );
  }
}
