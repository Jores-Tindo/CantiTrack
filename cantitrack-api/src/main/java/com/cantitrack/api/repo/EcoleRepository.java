package com.cantitrack.api.repo;

import com.cantitrack.api.domain.Ecole;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EcoleRepository extends JpaRepository<Ecole, Integer> {

}
