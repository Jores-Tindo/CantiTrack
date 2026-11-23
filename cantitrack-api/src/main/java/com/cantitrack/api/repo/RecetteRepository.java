package com.cantitrack.api.repo;

import com.cantitrack.api.domain.Recette;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RecetteRepository extends JpaRepository<Recette, Integer> {
    List<Recette> findByPlatId(Integer platId);
}
