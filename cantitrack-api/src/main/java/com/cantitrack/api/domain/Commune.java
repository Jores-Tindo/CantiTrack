package com.cantitrack.api.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "communes", uniqueConstraints = @UniqueConstraint(columnNames = {"nom", "departement_id"}))
public class Commune {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) public Integer id;
    @Column(nullable = false, length = 80) public String nom;
    @Column(nullable = false) public Integer departementId;
}
