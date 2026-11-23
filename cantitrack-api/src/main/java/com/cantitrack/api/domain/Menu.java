package com.cantitrack.api.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "menus", uniqueConstraints = @UniqueConstraint(columnNames = {"ecole_id", "date_menu"}))
public class Menu {
    @Id @Column(length = 36) public String id;
    @Column(nullable = false) public Integer ecoleId;
    @Column(nullable = false) public LocalDate dateMenu;
    @Column(nullable = false) public Integer platId;
    @Column(nullable = false) public Integer effectifPrevu;
    public Integer effectifServi;
    @Column(nullable = false, length = 10) public String statut = "PREVU";
    @Column(nullable = false) public LocalDateTime dateModif;
    @Column(nullable = false) public boolean supprime;
}
