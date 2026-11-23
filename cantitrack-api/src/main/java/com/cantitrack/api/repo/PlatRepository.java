package com.cantitrack.api.repo;

import com.cantitrack.api.domain.Plat;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlatRepository extends JpaRepository<Plat, Integer> {

}
