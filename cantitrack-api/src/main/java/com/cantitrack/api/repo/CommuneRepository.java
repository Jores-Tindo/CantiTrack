package com.cantitrack.api.repo;

import com.cantitrack.api.domain.Commune;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CommuneRepository extends JpaRepository<Commune, Integer> {

}
