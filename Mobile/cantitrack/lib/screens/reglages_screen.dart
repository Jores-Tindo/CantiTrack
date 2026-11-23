import 'package:flutter/material.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import '../theme.dart';
import '../widgets.dart';

class ReglagesScreen extends StatelessWidget {
  const ReglagesScreen({super.key});

  Future<void> _modifier(BuildContext context, String titre, String cle, String? actuel,
      {bool nombre = false}) async {
    final ctrl = TextEditingController(text: actuel ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: nombre ? TextInputType.number : TextInputType.text,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    final valeur = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true) return;
    if (valeur.isEmpty || (nombre && (int.tryParse(valeur) == null || int.parse(valeur) <= 0))) {
      if (context.mounted) afficherMessage(context, 'Valeur invalide');
      return;
    }
    await AppDb.instance.setParam(cle, valeur);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ValueListenableBuilder<int>(
        valueListenable: AppDb.instance.changes,
        builder: (context, _, __) => FutureBuilder<List<String?>>(
          future: Future.wait([
            AppDb.instance.param('ecole'),
            AppDb.instance.param('utilisateur'),
            AppDb.instance.param('effectif_cantine'),
          ]),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final ecole = snap.data![0];
            final utilisateur = snap.data![1];
            final effectif = snap.data![2];
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Carte(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: const Text('École'),
                        subtitle: Text(ecole ?? '-'),
                        onTap: () => _modifier(context, 'Nom de l’école', 'ecole', ecole),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Votre nom'),
                        subtitle: Text(utilisateur ?? '-'),
                        onTap: () => _modifier(context, 'Votre nom', 'utilisateur', utilisateur),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.groups_outlined),
                        title: const Text('Élèves qui mangent à la cantine'),
                        subtitle: Text(effectif ?? '100'),
                        onTap: () => _modifier(
                            context, 'Effectif de la cantine', 'effectif_cantine', effectif,
                            nombre: true),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Seuils d’alerte'),
                        subtitle: const Text('Quantité minimale avant alerte, par produit'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const _SeuilsScreen())),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'Version 0.2 · les données restent sur ce téléphone jusqu’à la connexion au serveur central.',
                    style: styleSecondaire,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SeuilsScreen extends StatelessWidget {
  const _SeuilsScreen();

  Future<void> _modifier(BuildContext context, ProduitStock p) async {
    final ctrl = TextEditingController(text: fmtQte(p.seuil));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Seuil d’alerte : ${p.nom}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: p.unite, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    final v = lireNombre(ctrl.text);
    ctrl.dispose();
    if (ok != true) return;
    if (v == null || v < 0) {
      if (context.mounted) afficherMessage(context, 'Valeur invalide');
      return;
    }
    await AppDb.instance.majSeuil(p.id, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seuils d’alerte')),
      body: ValueListenableBuilder<int>(
        valueListenable: AppDb.instance.changes,
        builder: (context, _, __) => FutureBuilder<List<ProduitStock>>(
          future: AppDb.instance.produitsAvecStock(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            return ListView(
              children: [
                for (final p in snap.data!)
                  Carte(
                    onTap: () => _modifier(context, p),
                    child: Row(
                      children: [
                        Expanded(child: Text(p.nom, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text('${fmtQte(p.seuil)} ${p.unite}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit_outlined, size: 18, color: Couleurs.texteSecondaire),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
