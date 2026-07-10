# App mobile (Flutter)

App iOS/Android : dashboard sombre jaune/noir (clin d'œil au jaune de la e-208) avec verrouillage, charge, préconditionnement, historique de trajets, charge programmée et alertes/géofencing.

Les dossiers `android/` et `ios/` sont générés par `flutter create` et **versionnés** (seuls les artefacts de build sont ignorés, voir `.gitignore` local). Si tu repars d'un clone frais et qu'ils manquent, régénère-les :

```bash
cd mobile
flutter create --project-name mypeugeot .
flutter pub get
```

## Configuration de l'URL du backend

L'URL du backend (`backend/` du dépôt, déployé sur ton Raspberry Pi/serveur) est à renseigner dans `lib/services/api_service.dart` (constante `baseUrl`), ou à passer au build via `--dart-define=API_BASE_URL=https://mon-backend:5000`.

Le service d'alertes mouvement/géofencing (`backend/alert_watcher`, port `5050`) est séparé de `psa_car_controller` (port `5000`) : son URL se configure via `--dart-define=ALERTS_BASE_URL=http://<ip-backend>:5050`.

## Lancer l'app

```bash
flutter run \
  --dart-define=API_BASE_URL=http://<ip-backend>:5000 \
  --dart-define=ALERTS_BASE_URL=http://<ip-backend>:5050
```

## Structure

```
lib/
  main.dart                          # point d'entrée
  app.dart                           # MaterialApp + thème
  theme/
    app_theme.dart                   # palette jaune/noir + ThemeData
  models/
    vehicle_status.dart              # statut véhicule (batterie, verrouillage, charge)
    trip.dart                        # trajet (distance, conso, coût)
  services/
    api_service.dart                 # client HTTP vers le backend
  screens/
    login_screen.dart                # stub d'écran de connexion
    home_shell.dart                  # bottom nav (Accueil/Trajets/Charge/Alertes)
    dashboard_screen.dart            # vue équilibrée : hero voiture + statut + actions
    trips_screen.dart                # historique trajets + conso/coûts
    charge_schedule_screen.dart      # seuil de charge + heures creuses (stub)
    alerts_screen.dart               # alerte mouvement + zones géofencing (stub)
  widgets/
    battery_gauge.dart               # jauge de batterie réutilisable
    car_hero.dart                    # illustration stylisée de la e-208 (CustomPainter, pas une photo)
```

## État actuel

Écrans et service API sont des stubs fonctionnels avec des données simulées (`ApiService` en mode mock) pour développer l'UI avant que le backend soit branché. Validé avec `flutter analyze` et `flutter test` (aucune erreur, quelques infos de dépréciation mineures sur `withOpacity`).

Prochaine étape : brancher `ApiService` sur les vraies routes exposées par `psa_car_controller` (voir `backend/README.md`), notamment pour les trajets, la programmation de charge et les alertes qui sont encore 100% côté client.
