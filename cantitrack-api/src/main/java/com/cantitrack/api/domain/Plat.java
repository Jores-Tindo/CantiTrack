package com.cantitrack.api.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "plats")
public class Plat {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) public Integer id;
    @Column(nullable = false, unique = true, length = 100) public String nom;
}
