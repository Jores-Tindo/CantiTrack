package com.cantitrack.api.repo;

import com.cantitrack.api.domain.Menu;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MenuRepository extends JpaRepository<Menu, String> {
    List<Menu> findByEcoleIdAndDateModifAfter(Integer ecoleId, LocalDateTime depuis);
    Optional<Menu> findByEcoleIdAndDateMenu(Integer ecoleId, LocalDate dateMenu);
}
