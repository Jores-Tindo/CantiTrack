package com.cantitrack.api.repo;

import com.cantitrack.api.domain.Produit;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProduitRepository extends JpaRepository<Produit, Integer> {

}
