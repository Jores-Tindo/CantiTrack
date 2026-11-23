package com.cantitrack.api.service;

import com.cantitrack.api.domain.*;
import com.cantitrack.api.dto.Dto;
import com.cantitrack.api.repo.*;
import com.cantitrack.api.security.AuthUser;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Synchronisation des écoles.
 * - push : le mobile envoie ses données ; l'opération est idempotente (identifiants UUID).
 * - pull : le mobile récupère tout (nouveau téléphone) ou seulement les changements.
 * Les lignes du registre (mouvements) ne sont JAMAIS modifiées ni supprimées une fois reçues.
 */
@Service
public class SyncService {
    private static final Set<String> TYPES =
            Set.of("ENTREE", "SORTIE", "PERTE", "AJUSTEMENT_PLUS", "AJUSTEMENT_MOINS");
    private static final Set<String> STATUTS_MENU = Set.of("PREVU", "SERVI", "ANNULE");
    private static final Set<String> STATUTS_LIVRAISON = Set.of("ATTENDUE", "RECUE", "PARTIELLE", "REFUSEE");

    private final MenuRepository menus;
    private final LivraisonRepository livraisons;
    private final LivraisonLigneRepository lignesLiv;
    private final MouvementStockRepository mouvements;
    private final InventaireRepository inventaires;
    private final InventaireLigneRepository lignesInv;
    private final ProduitRepository produits;
    private final PlatRepository plats;
    private final RecetteRepository recettes;
    private final SyncLogRepository logs;

    public SyncService(MenuRepository menus, LivraisonRepository livraisons, LivraisonLigneRepository lignesLiv,
                       MouvementStockRepository mouvements, InventaireRepository inventaires,
                       InventaireLigneRepository lignesInv, ProduitRepository produits, PlatRepository plats,
                       RecetteRepository recettes, SyncLogRepository logs) {
        this.menus = menus;
        this.livraisons = livraisons;
        this.lignesLiv = lignesLiv;
        this.mouvements = mouvements;
        this.inventaires = inventaires;
        this.lignesInv = lignesInv;
        this.produits = produits;
        this.plats = plats;
        this.recettes = recettes;
        this.logs = logs;
    }

    // ------------------------------------------------------------------ utilitaires
    private static <T> List<T> nz(List<T> l) { return l == null ? List.of() : l; }
    private static boolean vide(String s) { return s == null || s.isBlank(); }
    private static IllegalArgumentException bad(String m) { return new IllegalArgumentException(m); }
    private static LocalDateTime dt(String s) { return vide(s) ? LocalDateTime.now() : LocalDateTime.parse(s); }
    private static String str(Object o) { return o == null ? null : o.toString(); }
    private static BigDecimal q3(BigDecimal v) { return v.setScale(3, RoundingMode.HALF_UP); }

    private static String choix(String v, String defaut, Set<String> permis) {
        String x = vide(v) ? defaut : v;
        if (!permis.contains(x)) throw bad("valeur « " + x + " » non autorisée");
        return x;
    }

    private static Integer ecoleDe(AuthUser u) {
        if (u.ecoleId() == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Ce compte n’est rattaché à aucune école");
        }
        return u.ecoleId();
    }

