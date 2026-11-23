package com.cantitrack.api.web;

import com.cantitrack.api.domain.*;
import com.cantitrack.api.dto.Dto;
import com.cantitrack.api.repo.*;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

/** Gestion des référentiels par l'administrateur national. */
@RestController
@RequestMapping("/api/admin")
public class AdminController {
    private final DepartementRepository departements;
    private final CommuneRepository communes;
    private final EcoleRepository ecoles;
    private final UtilisateurRepository users;
    private final ProduitRepository produits;
    private final PasswordEncoder encoder;

    public AdminController(DepartementRepository departements, CommuneRepository communes, EcoleRepository ecoles,
                           UtilisateurRepository users, ProduitRepository produits, PasswordEncoder encoder) {
        this.departements = departements;
        this.communes = communes;
        this.ecoles = ecoles;
        this.users = users;
        this.produits = produits;
        this.encoder = encoder;
    }

    private static ResponseStatusException erreur(String m) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, m);
    }

    @GetMapping("/departements")
    public List<Departement> departements() { return departements.findAll(); }

    @GetMapping("/communes")
    public List<Commune> communes() { return communes.findAll(); }

    @PostMapping("/communes")
    public Commune creerCommune(@Valid @RequestBody Dto.CommuneRequest r) {
        if (!departements.existsById(r.departementId())) throw erreur("Département inconnu");
        Commune c = new Commune();
        c.nom = r.nom().trim();
        c.departementId = r.departementId();
        return communes.save(c);
    }

    @GetMapping("/ecoles")
    public List<Ecole> ecoles() { return ecoles.findAll(); }

    @PostMapping("/ecoles")
    public Ecole creerEcole(@Valid @RequestBody Dto.EcoleRequest r) {
        if (!communes.existsById(r.communeId())) throw erreur("Commune inconnue");
        Ecole e = new Ecole();
        e.code = r.code().trim();
        e.nom = r.nom().trim();
        e.communeId = r.communeId();
        e.effectifTotal = r.effectifTotal();
        e.effectifCantine = r.effectifCantine();
        return ecoles.save(e);
    }

    @GetMapping("/utilisateurs")
    public List<Dto.UtilisateurView> utilisateurs() {
        return users.findAll().stream()
                .map(u -> new Dto.UtilisateurView(u.id, u.nomComplet, u.login, u.role, u.ecoleId, u.departementId, u.actif))
                .toList();
    }

    @PostMapping("/utilisateurs")
    public Dto.UtilisateurView creerUtilisateur(@Valid @RequestBody Dto.UtilisateurRequest r) {
        if (users.existsByLogin(r.login().trim())) throw erreur("Cet identifiant existe déjà");
        boolean ecoleRequise = r.role() == Role.DIRECTEUR_ECOLE || r.role() == Role.GESTIONNAIRE;
        if (ecoleRequise && (r.ecoleId() == null || !ecoles.existsById(r.ecoleId()))) {
            throw erreur("Une école valide est obligatoire pour ce rôle");
        }
        if (r.role() == Role.DIRECTION_DEPARTEMENTALE
                && (r.departementId() == null || !departements.existsById(r.departementId()))) {
            throw erreur("Un département valide est obligatoire pour ce rôle");
        }
        Utilisateur u = new Utilisateur();
        u.nomComplet = r.nomComplet().trim();
        u.login = r.login().trim();
        u.motDePasseHash = encoder.encode(r.motDePasse());
        u.role = r.role();
        u.ecoleId = ecoleRequise ? r.ecoleId() : null;
        u.departementId = r.role() == Role.DIRECTION_DEPARTEMENTALE ? r.departementId() : null;
        u.telephone = r.telephone();
        users.save(u);
        return new Dto.UtilisateurView(u.id, u.nomComplet, u.login, u.role, u.ecoleId, u.departementId, u.actif);
    }

    @GetMapping("/produits")
    public List<Produit> produits() { return produits.findAll(); }

    @PutMapping("/produits/{id}")
    public Produit majSeuil(@PathVariable int id, @Valid @RequestBody Dto.SeuilRequest r) {
        Produit p = produits.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Produit introuvable"));
        p.seuilAlerte = r.seuilAlerte();
        return produits.save(p);
    }
}
