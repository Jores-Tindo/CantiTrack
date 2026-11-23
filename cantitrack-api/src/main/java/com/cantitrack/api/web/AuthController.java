package com.cantitrack.api.web;

import com.cantitrack.api.domain.Utilisateur;
import com.cantitrack.api.dto.Dto;
import com.cantitrack.api.repo.UtilisateurRepository;
import com.cantitrack.api.security.JwtService;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api")
public class AuthController {
    private final UtilisateurRepository users;
    private final PasswordEncoder encoder;
    private final JwtService jwt;

    public AuthController(UtilisateurRepository users, PasswordEncoder encoder, JwtService jwt) {
        this.users = users;
        this.encoder = encoder;
        this.jwt = jwt;
    }

    @GetMapping("/sante")
    public Map<String, String> sante() {
        return Map.of("statut", "ok");
    }

    @PostMapping("/auth/login")
    public Dto.LoginResponse login(@Valid @RequestBody Dto.LoginRequest req) {
        Utilisateur u = users.findByLogin(req.login().trim())
                .filter(x -> x.actif && encoder.matches(req.motDePasse(), x.motDePasseHash))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Identifiant ou mot de passe incorrect"));
        return new Dto.LoginResponse(jwt.creer(u), u.role.name(), u.nomComplet, u.ecoleId, u.departementId);
    }
}
