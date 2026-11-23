package com.cantitrack.api.web;

import com.cantitrack.api.security.AuthUser;
import com.cantitrack.api.service.DirectionService;
import java.util.List;
import java.util.Map;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/** Endpoints du tableau de bord web (direction nationale ou départementale). */
@RestController
@RequestMapping("/api/direction")
public class DirectionController {
    private final DirectionService direction;

    public DirectionController(DirectionService direction) {
        this.direction = direction;
    }

    @GetMapping("/ecoles")
    public List<Map<String, Object>> ecoles(@AuthenticationPrincipal AuthUser u) {
        return direction.ecoles(u);
    }

    @GetMapping("/ecoles/{id}")
    public Map<String, Object> ecole(@AuthenticationPrincipal AuthUser u, @PathVariable int id) {
        return direction.detailEcole(u, id);
    }

    @GetMapping("/rapports")
    public List<Map<String, Object>> rapports(@AuthenticationPrincipal AuthUser u,
                                              @RequestParam(defaultValue = "7") int jours) {
        return direction.rapports(u, Math.max(1, Math.min(jours, 90)));
    }

    @GetMapping("/stock-consolide")
    public List<Map<String, Object>> stock(@AuthenticationPrincipal AuthUser u) {
        return direction.stockConsolide(u);
    }
}
