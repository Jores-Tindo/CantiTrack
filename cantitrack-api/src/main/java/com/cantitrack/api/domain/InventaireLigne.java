package com.cantitrack.api.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "inventaire_lignes")
public class InventaireLigne {
    @Id @Column(length = 36) public String id;
    @Column(nullable = false, length = 36) public String inventaireId;
    @Column(nullable = false) public Integer produitId;
    @Column(nullable = false, precision = 12, scale = 3) public BigDecimal quantiteTheorique;
    @Column(nullable = false, precision = 12, scale = 3) public BigDecimal quantiteReelle;
}
