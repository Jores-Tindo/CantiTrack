import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';

/// Ouvre le formulaire d'enregistrement d'un mouvement de stock.
Future<void> showMouvementSheet(
  BuildContext context,
  List<ProduitStock> produits, {
  ProduitStock? produit,
  String type = 'ENTREE',
  bool rectification = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _MouvementForm(
          produits: produits, produit: produit, type: type, rectification: rectification),
    ),
  );
}

class _MouvementForm extends StatefulWidget {
  final List<ProduitStock> produits;
  final ProduitStock? produit;
  final String type;
  final bool rectification;

  const _MouvementForm({
    required this.produits,
    required this.produit,
    required this.type,
    this.rectification = false,
  });

  @override
  State<_MouvementForm> createState() => _MouvementFormState();
}

class _MouvementFormState extends State<_MouvementForm> {
  final _formKey = GlobalKey<FormState>();
  final _qte = TextEditingController();
  final _motif = TextEditingController();
  late int? _produitId;
  late String _type;
  bool _saving = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _type = widget.rectification && !widget.type.startsWith('AJUSTEMENT')
        ? 'AJUSTEMENT_PLUS'
        : widget.type;
    _produitId = widget.produit?.id ??
        (widget.produits.isNotEmpty ? widget.produits.first.id : null);
  }

  @override
  void dispose() {
    _qte.dispose();
    _motif.dispose();
    super.dispose();
  }

  String get _unite {
    for (final p in widget.produits) {
      if (p.id == _produitId) return p.unite;
    }
    return '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _produitId == null) return;
    setState(() {
      _saving = true;
      _erreur = null;
    });
    try {
      await AppDb.instance.ajouterMouvement(
        produitId: _produitId!,
        type: _type,
        quantite: double.parse(_qte.text.trim().replaceAll(',', '.')),
        motif: _motif.text.trim().isEmpty ? null : _motif.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _erreur = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.rectification ? 'Rectification du stock' : 'Nouveau mouvement de stock',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                for (final t in (widget.rectification
                    ? ['AJUSTEMENT_PLUS', 'AJUSTEMENT_MOINS']
                    : ['ENTREE', 'SORTIE', 'PERTE']))
                  ButtonSegment(value: t, label: Text(libelleType[t] ?? t)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _produitId,
              decoration: const InputDecoration(
                labelText: 'Produit',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in widget.produits)
                  DropdownMenuItem(value: p.id, child: Text(p.nom)),
              ],
              onChanged: (v) => setState(() => _produitId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qte,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantité ($_unite)',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Entrez une quantité valide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motif,
              decoration: InputDecoration(
                labelText: _type == 'ENTREE'
                    ? 'Source / n° du bordereau (facultatif)'
                    : (_type == 'PERTE' || widget.rectification)
                        ? 'Motif (obligatoire)'
                        : 'Motif (facultatif)',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if ((_type == 'PERTE' || widget.rectification) && (v ?? '').trim().isEmpty) {
                  return 'Précisez le motif';
                }
                return null;
              },
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