    // ------------------------------------------------------------------ PUSH
    @Transactional
    public Dto.PushResult push(AuthUser u, Dto.PushRequest r) {
        Integer ecoleId = ecoleDe(u);
        List<String> rejets = new ArrayList<>();
        int recus = 0;
        int deja = 0;

        for (Dto.MenuDto d : nz(r.menus())) {
            try {
                if (vide(d.id()) || d.dateMenu() == null || d.platId() == null || d.effectifPrevu() == null) {
                    throw bad("menu incomplet");
                }
                LocalDate jour = LocalDate.parse(d.dateMenu());
                LocalDateTime modif = dt(d.dateModif());
                Menu m = menus.findById(d.id()).orElse(null);
                if (m != null) {
                    if (!m.ecoleId.equals(ecoleId)) throw bad("menu d’une autre école");
                    if (modif.isBefore(m.dateModif)) { deja++; continue; }
                } else {
                    if (menus.findByEcoleIdAndDateMenu(ecoleId, jour).isPresent()) {
                        throw bad("un menu existe déjà à cette date");
                    }
                    m = new Menu();
                    m.id = d.id();
                    m.ecoleId = ecoleId;
                }
                m.dateMenu = jour;
                m.platId = d.platId();
                m.effectifPrevu = d.effectifPrevu();
                m.effectifServi = d.effectifServi();
                m.statut = choix(d.statut(), "PREVU", STATUTS_MENU);
                m.dateModif = modif;
                m.supprime = d.supprime() != null && d.supprime() == 1;
                menus.save(m);
                recus++;
            } catch (IllegalArgumentException | DateTimeException e) {
                rejets.add("menu " + d.id() + " : " + e.getMessage());
            }
        }

        for (Dto.LivraisonDto d : nz(r.livraisons())) {
            try {
                if (vide(d.id()) || vide(d.fournisseur())) throw bad("livraison incomplète");
                LocalDateTime modif = dt(d.dateModif());
                Livraison l = livraisons.findById(d.id()).orElse(null);
                if (l != null) {
                    if (!l.ecoleId.equals(ecoleId)) throw bad("livraison d’une autre école");
                    if (modif.isBefore(l.dateModif)) { deja++; continue; }
                } else {
                    l = new Livraison();
                    l.id = d.id();
                    l.ecoleId = ecoleId;
                }
                l.fournisseur = d.fournisseur();
                l.numeroBon = d.numeroBon();
                l.datePrevue = vide(d.datePrevue()) ? null : LocalDate.parse(d.datePrevue());
                l.dateReception = vide(d.dateReception()) ? null : LocalDate.parse(d.dateReception());
                l.statut = choix(d.statut(), "ATTENDUE", STATUTS_LIVRAISON);
                l.dateModif = modif;
                l.supprime = d.supprime() != null && d.supprime() == 1;
                livraisons.save(l);
                recus++;
            } catch (IllegalArgumentException | DateTimeException e) {
                rejets.add("livraison " + d.id() + " : " + e.getMessage());
            }
        }

        for (Dto.LivraisonLigneDto d : nz(r.livraisonLignes())) {
            try {
                if (vide(d.id()) || vide(d.livraisonId()) || d.produitId() == null) throw bad("ligne incomplète");
                Livraison parent = livraisons.findById(d.livraisonId())
                        .orElseThrow(() -> bad("livraison inconnue"));
                if (!parent.ecoleId.equals(ecoleId)) throw bad("livraison d’une autre école");
                if (!produits.existsById(d.produitId())) throw bad("produit inconnu");
                LivraisonLigne l = lignesLiv.findById(d.id()).orElse(null);
                if (l != null && !l.livraisonId.equals(d.livraisonId())) throw bad("ligne rattachée à une autre livraison");
                if (l == null) {
                    l = new LivraisonLigne();
                    l.id = d.id();
                    l.livraisonId = d.livraisonId();
                }
                l.produitId = d.produitId();
                l.quantitePrevue = q3(d.quantitePrevue() == null ? BigDecimal.ZERO : d.quantitePrevue());
                l.quantiteRecue = q3(d.quantiteRecue() == null ? BigDecimal.ZERO : d.quantiteRecue());
                l.quantiteAbimee = q3(d.quantiteAbimee() == null ? BigDecimal.ZERO : d.quantiteAbimee());
                lignesLiv.save(l);
                recus++;
            } catch (IllegalArgumentException e) {
                rejets.add("ligne de livraison " + d.id() + " : " + e.getMessage());
            }
        }

        // Registre : insertion seule. Une ligne déjà reçue n'est jamais modifiée.
        for (Dto.MouvementDto d : nz(r.mouvements())) {
            try {
                if (vide(d.id())) throw bad("identifiant manquant");
                if (mouvements.existsById(d.id())) { deja++; continue; }
                if (d.produitId() == null || !produits.existsById(d.produitId())) throw bad("produit inconnu");
                if (d.type() == null || !TYPES.contains(d.type())) throw bad("type invalide");
                if (d.quantite() == null || d.quantite().signum() <= 0) throw bad("quantité invalide");
                MouvementStock m = new MouvementStock();
                m.id = d.id();
                m.ecoleId = ecoleId;
                m.produitId = d.produitId();
                m.type = d.type();
                m.quantite = q3(d.quantite());
                m.dateMouvement = dt(d.dateMouvement());
                m.menuId = d.menuId();
                m.motif = d.motif();
                m.numero = d.numero() == null ? 0 : d.numero();
                m.auteur = d.auteur();
                m.dateModif = dt(d.dateModif());
                m.supprime = false;
                mouvements.save(m);
                recus++;
            } catch (IllegalArgumentException | DateTimeException e) {
                rejets.add("mouvement " + d.id() + " : " + e.getMessage());
            }
        }

        for (Dto.InventaireDto d : nz(r.inventaires())) {
            try {
                if (vide(d.id()) || vide(d.dateInventaire())) throw bad("inventaire incomplet");
                if (inventaires.existsById(d.id())) { deja++; continue; }
                Inventaire i = new Inventaire();
                i.id = d.id();
                i.ecoleId = ecoleId;
                i.dateInventaire = LocalDate.parse(d.dateInventaire());
                i.utilisateur = d.utilisateur();
                i.dateModif = dt(d.dateModif());
                inventaires.save(i);
                recus++;
            } catch (IllegalArgumentException | DateTimeException e) {
                rejets.add("inventaire " + d.id() + " : " + e.getMessage());
            }
        }

        for (Dto.InventaireLigneDto d : nz(r.inventaireLignes())) {
            try {
                if (vide(d.id()) || vide(d.inventaireId()) || d.produitId() == null
                        || d.quantiteTheorique() == null || d.quantiteReelle() == null) {
                    throw bad("ligne incomplète");
                }
                if (lignesInv.existsById(d.id())) { deja++; continue; }
                Inventaire parent = inventaires.findById(d.inventaireId())
                        .orElseThrow(() -> bad("inventaire inconnu"));
                if (!parent.ecoleId.equals(ecoleId)) throw bad("inventaire d’une autre école");
                if (!produits.existsById(d.produitId())) throw bad("produit inconnu");
                InventaireLigne l = new InventaireLigne();
                l.id = d.id();
                l.inventaireId = d.inventaireId();
                l.produitId = d.produitId();
                l.quantiteTheorique = q3(d.quantiteTheorique());
                l.quantiteReelle = q3(d.quantiteReelle());
                lignesInv.save(l);
                recus++;
            } catch (IllegalArgumentException e) {
                rejets.add("ligne d’inventaire " + d.id() + " : " + e.getMessage());
            }
        }

        SyncLog log = new SyncLog();
        log.ecoleId = ecoleId;
        log.dateSync = LocalDateTime.now();
        log.nbEnregistrements = recus;
        log.statut = (recus == 0 && deja == 0 && !rejets.isEmpty()) ? "ERREUR" : "OK";
        log.message = rejets.isEmpty() ? null : rejets.size() + " rejet(s)";
        logs.save(log);

        return new Dto.PushResult(recus, deja, rejets, LocalDateTime.now().toString());
    }

