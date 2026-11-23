import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'reception_screen.dart';

class LivraisonsScreen extends StatelessWidget {
  const LivraisonsScreen({super.key});

  Widget _statut(String s) {
    switch (s) {
      case 'RECUE':
        return const Pastille(texte: 'Reçue');
      case 'PARTIELLE':
        return const Pastille(
            texte: 'Partielle', couleur: Couleurs.alerte, fond: Couleurs.alerteFond);
      default:
        return const Pastille(
            texte: 'Attendue', couleur: Couleurs.texteSecondaire, fond: Color(0xFFE9ECE6));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Livraisons')),
      body: ValueListenableBuilder<int>(
        valueListenable: AppDb.instance.changes,
        builder: (context, _, __) => FutureBuilder<List<Livraison>>(
          future: AppDb.instance.livraisons(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final liste = snap.data!;
            if (liste.isEmpty) {
              return const EtatVide(
                icone: Icons.local_shipping_outlined,
                message: 'Aucune livraison enregistrée.\nAjoutez une livraison attendue pour préparer la réception.',
              );
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                for (final l in liste)
                  Carte(
                    onTap: l.statut == 'ATTENDUE'
                        ? () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ReceptionScreen(livraison: l)))
                        : null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.fournisseur, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                '${l.nbLignes} produit(s)'
                                '${l.numeroBon != null ? ' · bordereau ${l.numeroBon}' : ''}\n'
                                '${l.statut == 'ATTENDUE' ? 'Prévue le ${l.datePrevue != null ? fmtDate(l.datePrevue!) : '-'}' : 'Reçue le ${l.dateReception != null ? fmtDate(l.dateReception!) : '-'}'}',
                                style: styleSecondaire,
                              ),
                            ],
                          ),
                        ),
                        _statut(l.statut),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (ctx) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: const _LivraisonForm(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Livraison attendue'),
      ),
    );
  }
}

class _LigneEdit {
  int? produitId;
  final TextEditingController qte = TextEditingController();
}

class _LivraisonForm extends StatefulWidget {
  const _LivraisonForm();

  @override
  State<_LivraisonForm> createState() => _LivraisonFormState();
}

class _LivraisonFormState extends State<_LivraisonForm> {
  final _fournisseur = TextEditingController(text: 'État');
  final _bon = TextEditingController();
  final _lignes = <_LigneEdit>[_LigneEdit()];
  List<ProduitStock> _produits = [];
  DateTime _date = DateTime.now();
  String? _erreur;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AppDb.instance.produitsAvecStock().then((p) {
      if (mounted) setState(() => _produits = p);
    });
  }

  @override
  void dispose() {
    _fournisseur.dispose();
    _bon.dispose();
    for (final l in _lignes) {
      l.qte.dispose();
    }
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final quantites = <int, double>{};
    for (final l in _lignes) {
      final q = lireNombre(l.qte.text);
      if (l.produitId == null || q == null || q <= 0) {
        setState(() => _erreur = 'Chaque ligne doit avoir un produit et une quantité valide');
        return;
      }
      quantites[l.produitId!] = (quantites[l.produitId!] ?? 0) + q;
    }
    setState(() {
      _saving = true;
      _erreur = null;
    });
    try {
      await AppDb.instance.creerLivraison(
        fournisseur: _fournisseur.text,
        numeroBon: _bon.text,
        datePrevue: _date,
        quantites: quantites,
      );
      if (mounted) Navigator.pop(context);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Livraison attendue', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _fournisseur,
            decoration: const InputDecoration(labelText: 'Fournisseur', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bon,
            decoration: const InputDecoration(
                labelText: 'N° du bordereau (facultatif)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _choisirDate,
            icon: const Icon(Icons.event),
            label: Text('Date prévue : ${fmtDate(_date)}'),
          ),
          const SizedBox(height: 12),
          const Text('Produits attendus', style: TextStyle(fontWeight: FontWeight.w700)),
          for (var i = 0; i < _lignes.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _lignes[i].produitId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Produit', border: OutlineInputBorder()),
                      items: [
                        for (final p in _produits)
                          DropdownMenuItem(value: p.id, child: Text('${p.nom} (${p.unite})')),
                      ],
                      onChanged: (v) => setState(() => _lignes[i].produitId = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _lignes[i].qte,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Qté', border: OutlineInputBorder()),
                    ),
                  ),
                  if (_lignes.length > 1)
                    IconButton(
                      tooltip: 'Retirer',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _lignes.removeAt(i).qte.dispose()),
                    ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () => setState(() => _lignes.add(_LigneEdit())),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un produit'),
          ),
          if (_erreur != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_erreur!, style: const TextStyle(color: Couleurs.alerte)),
            ),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
