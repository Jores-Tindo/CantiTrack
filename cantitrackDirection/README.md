# CantiTrack - tableau de bord direction (web)

## Lancer
Double-cliquer sur `index.html`, ou depuis ce dossier : `python3 -m http.server 8000` puis ouvrir http://localhost:8000

## Fichiers
- `index.html` : structure de la page (en-tete, zone principale, chargement des scripts)
- `css/style.css` : couleurs (variables --g, --r, --bg...), mode sombre, mise en page
- `js/data.js` : donnees d'exemple (produits P, ecoles E). C'est ici que l'API remplacera les donnees
- `js/app.js` : utilitaires, vues (objet V), actions, navigation (go, L)

## A faire
- Remplacer data.js par des appels API (fetch) une fois le serveur Spring Boot pret
- Vraie authentification, gestion des utilisateurs, carte des ecoles
- Export CSV/PDF par telechargement (possible une fois heberge)
