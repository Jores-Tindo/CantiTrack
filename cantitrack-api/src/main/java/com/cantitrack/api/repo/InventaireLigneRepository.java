package com.cantitrack.api.repo;

import com.cantitrack.api.domain.InventaireLigne;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InventaireLigneRepository extends JpaRepository<InventaireLigne, String> {
    List<InventaireLigne> findByInventaireIdIn(Collection<String> ids);
}
