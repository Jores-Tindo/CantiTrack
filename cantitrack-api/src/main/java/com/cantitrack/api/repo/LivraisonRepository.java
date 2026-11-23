package com.cantitrack.api.repo;

import com.cantitrack.api.domain.Livraison;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LivraisonRepository extends JpaRepository<Livraison, String> {
    List<Livraison> findByEcoleIdAndDateModifAfter(Integer ecoleId, LocalDateTime depuis);
}
