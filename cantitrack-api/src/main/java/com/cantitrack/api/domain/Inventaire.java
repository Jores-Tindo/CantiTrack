package com.cantitrack.api.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "inventaires")
public class Inventaire {
    @Id @Column(length = 36) public String id;
    @Column(nullable = false) public Integer ecoleId;
    @Column(nullable = false) public LocalDate dateInventaire;
    @Column(length = 120) public String utilisateur;
    @Column(nullable = false) public LocalDateTime dateModif;
}
