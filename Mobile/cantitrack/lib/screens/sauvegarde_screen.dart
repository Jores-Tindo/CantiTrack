import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/app_db.dart';
import '../db/models.dart';
import '../theme.dart';
import '../widgets.dart';

class SauvegardeScreen extends StatelessWidget {
  const SauvegardeScreen({super.key});

  Future<void> _exporterCopie(BuildContext context) async {
    try {
      final source = File(await AppDb.instance.cheminBase());
      final dir = await getTemporaryDirectory();
      final n = DateTime.now();
      final nom =
          'cantitrack_sauvegarde_${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}.db';
      final copie = await source.copy('${dir.path}/$nom');
      await Share.shareXFiles([XFile(copie.path)], text: 'Copie de sauvegarde CantiTrack');
    } catch (e) {
      if (context.mounted) afficherMessage(context, 'Copie impossible : ${messageErreur(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegarde et restauration')),
      body: ValueListenableBuilder<int>(
        valueListenable: AppDb.instance.changes,
        builder: (context, _, __) => FutureBuilder<(int, int, String?)>(
          future: () async {
            final db = AppDb.instance;
            return (await db.operationsEnAttente(), await db.nombreOperations(), await db.param('derniere_sync'));
          }(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final (attente, total, derniere) = snap.data!;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Carte(
                  couleur: attente == 0 ? Couleurs.vertClair : Couleurs.alerteFond,
                  child: Row(
                    children: [
                      Icon(attente == 0 ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                          color: attente == 0 ? Couleurs.vert : Couleurs.alerte),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          attente == 0
                              ? 'Toutes vos données sont envoyées au serveur'
                              : '$attente opération(s) pas encore envoyée(s) au serveur',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Carte(
                  child: Column(
                    children: [
                      _ligne('Dernière synchronisation', derniere ?? 'Jamais'),
                      const Divider(),
                      _ligne('Opérations dans le registre', '$total'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FilledButton.icon(
                    onPressed: () => afficherMessage(context,
                        'Le serveur central n’est pas encore connecté : la synchronisation arrive à la prochaine étape.'),
                    icon: const Icon(Icons.sync),
                    label: const Text('Synchroniser maintenant'),
                  ),
                ),
                const SizedBox(height: 16),
                const Carte(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Copie de sauvegarde', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text(
                        'En attendant le serveur, envoyez une copie du registre sur WhatsApp, par e-mail ou sur une clé USB, et gardez-la en lieu sûr.',
                        style: styleSecondaire,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => _exporterCopie(context),
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Envoyer une copie de sauvegarde'),
                  ),
                ),
                const SizedBox(height: 16),
                const Carte(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nouveau téléphone ?', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text(
                        'Dès que le serveur central sera connecté, vous retrouverez tout le registre de l’école en vous connectant avec votre compte.',
                        style: styleSecondaire,
                      ),
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

  Widget _ligne(String a, String b) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(a), Text(b, style: const TextStyle(fontWeight: FontWeight.w700))],
      );
}
