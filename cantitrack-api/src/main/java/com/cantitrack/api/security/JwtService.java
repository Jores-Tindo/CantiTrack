package com.cantitrack.api.security;

import com.cantitrack.api.domain.Role;
import com.cantitrack.api.domain.Utilisateur;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    private final SecretKey key;
    private final long ttlMs;

    public JwtService(@Value("${cantitrack.jwt-secret}") String secret,
                      @Value("${cantitrack.jwt-ttl-hours:12}") long heures) {
        byte[] octets = secret.getBytes(StandardCharsets.UTF_8);
        if (octets.length < 32) {
            throw new IllegalStateException("cantitrack.jwt-secret doit contenir au moins 32 caractères");
        }
        this.key = Keys.hmacShaKeyFor(octets);
        this.ttlMs = heures * 3_600_000L;
    }

    public String creer(Utilisateur u) {
        JwtBuilder b = Jwts.builder()
                .subject(u.login)
                .claim("uid", u.id)
                .claim("role", u.role.name())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + ttlMs));
        if (u.ecoleId != null) b.claim("ecole_id", u.ecoleId);
        if (u.departementId != null) b.claim("dep_id", u.departementId);
        return b.signWith(key).compact();
    }

    /** Lève une JwtException si le jeton est invalide ou expiré. */
    public AuthUser lire(String token) {
        Claims c = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
        return new AuthUser(c.get("uid", Integer.class), c.getSubject(),
                Role.valueOf(c.get("role", String.class)),
                c.get("ecole_id", Integer.class), c.get("dep_id", Integer.class));
    }
}
