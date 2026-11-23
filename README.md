# 🍲 CantiTrack — Gestion Numérique des Cantines Scolaires au Bénin

**CantiTrack** est une solution numérique intégrée conçue pour moderniser, sécuriser et optimiser le suivi des cantines scolaires au Bénin. Elle permet d'assurer la traçabilité des rations alimentaires, la gestion des stocks dans les écoles et le pilotage global en temps réel.

---

## 🏗️ Architecture du Projet

Le dépôt est structuré sous forme de **Monorepo** regroupant les trois composants du système :

```text
CantiTrack/
├── cantitrack-api/         # Backend & API REST (Java / Spring Boot)
├── Mobile/cantitrack/      # Application mobile de terrain (Flutter / Dart)
└── cantitrackDirection/    # Tableau de bord général de contrôle (HTML5 / CSS3 / JavaScript)
```

---

## 🚀 Fonctionnalités Principales

* **📱 Application Mobile (`Mobile/`) :** Destinée aux gestionnaires et acteurs de terrain (directeurs d'école, magasiniers) pour enregistrer les effectifs quotidiens, suivre la consommation des vivres et gérer les entrées/sorties de stocks.
* **📊 Tableau de Bord Direction (`cantitrackDirection/`) :** Interface web de supervision permettant aux autorités et coordinateurs de visualiser les statistiques globales, contrôler les anomalies et suivre l'approvisionnement des écoles en temps réel.
* **⚙️ API Centrale (`cantitrack-api/`) :** Cœur métier sécurisé assurant la synchronisation des données, la gestion des rôles utilisateurs et l'interopérabilité entre le mobile et le web.

---

## 🛠️ Stack Technique

* **Mobile :** Flutter, Dart
* **Backend :** Java, Spring Boot, Spring Security, JPA/Hibernate
* **Web Dashboard :** HTML5, CSS3, JavaScript (Vanilla)
* **Base de données :** MySQL / PostgreSQL *(à adapter selon ta configuration)*

---

## ⚙️ Installation & Démarrage rapide

### 1. Cloner le dépôt
```bash
git clone https://github.com
cd CantiTrack
```

### 2. Lancer le Backend (`cantitrack-api`)
```bash
cd cantitrack-api
./mvnw spring-boot:run
```

### 3. Lancer l'Application Mobile (`Mobile/cantitrack`)
```bash
cd Mobile/cantitrack
flutter pub get
flutter run
```

### 4. Ouvrir le Tableau de Bord (`cantitrackDirection`)
Ouvrir simplement le fichier `index.html` dans un navigateur ou via l'extension **Live Server** de VS Code.

---

## 👨‍💻 Auteur
Développé par **Jores** — Projet de digitalisation des cantines scolaires au Bénin 🇧🇯.
