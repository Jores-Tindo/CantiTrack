package com.cantitrack.api.web;

import com.cantitrack.api.dto.Dto;
import com.cantitrack.api.security.AuthUser;
import com.cantitrack.api.service.SyncService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/** Endpoints utilisés par l'application mobile de l'école. */
@RestController
@RequestMapping("/api/sync")
public class SyncController {
    private final SyncService sync;

    public SyncController(SyncService sync) {
        this.sync = sync;
    }

    /** Envoie les données locales. Peut être appelé avec un corps vide pour signaler « synchronisé ». */
    @PostMapping("/push")
    public Dto.PushResult push(@AuthenticationPrincipal AuthUser u, @RequestBody Dto.PushRequest req) {
        return sync.push(u, req);
    }

    /** Sans paramètre : restauration complète (nouveau téléphone). Avec « depuis » : changements seulement. */
    @GetMapping("/pull")
    public Dto.PullResponse pull(@AuthenticationPrincipal AuthUser u,
                                 @RequestParam(required = false) String depuis) {
        return sync.pull(u, depuis);
    }
}
