package com.cantitrack.api.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "livraison_lignes")
public class LivraisonLigne {
    @Id @Column(length = 36) public String id;
    @Column(nullable = false, length = 36) public String livraisonId;
    @Column(nullable = false) public Integer produitId;
    @Column(nullable = false, precision = 12, scale = 3) public BigDecimal quantitePrevue = BigDecimal.ZERO;
    @Column(nullable = false, precision = 12, scale = 3) public BigDecimal quantiteRecue = BigDecimal.ZERO;
    @Column(nullable = false, precision = 12, scale = 3) public BigDecimal quantiteAbimee = BigDecimal.ZERO;
}
