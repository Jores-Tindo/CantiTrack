package com.cantitrack.api.security;

import com.cantitrack.api.domain.Role;

/** Utilisateur authentifié, lu dans le jeton JWT. */
public record AuthUser(Integer id, String login, Role role, Integer ecoleId, Integer departementId) {}
