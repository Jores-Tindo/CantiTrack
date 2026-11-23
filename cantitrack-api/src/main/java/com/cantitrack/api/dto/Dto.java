package com.cantitrack.api.dto;

import com.cantitrack.api.domain.Role;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;

/** Objets échangés avec le mobile et le tableau de bord (JSON en snake_case). */
public final class Dto {
    private Dto() {}

    // ---- Authentification ----
    public record LoginRequest(@NotBlank String login, @NotBlank String motDePasse) {}
    public record LoginResponse(String token, String role, String nomComplet, Integer ecoleId, Integer departementId) {}

    // ---- Synchronisation (mêmes noms que les colonnes SQLite du mobile) ----
    public record MenuDto(String id, String dateMenu, Integer platId, Integer effectifPrevu,
                          Integer effectifServi, String statut, String dateModif, Integer supprime) {}
    public record LivraisonDto(String id, String fournisseur, String numeroBon, String datePrevue,
                               String dateReception, String statut, String dateModif, Integer supprime) {}
    public record LivraisonLigneDto(String id, String livraisonId, Integer produitId, BigDecimal quantitePrevue,
                                    BigDecimal quantiteRecue, BigDecimal quantiteAbimee) {}
    public record MouvementDto(String id, Integer produitId, String type, BigDecimal quantite, String dateMouvement,
                               String menuId, String motif, Integer numero, String auteur, String dateModif,
                               Integer supprime) {}
    public record InventaireDto(String id, String dateInventaire, String utilisateur, String dateModif) {}
    public record InventaireLigneDto(String id, String inventaireId, Integer produitId,
                                     BigDecimal quantiteTheorique, BigDecimal quantiteReelle) {}

    public record PushRequest(List<MenuDto> menus, List<LivraisonDto> livraisons,
                              List<LivraisonLigneDto> livraisonLignes, List<MouvementDto> mouvements,
                              List<InventaireDto> inventaires, List<InventaireLigneDto> inventaireLignes) {}
    public record PushResult(int recus, int dejaPresents, List<String> rejets, String heureServeur) {}

    public record RecetteDto(Integer produitId, BigDecimal quantiteParEleve) {}
    public record PlatDto(Integer id, String nom, List<RecetteDto> recettes) {}
    public record ProduitDto(Integer id, String nom, String unite, BigDecimal seuilAlerte) {}
    public record PullResponse(List<ProduitDto> produits, List<PlatDto> plats, List<MenuDto> menus,
                               List<LivraisonDto> livraisons, List<LivraisonLigneDto> livraisonLignes,
                               List<MouvementDto> mouvements, List<InventaireDto> inventaires,
                               List<InventaireLigneDto> inventaireLignes, String heureServeur) {}

    // ---- Administration ----
    public record CommuneRequest(@NotBlank String nom, @NotNull Integer departementId) {}
    public record EcoleRequest(@NotBlank String code, @NotBlank String nom, @NotNull Integer communeId,
                               @Min(0) int effectifTotal, @Min(0) int effectifCantine) {}
    public record UtilisateurRequest(@NotBlank String nomComplet, @NotBlank String login,
                                     @NotBlank @Size(min = 8, message = "8 caractères minimum") String motDePasse,
                                     @NotNull Role role, Integer ecoleId, Integer departementId, String telephone) {}
    public record UtilisateurView(Integer id, String nomComplet, String login, Role role, Integer ecoleId,
                                  Integer departementId, boolean actif) {}
    public record SeuilRequest(@NotNull @DecimalMin("0") BigDecimal seuilAlerte) {}
}
