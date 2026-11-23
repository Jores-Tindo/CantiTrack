package com.cantitrack.api.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "departements")
public class Departement {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) public Integer id;
    @Column(nullable = false, unique = true, length = 50) public String nom;
}
