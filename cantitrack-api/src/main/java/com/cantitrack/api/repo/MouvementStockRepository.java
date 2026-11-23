package com.cantitrack.api.repo;

import com.cantitrack.api.domain.MouvementStock;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MouvementStockRepository extends JpaRepository<MouvementStock, String> {
    List<MouvementStock> findByEcoleIdAndDateModifAfter(Integer ecoleId, LocalDateTime depuis);
}