    // ------------------------------------------------------------------ PULL
    @Transactional(readOnly = true)
    public Dto.PullResponse pull(AuthUser u, String depuis) {
        Integer ecoleId = ecoleDe(u);
        LocalDateTime t = vide(depuis) ? LocalDateTime.of(1970, 1, 1, 0, 0) : dt(depuis);

        List<Livraison> livs = livraisons.findByEcoleIdAndDateModifAfter(ecoleId, t);
        List<String> livIds = livs.stream().map(l -> l.id).collect(Collectors.toList());
        List<Inventaire> invs = inventaires.findByEcoleIdAndDateModifAfter(ecoleId, t);
        List<String> invIds = invs.stream().map(i -> i.id).collect(Collectors.toList());

        List<Dto.ProduitDto> prods = produits.findAll().stream()
                .map(p -> new Dto.ProduitDto(p.id, p.nom, p.unite, p.seuilAlerte)).collect(Collectors.toList());
        List<Dto.PlatDto> pls = plats.findAll().stream()
                .map(p -> new Dto.PlatDto(p.id, p.nom, recettes.findByPlatId(p.id).stream()
                        .map(x -> new Dto.RecetteDto(x.produitId, x.quantiteParEleve)).collect(Collectors.toList())))
                .collect(Collectors.toList());

        return new Dto.PullResponse(
                prods,
                pls,
                menus.findByEcoleIdAndDateModifAfter(ecoleId, t).stream()
                        .map(m -> new Dto.MenuDto(m.id, str(m.dateMenu), m.platId, m.effectifPrevu, m.effectifServi,
                                m.statut, str(m.dateModif), m.supprime ? 1 : 0))
                        .collect(Collectors.toList()),
                livs.stream()
                        .map(l -> new Dto.LivraisonDto(l.id, l.fournisseur, l.numeroBon, str(l.datePrevue),
                                str(l.dateReception), l.statut, str(l.dateModif), l.supprime ? 1 : 0))
                        .collect(Collectors.toList()),
                livIds.isEmpty() ? List.of() : lignesLiv.findByLivraisonIdIn(livIds).stream()
                        .map(l -> new Dto.LivraisonLigneDto(l.id, l.livraisonId, l.produitId, l.quantitePrevue,
                                l.quantiteRecue, l.quantiteAbimee))
                        .collect(Collectors.toList()),
                mouvements.findByEcoleIdAndDateModifAfter(ecoleId, t).stream()
                        .map(m -> new Dto.MouvementDto(m.id, m.produitId, m.type, m.quantite, str(m.dateMouvement),
                                m.menuId, m.motif, m.numero, m.auteur, str(m.dateModif), 0))
                        .collect(Collectors.toList()),
                invs.stream()
                        .map(i -> new Dto.InventaireDto(i.id, str(i.dateInventaire), i.utilisateur, str(i.dateModif)))
                        .collect(Collectors.toList()),
                invIds.isEmpty() ? List.of() : lignesInv.findByInventaireIdIn(invIds).stream()
                        .map(l -> new Dto.InventaireLigneDto(l.id, l.inventaireId, l.produitId,
                                l.quantiteTheorique, l.quantiteReelle))
                        .collect(Collectors.toList()),
                LocalDateTime.now().toString());
    }
}
