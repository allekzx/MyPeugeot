# App mobile (Flutter)

Ce dossier contient uniquement le code source Dart (`lib/`, `pubspec.yaml`). Les dossiers de plateforme (`android/`, `ios/`) doivent être générés localement avec le SDK Flutter, indisponible dans cet environnement de développement à distance.

## Mise en place (première fois)

```bash
cd mobile
flutter create --project-name mypeugeot .
flutter pub get
```

`flutter create .` sur un dossier qui a déjà un `pubspec.yaml` et un `lib/` ajoute les dossiers `android/`, `ios/`, etc. sans écraser le code existant.

## Configuration de l'URL du backend

L'URL du backend (`backend/` du dépôt, déployé sur ton Raspberry Pi/serveur) est à renseigner dans `lib/services/api_service.dart` (constante `baseUrl`), ou à passer au build via `--dart-define=API_BASE_URL=https://mon-backend:5000`.

## Lancer l'app

```bash
flutter run --dart-define=API_BASE_URL=http://<ip-backend>:5000
```

## Structure

```
lib/
  main.dart                    # point d'entrée
  app.dart                     # MaterialApp + routes
  models/
    vehicle_status.dart        # modèle de statut véhicule
  services/
    api_service.dart           # client HTTP vers le backend
  screens/
    login_screen.dart          # stub d'écran de connexion
    dashboard_screen.dart      # statut véhicule + actions
  widgets/
    battery_gauge.dart         # jauge de batterie réutilisable
```

## État actuel

Écrans et service API sont des stubs fonctionnels avec des données simulées (`ApiService` en mode mock) pour permettre de développer l'UI avant que le backend soit branché. Prochaine étape : brancher `ApiService` sur les vraies routes exposées par `psa_car_controller` (voir `backend/README.md`).
