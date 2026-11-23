import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';

class MenusScreen extends StatelessWidget {
  const MenusScreen({super.key});

  void _message(BuildContext context, String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _programmer(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _MenuForm(),
      ),
    );
  }

  Future<void> _servir(BuildContext context, MenuJour m) async {
    final ctrl = TextEditingController(text: m.effectifPrevu.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servir ce repas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.plat, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Les sorties de stock seront enregistrées automatiquement.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre d’élèves servis',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Valider')),
        ],
      ),
    );
    final n = int.tryParse(ctrl.text.trim()) ?? 0;
    ctrl.dispose();
    if (ok != true || !context.mounted) return;
    try {
      await AppDb.instance.servirMenu(m.id, n);
      if (context.mounted) _message(context, 'Repas enregistré, stock mis à jour');
    } catch (e) {
      if (context.mounted) {
        _message(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Widget _carte(BuildContext context, MenuJour m) {
    final prevu = m.statut == 'PREVU';
    final statut = prevu ? 'Prévu' : (m.statut == 'SERVI' ? 'Servi' : 'Annulé');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(m.plat, style: Theme.of(context).textTheme.titleMedium),
                ),
                Chip(label: Text(statut)),
              ],
            ),
            const SizedBox(height: 4),
            Text(fmtDate(m.date)),
            Text(m.statut == 'SERVI'
                ? 'Élèves servis : ${m.effectifServi ?? 0}'
                : 'Effectif prévu : ${m.effectifPrevu}'),
            if (prevu)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _servir(context, m),
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Servir'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menus')),
      body: ValueListenableBuilder<int>(
        valueListenable: AppDb.instance.changes,
        builder: (context, _, __) => FutureBuilder<List<MenuJour>>(
          future: AppDb.instance.menus(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final menus = snap.data!;
            if (menus.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun menu programmé.\nAppuyez sur « Programmer » pour commencer.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: menus.length,
              itemBuilder: (context, i) => _carte(context, menus[i]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _programmer(context),
        icon: const Icon(Icons.add),
        label: const Text('Programmer'),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Formulaire de programmation d'un menu
// ----------------------------------------------------------------------
class _MenuForm extends StatefulWidget {
  const _MenuForm();

  @override
  State<_MenuForm> createState() => _MenuFormState();
}

class _MenuFormState extends State<_MenuForm> {
  final _effectif = TextEditingController();
  List<Plat> _plats = [];
  int? _platId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _effectif.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final plats = await AppDb.instance.plats();
    final effectif = await AppDb.instance.effectifParDefaut();
    if (!mounted) return;
    setState(() {
      _plats = plats;
      _platId = plats.isNotEmpty ? plats.first.id : null;
      _effectif.text = effectif.toString();
    });
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
    final effectif = int.tryParse(_effectif.text.trim()) ?? 0;
    if (_platId == null) return;
    setState(() {
      _saving = true;
      _erreur = null;
    });
    try {
      await AppDb.instance.programmerMenu(
        date: _date,
        platId: _platId!,
        effectif: effectif,
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
    final effectif = int.tryParse(_effectif.text.trim()) ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Programmer un menu', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _choisirDate,
            icon: const Icon(Icons.event),
            label: Text('Date : ${fmtDate(_date)}'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _platId,
            decoration: const InputDecoration(
              labelText: 'Plat',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final p in _plats) DropdownMenuItem(value: p.id, child: Text(p.nom)),
            ],
            onChanged: (v) => setState(() => _platId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _effectif,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Effectif prévu (élèves)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_platId != null && effectif > 0) ...[
            Text('Besoin en vivres', style: Theme.of(context).textTheme.titleMedium),
            _BesoinList(platId: _platId!, effectif: effectif),
          ],
          if (_erreur != null) ...[
            const SizedBox(height: 8),
            Text(_erreur!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_saving || _platId == null) ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _BesoinList extends StatelessWidget {
  final int platId;
  final int effectif;

  const _BesoinList({required this.platId, required this.effectif});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BesoinLigne>>(
      future: AppDb.instance.besoin(platId, effectif),
      builder: (context, snap) {
        final lignes = snap.data;
        if (lignes == null) return const SizedBox.shrink();
        return Column(
          children: [
            for (final l in lignes)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  l.suffisant ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: l.suffisant ? Colors.green : Colors.red,
                ),
                title: Text(l.produit),
                subtitle: Text('Stock : ${fmtQte(l.stock)} ${l.unite}'),
                trailing: Text('${fmtQte(l.besoin)} ${l.unite}'),
              ),
          ],
        );
      },
    );
  }
}
