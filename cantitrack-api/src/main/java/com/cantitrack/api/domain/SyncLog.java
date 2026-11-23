package com.cantitrack.api.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "sync_log", indexes = @Index(name = "idx_sync_ecole", columnList = "ecole_id, date_sync"))
public class SyncLog {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) public Long id;
    @Column(nullable = false) public Integer ecoleId;
    @Column(nullable = false) public LocalDateTime dateSync;
    @Column(nullable = false) public int nbEnregistrements;
    @Column(nullable = false, length = 10) public String statut;
    @Column(length = 255) public String message;
}
