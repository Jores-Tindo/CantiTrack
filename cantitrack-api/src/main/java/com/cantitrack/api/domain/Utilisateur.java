package com.cantitrack.api.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "utilisateurs")
public class Utilisateur {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) public Integer id;
    @Column(nullable = false, length = 120) public String nomComplet;
    @Column(nullable = false, unique = true, length = 60) public String login;
    @Column(nullable = false) public String motDePasseHash;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30) public Role role;
    public Integer ecoleId;
    public Integer departementId;
    @Column(length = 20) public String telephone;
    @Column(nullable = false) public boolean actif = true;
}
