package com.cantitrack.api.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Une ligne du registre numérique. Jamais modifiée ni supprimée une fois reçue. */
@Entity
@Table(name = "mouvements_stock", indexes = @Index(name = "idx_mvt_ecole_prod", columnList = "ecole_id, produit_id, date_mouvement"))
public class MouvementStock {
    @Id @Column(length = 36) public String id;
    @Column(nullable = false) public Integer ecoleId;
    @Column(nullable = false) public Integer produitId;
    @Column(nullable = false, length = 20) public String type;
    @Column(nullable = false, precision = 12, scale = 3) public BigDecimal quantite;
    @Column(nullable = false) public LocalDateTime dateMouvement;
    @Column(length = 36) public String menuId;
    @Column(length = 255) public String motif;
    @Column(nullable = false) public int numero;
    @Column(length = 120) public String auteur;
    @Column(nullable = false) public LocalDateTime dateModif;
    @Column(nullable = false) public boolean supprime;
}
