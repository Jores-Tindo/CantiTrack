package com.cantitrack.api.service;

import com.cantitrack.api.domain.Role;
import com.cantitrack.api.security.AuthUser;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/** Données consolidées pour le tableau de bord de la direction (lecture seule, SQL). */
@Service
public class DirectionService {
    private static final int JOURS_SANS_SYNC = 3;

    private static final String BASE_ECOLES = """
            SELECT e.id, e.code, e.nom, c.nom AS commune, d.nom AS departement, e.effectif_cantine,
                   (SELECT MAX(l.date_sync) FROM sync_log l WHERE l.ecole_id = e.id AND l.statut = 'OK') AS derniere_sync
            FROM ecoles e
            JOIN communes c ON c.id = e.commune_id
            JOIN departements d ON d.id = c.departement_id
            WHERE e.actif = TRUE""";

    private record Prod(int id, String nom, String unite, double seuil) {}

    private final JdbcTemplate jdbc;

    public DirectionService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ------------------------------------------------------------------ utilitaires
    private static Number num(Object o) { return o == null ? 0 : (Number) o; }

    /** Convertit les dates SQL en texte ISO pour le JSON. */
    private static Object norm(Object v) {
        if (v instanceof Timestamp t) return t.toLocalDateTime().toString();
        if (v instanceof LocalDateTime || v instanceof LocalDate || v instanceof java.sql.Date) return v.toString();
        return v;
    }

    private static LocalDateTime toLdt(Object v) {
        if (v instanceof Timestamp t) return t.toLocalDateTime();
        if (v instanceof LocalDateTime l) return l;
        return null;
    }

