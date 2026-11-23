package com.cantitrack.api.repo;

import com.cantitrack.api.domain.Departement;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DepartementRepository extends JpaRepository<Departement, Integer> {

}
