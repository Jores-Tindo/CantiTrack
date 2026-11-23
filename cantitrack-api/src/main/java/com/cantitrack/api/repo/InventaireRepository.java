package com.cantitrack.api.repo;

import com.cantitrack.api.domain.Inventaire;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InventaireRepository extends JpaRepository<Inventaire, String> {
    List<Inventaire> findByEcoleIdAndDateModifAfter(Integer ecoleId, LocalDateTime depuis);
}
