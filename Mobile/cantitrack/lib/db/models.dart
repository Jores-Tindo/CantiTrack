class ProduitStock {
  final int id;
  final String nom;
  final String unite;
  final double seuil;
  final double stock;

  const ProduitStock({
    required this.id,
    required this.nom,
    required this.unite,
    required this.seuil,
    required this.stock,
  });

  bool get enAlerte => stock <= seuil;
}

class Plat {
  final int id;
  final String nom;
  const Plat({required this.id, required this.nom});
}

class MenuJour {
  final String id;
  final DateTime date;
  final int platId;
  final String plat;
  final int effectifPrevu;
  final int? effectifServi;
  final String statut; // PREVU, SERVI, ANNULE

  const MenuJour({
    required this.id,
    required this.date,
    required this.platId,
    required this.plat,
    required this.effectifPrevu,
    required this.effectifServi,
    required this.statut,
  });
}

class BesoinLigne {
  final int produitId;
  final String produit;
  final String unite;
  final double besoin;
  final double stock;

  const BesoinLigne({
    required this.produitId,
    required this.produit,
    required this.unite,
    required this.besoin,
    required this.stock,
  });

  bool get suffisant => stock + 0.0005 >= besoin;
}

class Mouvement {
  final String id;
  final String produit;
  final String unite;
  final String type;
  final double quantite;
  final DateTime date;
  final String? motif;
  final int numero;
  final String? auteur;
  final int produitId;

  const Mouvement({
    required this.id,
    required this.produit,
    required this.unite,
    required this.type,
    required this.quantite,
    required this.date,
    required this.motif,
    this.numero = 0,
    this.auteur,
    this.produitId = 0,
  });

  bool get estEntree => type == 'ENTREE' || type == 'AJUSTEMENT_PLUS';
}

const Map<String, String> libelleType = {
  'ENTREE': 'Entrée',
  'SORTIE': 'Sortie',
  'PERTE': 'Perte',
  'AJUSTEMENT_PLUS': 'Ajustement +',
  'AJUSTEMENT_MOINS': 'Ajustement −',
};

/// 12.500 -> "12.5", 10.000 -> "10"
String fmtQte(double v) {
  final s = v.toStringAsFixed(3);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String fmtDateHeure(DateTime d) =>
    '${fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class Livraison {
  final String id;
  final String fournisseur;
  final String? numeroBon;
  final DateTime? datePrevue;
  final DateTime? dateReception;
  final String statut; // ATTENDUE, RECUE, PARTIELLE
  final int nbLignes;

  const Livraison({
    required this.id,
    required this.fournisseur,
    required this.numeroBon,
    required this.datePrevue,
    required this.dateReception,
    required this.statut,
    required this.nbLignes,
  });
}

class LivraisonLigne {
  final String id;
  final int produitId;
  final String produit;
  final String unite;
  final double prevue;
  final double recue;
  final double abimee;

  const LivraisonLigne({
    required this.id,
    required this.produitId,
    required this.produit,
    required this.unite,
    required this.prevue,
    required this.recue,
    required this.abimee,
  });
}

class LigneReception {
  final String ligneId;
  final int produitId;
  final double prevue;
  final double recue;
  final double abimee;

  const LigneReception({
    required this.ligneId,
    required this.produitId,
    required this.prevue,
    required this.recue,
    required this.abimee,
  });
}

class LigneInventaire {
  final int produitId;
  final double theorique;
  final double reel;
  const LigneInventaire({required this.produitId, required this.theorique, required this.reel});
}

class InventaireResume {
  final String id;
  final DateTime date;
  final int ecarts;
  const InventaireResume({required this.id, required this.date, required this.ecarts});
}

class LigneInventaireDetail {
  final String produit;
  final String unite;
  final double theorique;
  final double reel;
  const LigneInventaireDetail({
    required this.produit,
    required this.unite,
    required this.theorique,
    required this.reel,
  });
}

class LigneRapport {
  final String nom;
  final String unite;
  final double entrees;
  final double sorties;
  final double pertes;
  final double stock;

  const LigneRapport({
    required this.nom,
    required this.unite,
    required this.entrees,
    required this.sorties,
    required this.pertes,
    required this.stock,
  });
}

class Rapport {
  final DateTime debut;
  final DateTime fin; // exclue
  final int repas;
  final int eleves;
  final List<LigneRapport> lignes;

  const Rapport({
    required this.debut,
    required this.fin,
    required this.repas,
    required this.eleves,
    required this.lignes,
  });
}
