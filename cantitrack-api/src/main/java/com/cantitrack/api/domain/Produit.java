package com.cantitrack.api.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "produits")
public class Produit {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) public Integer id;
    @Column(nullable = false, unique = true, length = 100) public String nom;
    @Column(nullable = false, length = 10) public String unite;
    @Column(nullable = false, precision = 10, scale = 2) public BigDecimal seuilAlerte = BigDecimal.ZERO;
}
