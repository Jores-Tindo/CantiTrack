package com.cantitrack.api.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "ecoles")
public class Ecole {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) public Integer id;
    @Column(nullable = false, unique = true, length = 30) public String code;
    @Column(nullable = false, length = 150) public String nom;
    @Column(nullable = false) public Integer communeId;
    @Column(nullable = false) public int effectifTotal;
    @Column(nullable = false) public int effectifCantine;
    @Column(nullable = false) public boolean actif = true;
}
