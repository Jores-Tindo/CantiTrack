# CantiTrack - application mobile (Flutter, hors-ligne) - v0.2

Palette : vert forêt adouci (#2F6B4F) sur fond crème (#F4F1EA), alertes en rouge.

## Création du projet (officiel, avec identifiant de paquet)
```bash
flutter create --org com.cantitrack --project-name cantitrack --platforms=android cantitrack
cd cantitrack
```
Puis : remplacer `pubspec.yaml` et le dossier `lib/` par ceux de ce zip, supprimer `test/widget_test.dart`,
mettre `android:label="CantiTrack"` dans `android/app/src/main/AndroidManifest.xml`, puis :
```bash
flutter pub get
flutter run
```
`flutter build apk` génère l'APK de test (pilote dans les écoles).

## Écrans (v0.2)
Connexion (code à 4 chiffres local) · Accueil · Stock · Détail produit · Nouveau mouvement ·
Menus · Programmer / Servir un repas · Livraisons · Réception · Inventaire · Registre numérique
(numérotation continue, export PDF, rectification) · Rapports (partage WhatsApp) · Sauvegarde et restauration · Réglages.

## Pas encore branché
- Synchronisation avec le serveur central (bouton présent, message explicatif)
- Restauration sur un nouveau téléphone (dépend du serveur)
- Quantités par élève : valeurs d'exemple à remplacer par les rations officielles
- Les anciens fichiers (ex. historique_screen.dart) sont conservés mais ne sont plus utilisés
