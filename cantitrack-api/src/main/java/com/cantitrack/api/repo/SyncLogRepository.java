package com.cantitrack.api.repo;

import com.cantitrack.api.domain.SyncLog;
import java.time.*;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SyncLogRepository extends JpaRepository<SyncLog, Long> {

}