    private static List<Map<String, Object>> propres(List<Map<String, Object>> rows) {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            Map<String, Object> m = new LinkedHashMap<>();
            r.forEach((k, v) -> m.put(k, norm(v)));
            out.add(m);
        }
        return out;
    }

    /** Département imposé pour une direction départementale, null pour l'administrateur national. */
    private static Integer perimetre(AuthUser u) {
        if (u.role() == Role.DIRECTION_DEPARTEMENTALE) {
            if (u.departementId() == null) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Compte sans département");
            }
            return u.departementId();
        }
        return null;
    }

    private List<Prod> produits() {
        List<Prod> l = new ArrayList<>();
        for (Map<String, Object> r : jdbc.queryForList("SELECT id, nom, unite, seuil_alerte FROM produits ORDER BY id")) {
            l.add(new Prod(num(r.get("id")).intValue(), (String) r.get("nom"), (String) r.get("unite"),
                    num(r.get("seuil_alerte")).doubleValue()));
        }
        return l;
    }

    /** Stock actuel par école puis par produit, calculé à partir du registre. */
    private Map<Integer, Map<Integer, Double>> stocks(Integer dep) {
        String sql = """
                SELECT m.ecole_id, m.produit_id,
                       SUM(CASE WHEN m.type IN ('ENTREE','AJUSTEMENT_PLUS') THEN m.quantite ELSE -m.quantite END) AS stock
                FROM mouvements_stock m
                JOIN ecoles e ON e.id = m.ecole_id
                JOIN communes c ON c.id = e.commune_id
                WHERE m.supprime = FALSE""" + (dep != null ? " AND c.departement_id = ?" : "")
                + " GROUP BY m.ecole_id, m.produit_id";
        Map<Integer, Map<Integer, Double>> res = new HashMap<>();
        for (Map<String, Object> r : jdbc.queryForList(sql, dep != null ? new Object[]{dep} : new Object[0])) {
            res.computeIfAbsent(num(r.get("ecole_id")).intValue(), k -> new HashMap<>())
                    .put(num(r.get("produit_id")).intValue(), num(r.get("stock")).doubleValue());
        }
        return res;
    }

    // ------------------------------------------------------------------ écoles
    public List<Map<String, Object>> ecoles(AuthUser u) {
        Integer dep = perimetre(u);
        List<Prod> produits = produits();
        Map<Integer, Map<Integer, Double>> stocks = stocks(dep);
        String sql = BASE_ECOLES + (dep != null ? " AND d.id = ?" : "") + " ORDER BY e.nom";
        List<Map<String, Object>> rows = jdbc.queryForList(sql, dep != null ? new Object[]{dep} : new Object[0]);

        List<Map<String, Object>> out = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            int id = num(r.get("id")).intValue();
            Map<Integer, Double> st = stocks.getOrDefault(id, Map.of());
            List<String> critiques = new ArrayList<>();
            for (Prod p : produits) {
                if (st.getOrDefault(p.id(), 0.0) <= p.seuil()) critiques.add(p.nom());
            }
            LocalDateTime sync = toLdt(r.get("derniere_sync"));
            Long jours = sync == null ? null : ChronoUnit.DAYS.between(sync, LocalDateTime.now());
            String statut = (jours == null || jours > JOURS_SANS_SYNC) ? "SANS_SYNC"
                    : critiques.isEmpty() ? "A_JOUR" : "ALERTE_STOCK";

            Map<String, Object> o = new LinkedHashMap<>();
            r.forEach((k, v) -> o.put(k, norm(v)));
            o.put("jours_sans_sync", jours);
            o.put("produits_critiques", critiques);
            o.put("statut", statut);
            out.add(o);
        }
        return out;
    }

    public Map<String, Object> detailEcole(AuthUser u, int id) {
        Map<String, Object> ecole = ecoles(u).stream()
                .filter(e -> num(e.get("id")).intValue() == id)
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "École introuvable"));

        Map<Integer, Double> st = stocks(perimetre(u)).getOrDefault(id, Map.of());
        List<Map<String, Object>> stockList = new ArrayList<>();
        for (Prod p : produits()) {
            double s = st.getOrDefault(p.id(), 0.0);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("produit_id", p.id());
            m.put("produit", p.nom());
            m.put("unite", p.unite());
            m.put("stock", s);
            m.put("seuil_alerte", p.seuil());
            m.put("sous_seuil", s <= p.seuil());
            stockList.add(m);
        }

        List<Map<String, Object>> mouvements = propres(jdbc.queryForList("""
                SELECT m.numero, m.date_mouvement, m.type, p.nom AS produit, p.unite, m.quantite, m.motif, m.auteur
                FROM mouvements_stock m JOIN produits p ON p.id = m.produit_id
                WHERE m.ecole_id = ? AND m.supprime = FALSE
                ORDER BY m.numero DESC, m.date_mouvement DESC LIMIT 20""", id));

        List<Map<String, Object>> menus = propres(jdbc.queryForList("""
                SELECT m.date_menu, pl.nom AS plat, m.effectif_prevu, m.effectif_servi, m.statut
                FROM menus m JOIN plats pl ON pl.id = m.plat_id
                WHERE m.ecole_id = ? AND m.supprime = FALSE
                ORDER BY m.date_menu DESC LIMIT 7""", id));

        Map<String, Object> res = new LinkedHashMap<>(ecole);
        res.put("stocks", stockList);
        res.put("derniers_mouvements", mouvements);
        res.put("menus", menus);
        return res;
    }

    // ------------------------------------------------------------------ rapports
    public List<Map<String, Object>> rapports(AuthUser u, int jours) {
        Integer dep = perimetre(u);
        LocalDate fin = LocalDate.now();
        LocalDate debut = fin.minusDays(jours - 1L);
        String sql = """
                SELECT c.nom AS commune, COUNT(DISTINCT e.id) AS ecoles,
                       COALESCE(SUM(CASE WHEN m.statut = 'SERVI' THEN 1 ELSE 0 END), 0) AS repas_servis,
                       COALESCE(SUM(CASE WHEN m.statut = 'SERVI' THEN m.effectif_servi ELSE 0 END), 0) AS eleves_servis
                FROM communes c
                JOIN ecoles e ON e.commune_id = c.id AND e.actif = TRUE
                LEFT JOIN menus m ON m.ecole_id = e.id AND m.supprime = FALSE AND m.date_menu BETWEEN ? AND ?
                WHERE 1 = 1""" + (dep != null ? " AND c.departement_id = ?" : "")
                + " GROUP BY c.id, c.nom ORDER BY c.nom";
        Object[] args = dep != null
                ? new Object[]{java.sql.Date.valueOf(debut), java.sql.Date.valueOf(fin), dep}
                : new Object[]{java.sql.Date.valueOf(debut), java.sql.Date.valueOf(fin)};
        List<Map<String, Object>> rows = propres(jdbc.queryForList(sql, args));

        Map<String, Integer> alertes = new HashMap<>();
        Map<String, Integer> sansSync = new HashMap<>();
        for (Map<String, Object> e : ecoles(u)) {
            String c = (String) e.get("commune");
            if ("ALERTE_STOCK".equals(e.get("statut"))) alertes.merge(c, 1, Integer::sum);
            if ("SANS_SYNC".equals(e.get("statut"))) sansSync.merge(c, 1, Integer::sum);
        }
        for (Map<String, Object> r : rows) {
            r.put("ecoles_alerte_stock", alertes.getOrDefault((String) r.get("commune"), 0));
            r.put("ecoles_sans_sync", sansSync.getOrDefault((String) r.get("commune"), 0));
        }
        return rows;
    }

    // ------------------------------------------------------------------ stock consolidé
    public List<Map<String, Object>> stockConsolide(AuthUser u) {
        Integer dep = perimetre(u);
        Map<Integer, Map<Integer, Double>> stocks = stocks(dep);
        List<Integer> ecoleIds = new ArrayList<>();
        for (Map<String, Object> e : ecoles(u)) ecoleIds.add(num(e.get("id")).intValue());

        List<Map<String, Object>> out = new ArrayList<>();
        for (Prod p : produits()) {
            double total = 0;
            int sous = 0;
            for (int id : ecoleIds) {
                double s = stocks.getOrDefault(id, Map.of()).getOrDefault(p.id(), 0.0);
                total += s;
                if (s <= p.seuil()) sous++;
            }
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("produit", p.nom());
            m.put("unite", p.unite());
            m.put("stock_total", Math.round(total * 1000) / 1000.0);
            m.put("ecoles_sous_seuil", sous);
            out.add(m);
        }
        return out;
    }
}
