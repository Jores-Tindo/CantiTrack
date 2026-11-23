import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

/// Base locale SQLite (hors-ligne). Même logique que le schéma MySQL central :
/// le stock est toujours calculé à partir des mouvements.
/// Les colonnes `synced`, `date_modif` et `supprime` préparent la synchronisation.
class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();
  static const Uuid _uuid = Uuid();

  /// Incrémenté après chaque écriture : les écrans écoutent pour se rafraîchir.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Database? _db;
  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'cantine.db');
    return openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE produits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE,
        unite TEXT NOT NULL,
        seuil_alerte REAL NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE plats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL UNIQUE
      )''');
    await db.execute('''
      CREATE TABLE recettes (
        plat_id INTEGER NOT NULL,
        produit_id INTEGER NOT NULL,
        quantite_par_eleve REAL NOT NULL,
        PRIMARY KEY (plat_id, produit_id)
      )''');
    await db.execute('''
      CREATE TABLE menus (
        id TEXT PRIMARY KEY,
        date_menu TEXT NOT NULL UNIQUE,
        plat_id INTEGER NOT NULL,
        effectif_prevu INTEGER NOT NULL,
        effectif_servi INTEGER,
        statut TEXT NOT NULL DEFAULT 'PREVU',
        date_modif TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        supprime INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE mouvements_stock (
        id TEXT PRIMARY KEY,
        produit_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantite REAL NOT NULL,
        date_mouvement TEXT NOT NULL,
        menu_id TEXT,
        motif TEXT,
        numero INTEGER NOT NULL DEFAULT 0,
        auteur TEXT,
        date_modif TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        supprime INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute(
        'CREATE INDEX idx_mvt_produit ON mouvements_stock (produit_id, date_mouvement)');
    await db.execute('''
      CREATE TABLE parametres (
        cle TEXT PRIMARY KEY,
        valeur TEXT NOT NULL
      )''');
    await _creerTablesV2(db);
    await _seed(db);
  }

  /// Données de départ. ATTENTION : les quantités par élève sont des valeurs
  /// d'exemple à remplacer par les rations officielles.
  Future<void> _seed(Database db) async {
    final produits = <String, int>{};
    final liste = <List<Object>>[
      ['Riz', 'kg', 50.0],
      ['Haricot', 'kg', 30.0],
      ['Maïs', 'kg', 30.0],
      ['Huile', 'l', 10.0],
      ['Sel', 'kg', 5.0],
      ['Tomate / condiments', 'kg', 5.0],
    ];
    for (final p in liste) {
      produits[p[0] as String] = await db.insert('produits', {
        'nom': p[0],
        'unite': p[1],
        'seuil_alerte': p[2],
      });
    }

    final recettes = <String, Map<String, double>>{
      'Riz sauce tomate': {'Riz': 0.12, 'Huile': 0.01, 'Tomate / condiments': 0.02, 'Sel': 0.002},
      'Riz au haricot': {'Riz': 0.08, 'Haricot': 0.04, 'Huile': 0.01, 'Sel': 0.002},
      'Pâte de maïs et sauce': {'Maïs': 0.12, 'Huile': 0.01, 'Tomate / condiments': 0.02, 'Sel': 0.002},
    };
    for (final e in recettes.entries) {
      final platId = await db.insert('plats', {'nom': e.key});
      for (final l in e.value.entries) {
        await db.insert('recettes', {
          'plat_id': platId,
          'produit_id': produits[l.key],
          'quantite_par_eleve': l.value,
        });
      }
    }
    await db.insert('parametres', {'cle': 'effectif_cantine', 'valeur': '100'});
  }

  // ------------------------------------------------------------------
  // Utilitaires
  // ------------------------------------------------------------------
  void _notify() => changes.value++;
  String _now() => DateTime.now().toIso8601String();
  String _dateKey(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<double> _stockProduit(DatabaseExecutor db, int produitId) async {
    final r = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN type IN ('ENTREE','AJUSTEMENT_PLUS')
                               THEN quantite ELSE -quantite END), 0) AS s
      FROM mouvements_stock
      WHERE produit_id = ? AND supprime = 0''', [produitId]);
    return (r.first['s'] as num).toDouble();
  }

  Future<void> _insertMouvement(
    DatabaseExecutor db, {
    required int produitId,
    required String type,
    required double quantite,
    String? motif,
    String? menuId,
  }) async {
    final q = double.parse(quantite.toStringAsFixed(3));
    if (q <= 0) throw Exception('La quantité doit être supérieure à 0');

    final sortie = type == 'SORTIE' || type == 'PERTE' || type == 'AJUSTEMENT_MOINS';
    if (sortie) {
      final stock = await _stockProduit(db, produitId);
      if (q > stock + 0.0005) {
        final p = await db.query('produits',
            columns: ['nom', 'unite'], where: 'id = ?', whereArgs: [produitId]);
        throw Exception(
            'Stock insuffisant pour ${p.first['nom']} (disponible : ${fmtQte(stock)} ${p.first['unite']})');
      }
    }

    final now = _now();
    final dernier = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COALESCE(MAX(numero), 0) FROM mouvements_stock')) ??
        0;
    final auteur = await _param(db, 'utilisateur');
    await db.insert('mouvements_stock', {
      'numero': dernier + 1,
      'auteur': auteur,
      'id': _uuid.v4(),
      'produit_id': produitId,
      'type': type,
      'quantite': q,
      'date_mouvement': now,
      'menu_id': menuId,
      'motif': motif,
      'date_modif': now,
      'synced': 0,
      'supprime': 0,
    });
  }

  // ------------------------------------------------------------------
  // Stock
  // ------------------------------------------------------------------
  Future<List<ProduitStock>> produitsAvecStock() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT p.id, p.nom, p.unite, p.seuil_alerte,
             COALESCE(SUM(CASE
                 WHEN m.type IN ('ENTREE','AJUSTEMENT_PLUS') THEN m.quantite
                 WHEN m.type IS NOT NULL THEN -m.quantite
                 ELSE 0 END), 0) AS stock
      FROM produits p
      LEFT JOIN mouvements_stock m ON m.produit_id = p.id AND m.supprime = 0
      GROUP BY p.id
      ORDER BY p.nom''');
    return rows
        .map((r) => ProduitStock(
              id: r['id'] as int,
              nom: r['nom'] as String,
              unite: r['unite'] as String,
              seuil: (r['seuil_alerte'] as num).toDouble(),
              stock: (r['stock'] as num).toDouble(),
            ))
        .toList();
  }

  Future<void> ajouterMouvement({
    required int produitId,
    required String type,
    required double quantite,
    String? motif,
  }) async {
    final db = await _database;
    await db.transaction((txn) => _insertMouvement(txn,
        produitId: produitId, type: type, quantite: quantite, motif: motif));
    _notify();
  }

  Future<List<Mouvement>> historique({int limite = 100}) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT m.id, p.nom, p.unite, m.type, m.quantite, m.date_mouvement, m.motif
      FROM mouvements_stock m
      JOIN produits p ON p.id = m.produit_id
      WHERE m.supprime = 0
      ORDER BY m.date_mouvement DESC
      LIMIT ?''', [limite]);
    return rows
        .map((r) => Mouvement(
              id: r['id'] as String,
              produit: r['nom'] as String,
              unite: r['unite'] as String,
              type: r['type'] as String,
              quantite: (r['quantite'] as num).toDouble(),
              date: DateTime.parse(r['date_mouvement'] as String),
              motif: r['motif'] as String?,
            ))
        .toList();
  }

  // ------------------------------------------------------------------
  // Menus
  // ------------------------------------------------------------------
  Future<List<Plat>> plats() async {
    final db = await _database;
    final rows = await db.query('plats', orderBy: 'nom');
    return rows.map((r) => Plat(id: r['id'] as int, nom: r['nom'] as String)).toList();
  }

  Future<int> effectifParDefaut() async {
    final db = await _database;
    final r = await db.query('parametres', where: 'cle = ?', whereArgs: ['effectif_cantine']);
    if (r.isEmpty) return 100;
    return int.tryParse(r.first['valeur'] as String) ?? 100;
  }

  Future<List<MenuJour>> menus({int limite = 60}) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT m.id, m.date_menu, m.plat_id, m.effectif_prevu, m.effectif_servi,
             m.statut, pl.nom AS plat
      FROM menus m
      JOIN plats pl ON pl.id = m.plat_id
      WHERE m.supprime = 0
      ORDER BY m.date_menu DESC
      LIMIT ?''', [limite]);
    return rows
        .map((r) => MenuJour(
              id: r['id'] as String,
              date: DateTime.parse(r['date_menu'] as String),
              platId: r['plat_id'] as int,
              plat: r['plat'] as String,
              effectifPrevu: r['effectif_prevu'] as int,
              effectifServi: r['effectif_servi'] as int?,
              statut: r['statut'] as String,
            ))
        .toList();
  }

  /// Besoin en vivres pour un plat : effectif x quantité par élève, comparé au stock.
  Future<List<BesoinLigne>> besoin(int platId, int effectif) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT p.id, p.nom, p.unite, r.quantite_par_eleve AS q
      FROM recettes r
      JOIN produits p ON p.id = r.produit_id
      WHERE r.plat_id = ?
      ORDER BY p.nom''', [platId]);
    final res = <BesoinLigne>[];
    for (final r in rows) {
      final id = r['id'] as int;
      res.add(BesoinLigne(
        produitId: id,
        produit: r['nom'] as String,
        unite: r['unite'] as String,
        besoin: (r['q'] as num).toDouble() * effectif,
        stock: await _stockProduit(db, id),
      ));
    }
    return res;
  }

  Future<void> programmerMenu({
    required DateTime date,
    required int platId,
    required int effectif,
  }) async {
    if (effectif <= 0) throw Exception('L’effectif doit être supérieur à 0');
    final db = await _database;
    final cle = _dateKey(date);
    final existant = await db.query('menus', where: 'date_menu = ?', whereArgs: [cle]);
    if (existant.isNotEmpty) {
      if (existant.first['statut'] != 'PREVU') {
        throw Exception('Le menu de cette date est déjà clôturé');
      }
      await db.update(
        'menus',
        {
          'plat_id': platId,
          'effectif_prevu': effectif,
          'date_modif': _now(),
          'supprime': 0,
          'synced': 0,
        },
        where: 'id = ?',
        whereArgs: [existant.first['id']],
      );
    } else {
      await db.insert('menus', {
        'id': _uuid.v4(),
        'date_menu': cle,
        'plat_id': platId,
        'effectif_prevu': effectif,
        'statut': 'PREVU',
        'date_modif': _now(),
        'synced': 0,
        'supprime': 0,
      });
    }
    _notify();
  }

  /// Clôture un repas : crée automatiquement les SORTIES de stock
  /// (effectif servi x quantité par élève) dans une seule transaction.
  Future<void> servirMenu(String menuId, int effectifServi) async {
    if (effectifServi <= 0) throw Exception('Nombre d’élèves invalide');
    final db = await _database;
    await db.transaction((txn) async {
      final rows = await txn.query('menus', where: 'id = ?', whereArgs: [menuId]);
      if (rows.isEmpty) throw Exception('Menu introuvable');
      if (rows.first['statut'] != 'PREVU') throw Exception('Ce menu est déjà clôturé');

      final platId = rows.first['plat_id'] as int;
      final lignes = await txn.query('recettes', where: 'plat_id = ?', whereArgs: [platId]);
      for (final l in lignes) {
        await _insertMouvement(
          txn,
          produitId: l['produit_id'] as int,
          type: 'SORTIE',
          quantite: (l['quantite_par_eleve'] as num).toDouble() * effectifServi,
          menuId: menuId,
          motif: 'Repas servi',
        );
      }
      await txn.update(
        'menus',
        {
          'statut': 'SERVI',
          'effectif_servi': effectifServi,
          'date_modif': _now(),
          'synced': 0,
        },
        where: 'id = ?',
        whereArgs: [menuId],
      );
    });
    _notify();
  }

  // ------------------------------------------------------------------
  // v0.2 : migration, paramètres, registre, livraisons, inventaires, rapports
  // ------------------------------------------------------------------
  Future<void> _onUpgrade(Database db, int ancienne, int nouvelle) async {
    if (ancienne < 2) {
      await db.execute('ALTER TABLE mouvements_stock ADD COLUMN numero INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE mouvements_stock ADD COLUMN auteur TEXT');
      await db.execute('UPDATE mouvements_stock SET numero = rowid');
      await _creerTablesV2(db);
    }
  }

  Future<void> _creerTablesV2(Database db) async {
    await db.execute('''
      CREATE TABLE livraisons (
        id TEXT PRIMARY KEY,
        fournisseur TEXT NOT NULL,
        numero_bon TEXT,
        date_prevue TEXT,
        date_reception TEXT,
        statut TEXT NOT NULL DEFAULT 'ATTENDUE',
        date_modif TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        supprime INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE livraison_lignes (
        id TEXT PRIMARY KEY,
        livraison_id TEXT NOT NULL,
        produit_id INTEGER NOT NULL,
        quantite_prevue REAL NOT NULL,
        quantite_recue REAL NOT NULL DEFAULT 0,
        quantite_abimee REAL NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE inventaires (
        id TEXT PRIMARY KEY,
        date_inventaire TEXT NOT NULL,
        utilisateur TEXT,
        date_modif TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE inventaire_lignes (
        id TEXT PRIMARY KEY,
        inventaire_id TEXT NOT NULL,
        produit_id INTEGER NOT NULL,
        quantite_theorique REAL NOT NULL,
        quantite_reelle REAL NOT NULL
      )''');
  }

  Future<String?> _param(DatabaseExecutor db, String cle) async {
    final r = await db.query('parametres', where: 'cle = ?', whereArgs: [cle]);
    return r.isEmpty ? null : r.first['valeur'] as String;
  }

  Future<String?> param(String cle) async => _param(await _database, cle);

  Future<void> setParam(String cle, String valeur) async {
    final db = await _database;
    await db.insert('parametres', {'cle': cle, 'valeur': valeur},
        conflictAlgorithm: ConflictAlgorithm.replace);
    _notify();
  }

  Future<void> majSeuil(int produitId, double seuil) async {
    final db = await _database;
    await db.update('produits', {'seuil_alerte': seuil}, where: 'id = ?', whereArgs: [produitId]);
    _notify();
  }

  Future<String> cheminBase() async => join(await getDatabasesPath(), 'cantine.db');

  Future<int> operationsEnAttente() async {
    final db = await _database;
    var total = 0;
    for (final t in ['mouvements_stock', 'menus', 'livraisons', 'inventaires']) {
      total += Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $t WHERE synced = 0')) ??
          0;
    }
    return total;
  }

  Future<int> nombreOperations() async {
    final db = await _database;
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM mouvements_stock WHERE supprime = 0')) ??
        0;
  }

  // ---- Registre ----
  Future<List<Mouvement>> registre({
    DateTime? debut,
    DateTime? fin,
    int? produitId,
    int limite = 500,
  }) async {
    final db = await _database;
    final where = <String>['m.supprime = 0'];
    final args = <Object?>[];
    if (debut != null) {
      where.add('m.date_mouvement >= ?');
      args.add(debut.toIso8601String());
    }
    if (fin != null) {
      where.add('m.date_mouvement < ?');
      args.add(fin.toIso8601String());
    }
    if (produitId != null) {
      where.add('m.produit_id = ?');
      args.add(produitId);
    }
    args.add(limite);
    final rows = await db.rawQuery('''
      SELECT m.id, m.produit_id, p.nom, p.unite, m.type, m.quantite,
             m.date_mouvement, m.motif, m.numero, m.auteur
      FROM mouvements_stock m
      JOIN produits p ON p.id = m.produit_id
      WHERE ${where.join(' AND ')}
      ORDER BY m.numero DESC, m.date_mouvement DESC
      LIMIT ?''', args);
    return rows
        .map((r) => Mouvement(
              id: r['id'] as String,
              produit: r['nom'] as String,
              unite: r['unite'] as String,
              type: r['type'] as String,
              quantite: (r['quantite'] as num).toDouble(),
              date: DateTime.parse(r['date_mouvement'] as String),
              motif: r['motif'] as String?,
              numero: r['numero'] as int,
              auteur: r['auteur'] as String?,
              produitId: r['produit_id'] as int,
            ))
        .toList();
  }

  // ---- Livraisons ----
  Future<List<Livraison>> livraisons() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT l.id, l.fournisseur, l.numero_bon, l.date_prevue, l.date_reception, l.statut,
             (SELECT COUNT(*) FROM livraison_lignes x WHERE x.livraison_id = l.id) AS nb
      FROM livraisons l
      WHERE l.supprime = 0
      ORDER BY CASE l.statut WHEN 'ATTENDUE' THEN 0 ELSE 1 END, l.date_prevue DESC''');
    return rows
        .map((r) => Livraison(
              id: r['id'] as String,
              fournisseur: r['fournisseur'] as String,
              numeroBon: r['numero_bon'] as String?,
              datePrevue: r['date_prevue'] == null ? null : DateTime.parse(r['date_prevue'] as String),
              dateReception:
                  r['date_reception'] == null ? null : DateTime.parse(r['date_reception'] as String),
              statut: r['statut'] as String,
              nbLignes: r['nb'] as int,
            ))
        .toList();
  }

  Future<List<LivraisonLigne>> lignesLivraison(String livraisonId) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT x.id, x.produit_id, p.nom, p.unite,
             x.quantite_prevue, x.quantite_recue, x.quantite_abimee
      FROM livraison_lignes x
      JOIN produits p ON p.id = x.produit_id
      WHERE x.livraison_id = ?
      ORDER BY p.nom''', [livraisonId]);
    return rows
        .map((r) => LivraisonLigne(
              id: r['id'] as String,
              produitId: r['produit_id'] as int,
              produit: r['nom'] as String,
              unite: r['unite'] as String,
              prevue: (r['quantite_prevue'] as num).toDouble(),
              recue: (r['quantite_recue'] as num).toDouble(),
              abimee: (r['quantite_abimee'] as num).toDouble(),
            ))
        .toList();
  }

  Future<void> creerLivraison({
    required String fournisseur,
    String? numeroBon,
    required DateTime datePrevue,
    required Map<int, double> quantites,
  }) async {
    if (fournisseur.trim().isEmpty) throw Exception('Indiquez le fournisseur');
    if (quantites.isEmpty) throw Exception('Ajoutez au moins un produit');
    final db = await _database;
    final id = _uuid.v4();
    await db.transaction((txn) async {
      await txn.insert('livraisons', {
        'id': id,
        'fournisseur': fournisseur.trim(),
        'numero_bon': (numeroBon == null || numeroBon.trim().isEmpty) ? null : numeroBon.trim(),
        'date_prevue': _dateKey(datePrevue),
        'statut': 'ATTENDUE',
        'date_modif': _now(),
        'synced': 0,
        'supprime': 0,
      });
      for (final e in quantites.entries) {
        await txn.insert('livraison_lignes', {
          'id': _uuid.v4(),
          'livraison_id': id,
          'produit_id': e.key,
          'quantite_prevue': e.value,
        });
      }
    });
    _notify();
  }

  /// Réception : une ENTREE par produit reçu, puis une PERTE pour la partie abîmée
  /// (tout reste visible dans le registre).
  Future<void> receptionnerLivraison(String livraisonId, List<LigneReception> lignes) async {
    final db = await _database;
    await db.transaction((txn) async {
      final liv = await txn.query('livraisons', where: 'id = ?', whereArgs: [livraisonId]);
      if (liv.isEmpty) throw Exception('Livraison introuvable');
      if (liv.first['statut'] != 'ATTENDUE') throw Exception('Cette livraison est déjà réceptionnée');
      final bon = liv.first['numero_bon'] as String?;
      final ref = (bon == null || bon.isEmpty) ? 'Livraison' : 'Bordereau $bon';
      var partielle = false;
      for (final l in lignes) {
        if (l.recue < 0 || l.abimee < 0) throw Exception('Quantités invalides');
        if (l.abimee > l.recue) throw Exception('La quantité abîmée dépasse la quantité reçue');
        await txn.update(
          'livraison_lignes',
          {'quantite_recue': l.recue, 'quantite_abimee': l.abimee},
          where: 'id = ?',
          whereArgs: [l.ligneId],
        );
        if (l.recue > 0) {
          await _insertMouvement(txn,
              produitId: l.produitId, type: 'ENTREE', quantite: l.recue, motif: ref);
        }
        if (l.abimee > 0) {
          await _insertMouvement(txn,
              produitId: l.produitId,
              type: 'PERTE',
              quantite: l.abimee,
              motif: 'Abîmé à la réception ($ref)');
        }
        if (l.recue + 0.0005 < l.prevue) partielle = true;
      }
      await txn.update(
        'livraisons',
        {
          'statut': partielle ? 'PARTIELLE' : 'RECUE',
          'date_reception': _dateKey(DateTime.now()),
          'date_modif': _now(),
          'synced': 0,
        },
        where: 'id = ?',
        whereArgs: [livraisonId],
      );
    });
    _notify();
  }

  // ---- Inventaires ----
  Future<List<InventaireResume>> inventaires() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT i.id, i.date_inventaire,
        (SELECT COUNT(*) FROM inventaire_lignes l
          WHERE l.inventaire_id = i.id
            AND ABS(l.quantite_reelle - l.quantite_theorique) > 0.0005) AS ecarts
      FROM inventaires i
      ORDER BY i.date_inventaire DESC, i.date_modif DESC''');
    return rows
        .map((r) => InventaireResume(
              id: r['id'] as String,
              date: DateTime.parse(r['date_inventaire'] as String),
              ecarts: r['ecarts'] as int,
            ))
        .toList();
  }

  Future<List<LigneInventaireDetail>> lignesInventaire(String inventaireId) async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT p.nom, p.unite, l.quantite_theorique, l.quantite_reelle
      FROM inventaire_lignes l
      JOIN produits p ON p.id = l.produit_id
      WHERE l.inventaire_id = ?
      ORDER BY p.nom''', [inventaireId]);
    return rows
        .map((r) => LigneInventaireDetail(
              produit: r['nom'] as String,
              unite: r['unite'] as String,
              theorique: (r['quantite_theorique'] as num).toDouble(),
              reel: (r['quantite_reelle'] as num).toDouble(),
            ))
        .toList();
  }

  /// Enregistre l'inventaire et crée un ajustement tracé pour chaque écart.
  Future<void> enregistrerInventaire(List<LigneInventaire> lignes) async {
    final db = await _database;
    final id = _uuid.v4();
    final aujourdhui = DateTime.now();
    final libelle = fmtDate(aujourdhui);
    await db.transaction((txn) async {
      await txn.insert('inventaires', {
        'id': id,
        'date_inventaire': _dateKey(aujourdhui),
        'utilisateur': await _param(txn, 'utilisateur'),
        'date_modif': _now(),
        'synced': 0,
      });
      for (final l in lignes) {
        await txn.insert('inventaire_lignes', {
          'id': _uuid.v4(),
          'inventaire_id': id,
          'produit_id': l.produitId,
          'quantite_theorique': l.theorique,
          'quantite_reelle': l.reel,
        });
        final ecart = double.parse((l.reel - l.theorique).toStringAsFixed(3));
        if (ecart.abs() > 0.0005) {
          await _insertMouvement(txn,
              produitId: l.produitId,
              type: ecart > 0 ? 'AJUSTEMENT_PLUS' : 'AJUSTEMENT_MOINS',
              quantite: ecart.abs(),
              motif: 'Inventaire du $libelle');
        }
      }
    });
    _notify();
  }

  // ---- Rapports ----
  Future<Rapport> rapport(DateTime debut, DateTime fin) async {
    final db = await _database;
    final r = await db.rawQuery('''
      SELECT COUNT(*) AS n, COALESCE(SUM(effectif_servi), 0) AS e
      FROM menus
      WHERE supprime = 0 AND statut = 'SERVI' AND date_menu >= ? AND date_menu < ?''',
        [_dateKey(debut), _dateKey(fin)]);
    final m = await db.rawQuery('''
      SELECT p.nom, p.unite,
        COALESCE(SUM(CASE WHEN m.type IN ('ENTREE','AJUSTEMENT_PLUS') THEN m.quantite ELSE 0 END), 0) AS entrees,
        COALESCE(SUM(CASE WHEN m.type = 'SORTIE' THEN m.quantite ELSE 0 END), 0) AS sorties,
        COALESCE(SUM(CASE WHEN m.type IN ('PERTE','AJUSTEMENT_MOINS') THEN m.quantite ELSE 0 END), 0) AS pertes
      FROM produits p
      LEFT JOIN mouvements_stock m ON m.produit_id = p.id AND m.supprime = 0
        AND m.date_mouvement >= ? AND m.date_mouvement < ?
      GROUP BY p.id
      ORDER BY p.nom''', [debut.toIso8601String(), fin.toIso8601String()]);
    final stocks = {for (final p in await produitsAvecStock()) p.nom: p.stock};
    return Rapport(
      debut: debut,
      fin: fin,
      repas: r.first['n'] as int,
      eleves: (r.first['e'] as num).toInt(),
      lignes: m
          .map((x) => LigneRapport(
                nom: x['nom'] as String,
                unite: x['unite'] as String,
                entrees: (x['entrees'] as num).toDouble(),
                sorties: (x['sorties'] as num).toDouble(),
                pertes: (x['pertes'] as num).toDouble(),
                stock: stocks[x['nom'] as String] ?? 0,
              ))
          .toList(),
    );
  }
}
