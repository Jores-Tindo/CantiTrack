# CantiTrack API (Spring Boot 3.5, Java 17, MySQL)

API unique pour l'application mobile des écoles (synchronisation du registre) et le tableau de bord web de la direction.

## 1. Prérequis (Ubuntu)
```bash
sudo apt install openjdk-17-jdk maven mysql-server
java -version   # 17 ou plus
```

## 2. Base de données MySQL
```bash
sudo mysql
```
```sql
CREATE DATABASE cantitrack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'cantitrack'@'localhost' IDENTIFIED BY 'dev-password';
GRANT ALL PRIVILEGES ON cantitrack.* TO 'cantitrack'@'localhost';
FLUSH PRIVILEGES;
```

## 3. Lancer en développement
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```
Le profil `dev` crée les tables, les départements, les produits, les plats, le compte admin
(`admin` / `ChangeMe-Dev-2026`) et des comptes de démonstration
(`gestionnaire.demo`, `direction.demo` / `Demo-Passw0rd-2026`). A n'utiliser qu'en local.

## 4. Tester avec curl
```bash
# connexion de l'école de démonstration
curl -s -X POST localhost:8080/api/auth/login -H 'Content-Type: application/json' \
  -d '{"login":"gestionnaire.demo","mot_de_passe":"Demo-Passw0rd-2026"}'
TOKEN=<copier le champ token>

# envoyer une ligne de registre (idempotent : renvoyer la même ligne ne crée pas de doublon)
curl -s -X POST localhost:8080/api/sync/push -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"mouvements":[{"id":"11111111-1111-1111-1111-111111111111","produit_id":1,"type":"ENTREE","quantite":50,
       "date_mouvement":"2026-11-08T08:30:00","motif":"Bordereau 112","numero":1,"auteur":"Test",
       "date_modif":"2026-11-08T08:30:00"}]}'

# restauration complète (nouveau téléphone)
curl -s localhost:8080/api/sync/pull -H "Authorization: Bearer $TOKEN"

# tableau de bord direction
curl -s -X POST localhost:8080/api/auth/login -H 'Content-Type: application/json' \
  -d '{"login":"direction.demo","mot_de_passe":"Demo-Passw0rd-2026"}'
curl -s localhost:8080/api/direction/ecoles -H "Authorization: Bearer <token direction>"
```

## 5. Endpoints
| Méthode | Chemin | Rôles | Rôle |
|---|---|---|---|
| GET | /api/sante | public | test de vie |
| POST | /api/auth/login | public | connexion, renvoie un jeton JWT |
| POST | /api/sync/push | gestionnaire, directeur d'école | envoie menus, livraisons, mouvements, inventaires |
| GET | /api/sync/pull?depuis=... | gestionnaire, directeur d'école | restaure ou récupère les changements |
| GET | /api/direction/ecoles | direction, admin | écoles avec statut (A_JOUR, ALERTE_STOCK, SANS_SYNC) |
| GET | /api/direction/ecoles/{id} | direction, admin | stock, derniers mouvements, menus |
| GET | /api/direction/rapports?jours=7 | direction, admin | synthèse par commune |
| GET | /api/direction/stock-consolide | direction, admin | stock total par produit |
| GET/POST | /api/admin/communes, ecoles, utilisateurs | admin national | gestion des référentiels |
| GET/PUT | /api/admin/produits | admin national | seuils d'alerte |

## 6. Règles importantes
- Le registre est en insertion seule : une ligne de `mouvements_stock` déjà reçue n'est jamais modifiée.
- Chaque compte d'école ne peut envoyer et lire que les données de son école (l'école vient du jeton, pas de la requête).
- Une direction départementale ne voit que son département.
- Les identifiants des produits et plats suivent l'ordre de la base locale du mobile (Riz=1, Haricot=2, Maïs=3, Huile=4, Sel=5, Tomate=6). Ne pas les réordonner.
- JSON en snake_case, identique aux colonnes SQLite du mobile.

## 7. Avant la production
- Variables d'environnement : DB_URL, DB_USER, DB_PASSWORD, JWT_SECRET (32 caractères minimum, aléatoire), ADMIN_PASSWORD, CORS_ORIGINS.
- Ne pas utiliser le profil `dev`. Premier démarrage : `DDL_AUTO=update`, puis passer à `validate` (ou ajouter Flyway).
- HTTPS obligatoire (reverse proxy Nginx + Let's Encrypt).
- Sauvegardes MySQL automatiques et testées.
- A ajouter : limitation des tentatives de connexion, changement de mot de passe, désactivation immédiate d'un compte (le jeton dure 12 h), tests automatiques.
- Les quantités par élève (recettes) sont des valeurs d'exemple à remplacer par les rations officielles.
