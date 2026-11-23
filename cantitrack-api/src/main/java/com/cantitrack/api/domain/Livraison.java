package com.cantitrack.api.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "livraisons")
public class Livraison {
    @Id @Column(length = 36) public String id;
    @Column(nullable = false) public Integer ecoleId;
    @Column(nullable = false, length = 150) public String fournisseur;
    @Column(length = 50) public String numeroBon;
    public LocalDate datePrevue;
    public LocalDate dateReception;
    @Column(nullable = false, length = 12) public String statut = "ATTENDUE";
    @Column(nullable = false) public LocalDateTime dateModif;
    @Column(nullable = false) public boolean supprime;
}
