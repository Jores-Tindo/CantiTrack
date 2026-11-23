import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'db/models.dart';

/// Génère le registre en PDF (colonnes proches du cahier papier) et le partage.
Future<void> exporterRegistrePdf(List<Mouvement> liste, String ecole, String periode) async {
  final doc = pw.Document();
  final chrono = liste.reversed.toList();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      header: (c) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Registre de la cantine - $ecole',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(periode),
          pw.SizedBox(height: 8),
        ],
      ),
      footer: (c) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${c.pageNumber}/${c.pagesCount}'),
      ),
      build: (c) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headers: ['N°', 'Date', 'Operation', 'Produit', 'Quantite', 'Auteur', 'Motif / source', 'Signature'],
          data: [
            for (final m in chrono)
              [
                m.numero.toString().padLeft(4, '0'),
                fmtDateHeure(m.date),
                libelleType[m.type] ?? m.type,
                m.produit,
                '${m.estEntree ? '+' : '-'}${fmtQte(m.quantite)} ${m.unite}',
                m.auteur ?? '',
                m.motif ?? '',
                '',
              ],
          ],
        ),
      ],
    ),
  );
  final dir = await getTemporaryDirectory();
  final fichier = File('${dir.path}/registre_cantitrack.pdf');
  await fichier.writeAsBytes(await doc.save());
  await Share.shareXFiles([XFile(fichier.path)], text: 'Registre de la cantine - $ecole');
}
