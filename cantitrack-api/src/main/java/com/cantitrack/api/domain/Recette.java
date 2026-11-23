package com.cantitrack.api.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "recettes", uniqueConstraints = @UniqueConstraint(columnNames = {"plat_id", "produit_id"}))
public class Recette {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) public Integer id;
    @Column(nullable = false) public Integer platId;
    @Column(nullable = false) public Integer produitId;
    @Column(nullable = false, precision = 8, scale = 4) public BigDecimal quantiteParEleve;
}
