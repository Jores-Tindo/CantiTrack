package com.cantitrack.api.config;

import com.cantitrack.api.domain.*;
import com.cantitrack.api.repo.*;
import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Données de départ. Les identifiants des produits et des plats suivent le même ordre que la base
 * locale du mobile (Riz=1, Haricot=2, Maïs=3, Huile=4, Sel=5, Tomate=6). Ne pas réordonner.
 * ATTENTION : les quantités par élève sont des valeurs d'exemple à remplacer par les rations officielles.
 */
@Component
public class DataInitializer implements CommandLineRunner {
    private final DepartementRepository departements;
    private final CommuneRepository communes;
    private final EcoleRepository ecoles;
    private final ProduitRepository produits;
    private final PlatRepository plats;
    private final RecetteRepository recettes;
    private final UtilisateurRepository users;
    private final PasswordEncoder encoder;

    @Value("${cantitrack.admin-login:admin}") private String adminLogin;
    @Value("${cantitrack.admin-password}") private String adminPassword;
    @Value("${cantitrack.seed-demo:false}") private boolean demo;
    @Value("${cantitrack.demo-password:}") private String demoPassword;

    public DataInitializer(DepartementRepository departements, CommuneRepository communes, EcoleRepository ecoles,
                           ProduitRepository produits, PlatRepository plats, RecetteRepository recettes,
                           UtilisateurRepository users, PasswordEncoder encoder) {
        this.departements = departements;
        this.communes = communes;
        this.ecoles = ecoles;
        this.produits = produits;
        this.plats = plats;
        this.recettes = recettes;
        this.users = users;
        this.encoder = encoder;
    }

    @Override
    public void run(String... args) {
        if (departements.count() == 0) {
            for (String nom : List.of("Alibori", "Atacora", "Atlantique", "Borgou", "Collines", "Couffo",
                    "Donga", "Littoral", "Mono", "Ouémé", "Plateau", "Zou")) {
                Departement d = new Departement();
                d.nom = nom;
                departements.save(d);
            }
        }
        if (produits.count() == 0) {
            Object[][] liste = {
                    {"Riz", "kg", 50}, {"Haricot", "kg", 30}, {"Maïs", "kg", 30},
                    {"Huile", "l", 10}, {"Sel", "kg", 5}, {"Tomate / condiments", "kg", 5}};
            Map<String, Integer> ids = new LinkedHashMap<>();
            for (Object[] p : liste) {
                Produit x = new Produit();
                x.nom = (String) p[0];
                x.unite = (String) p[1];
                x.seuilAlerte = BigDecimal.valueOf(((Number) p[2]).doubleValue());
                ids.put(x.nom, produits.save(x).id);
            }
            creerPlat("Riz sauce tomate", ids, Map.of("Riz", "0.12", "Huile", "0.01", "Tomate / condiments", "0.02", "Sel", "0.002"));
            creerPlat("Riz au haricot", ids, Map.of("Riz", "0.08", "Haricot", "0.04", "Huile", "0.01", "Sel", "0.002"));
            creerPlat("Pâte de maïs et sauce", ids, Map.of("Maïs", "0.12", "Huile", "0.01", "Tomate / condiments", "0.02", "Sel", "0.002"));
        }
        if (!users.existsByLogin(adminLogin)) {
            creerUtilisateur("Administrateur national", adminLogin, adminPassword, Role.ADMIN_NATIONAL, null, null);
        }
        if (demo && !demoPassword.isBlank() && !users.existsByLogin("gestionnaire.demo")) {
            Departement dep = departements.findAll().get(0);
            Commune c = new Commune();
            c.nom = "Commune démo";
            c.departementId = dep.id;
            c = communes.save(c);
            Ecole e = new Ecole();
            e.code = "DEMO-001";
            e.nom = "EPP Démo";
            e.communeId = c.id;
            e.effectifTotal = 150;
            e.effectifCantine = 120;
            e = ecoles.save(e);
            creerUtilisateur("Gestionnaire démo", "gestionnaire.demo", demoPassword, Role.GESTIONNAIRE, e.id, null);
            creerUtilisateur("Direction démo", "direction.demo", demoPassword, Role.DIRECTION_DEPARTEMENTALE, null, dep.id);
        }
    }

    private void creerPlat(String nom, Map<String, Integer> ids, Map<String, String> quantites) {
        Plat p = new Plat();
        p.nom = nom;
        p = plats.save(p);
        for (Map.Entry<String, String> q : quantites.entrySet()) {
            Recette r = new Recette();
            r.platId = p.id;
            r.produitId = ids.get(q.getKey());
            r.quantiteParEleve = new BigDecimal(q.getValue());
            recettes.save(r);
        }
    }

    private void creerUtilisateur(String nom, String login, String mdp, Role role, Integer ecoleId, Integer depId) {
        Utilisateur u = new Utilisateur();
        u.nomComplet = nom;
        u.login = login;
        u.motDePasseHash = encoder.encode(mdp);
        u.role = role;
        u.ecoleId = ecoleId;
        u.departementId = depId;
        users.save(u);
    }
}
