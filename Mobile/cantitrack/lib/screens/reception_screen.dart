import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import '../theme.dart';
import '../widgets.dart';

class ReceptionScreen extends StatefulWidget {
  final Livraison livraison;

  const ReceptionScreen({super.key, required this.livraison});

  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends State<ReceptionScreen> {
  List<LivraisonLigne> _lignes = [];
  final _recue = <String, TextEditingController>{};
  final _abimee = <String, TextEditingController>{};
  bool _chargement = true;
  bool _saving = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    AppDb.instance.lignesLivraison(widget.livraison.id).then((l) {
      if (!mounted) return;
      setState(() {
        _lignes = l;
        for (final x in l) {
          _recue[x.id] = TextEditingController(text: fmtQte(x.prevue));
          _abimee[x.id] = TextEditingController(text: '0');
        }
        _chargement = false;
      });
    });
  }

  @override
  void dispose() {
    for (final c in [..._recue.values, ..._abimee.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _valider() async {
    final saisies = <LigneReception>[];
    for (final l in _lignes) {
      final r = lireNombre(_recue[l.id]!.text);
      final a = lireNombre(_abimee[l.id]!.text);
      if (r == null || a == null || r < 0 || a < 0) {
        setState(() => _erreur = 'Vérifiez les quantités de ${l.produit}');
        return;
      }
      saisies.add(LigneReception(
        ligneId: l.id,
        produitId: l.produitId,
        prevue: l.prevue,
        recue: r,
        abimee: a,
      ));
    }
    setState(() {
      _saving = true;
      _erreur = null;
    });
    try {
      await AppDb.instance.receptionnerLivraison(widget.livraison.id, saisies);
      if (!mounted) return;
      Navigator.pop(context);
      afficherMessage(context, 'Livraison réceptionnée, stock mis à jour');
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
    final l = widget.livraison;
    return Scaffold(
      appBar: AppBar(title: const Text('Réception')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Carte(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.fournisseur, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        '${l.numeroBon != null ? 'Bordereau ${l.numeroBon} · ' : ''}'
                        'Prévue le ${l.datePrevue != null ? fmtDate(l.datePrevue!) : '-'}',
                        style: styleSecondaire,
                      ),
                    ],
                  ),
                ),
                for (final x in _lignes)
                  Carte(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${x.produit} · prévu ${fmtQte(x.prevue)} ${x.unite}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _recue[x.id],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                    labelText: 'Reçu (${x.unite})', border: const OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _abimee[x.id],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                    labelText: 'Dont abîmé (${x.unite})',
                                    border: const OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'La quantité reçue entre dans le stock. La partie abîmée est enregistrée comme perte dans le registre.',
                    style: styleSecondaire,
                  ),
                ),
                if (_erreur != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(_erreur!, style: const TextStyle(color: Couleurs.alerte)),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _valider,
                    icon: const Icon(Icons.inventory),
                    label: const Text('Valider la réception'),
                  ),
                ),
              ],
            ),
    );
  }
}
