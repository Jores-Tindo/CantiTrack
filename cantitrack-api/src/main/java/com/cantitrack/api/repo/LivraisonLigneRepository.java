package com.cantitrack.api.repo;

import com.cantitrack.api.domain.LivraisonLigne;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LivraisonLigneRepository extends JpaRepository<LivraisonLigne, String> {
    List<LivraisonLigne> findByLivraisonIdIn(Collection<String> ids);
}
