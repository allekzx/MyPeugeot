# MyPeugeot (remplacement)

Application mobile personnelle pour remplacer/améliorer l'app MyPeugeot pour une Peugeot e-208, avec un backend auto-hébergé qui s'appuie sur le projet open-source [psa_car_controller](https://github.com/flobz/psa_car_controller) pour parler à l'API PSA/Stellantis (login PSA, état véhicule, verrouillage, charge, préconditionnement).

## Architecture

```
+----------------+        HTTPS/REST        +--------------------------+        API PSA officielle
|  App Flutter   |  <-------------------->  |  psa_car_controller       |  <-------------------->  Stellantis
|  (iOS/Android) |                          |  (Docker, backend/)       |
+----------------+                          +--------------------------+
```

- **`backend/`** : `docker-compose.yml` qui lance l'image `flobz/psa_car_controller`. Ce service gère l'authentification OAuth PSA (le client_id/secret ne doit jamais être dans l'app mobile) et expose une API REST + dashboard web sur le port 5000.
- **`mobile/`** : app Flutter (iOS + Android) qui consomme cette API REST pour afficher l'état du véhicule et déclencher des actions.

## Pourquoi cette approche

MyPeugeot ne communique pas en direct avec la voiture : tout passe par le cloud Stellantis. `psa_car_controller` a déjà fait le travail de reverse engineering de cette API (auth, endpoints véhicule) et est activement maintenu, donc on construit par-dessus plutôt que de tout refaire.

⚠️ Usage strictement personnel : l'API PSA utilisée n'est pas publique/officiellement supportée pour ce type d'usage, elle peut changer sans préavis.

## Fonctionnalités visées (MVP puis extensions)

1. Connexion via compte PSA (login backend, session dans l'app)
2. Dashboard : niveau de batterie, autonomie, statut portes/fenêtres
3. Verrouillage / déverrouillage à distance
4. Contrôle de charge (start/stop, seuil de charge)
5. Préconditionnement thermique (chauffage/clim avant départ)
6. Localisation du véhicule + historique de trajets
7. Notifications push (fin de charge, batterie faible)
8. Widget écran d'accueil (extension future)

## Démarrage rapide

### 1. Backend

```bash
cd backend
cp .env.example .env   # à adapter si besoin
docker compose up -d
```

Puis ouvrir `http://localhost:5000` pour terminer la configuration (connexion à ton compte PSA/Stellantis), comme décrit dans le [README de psa_car_controller](https://github.com/flobz/psa_car_controller). Voir `backend/README.md` pour le détail.

### 2. App mobile

Le SDK Flutter n'est pas disponible dans cet environnement de développement à distance, donc ce dépôt contient uniquement le **code source** (`mobile/lib/`, `mobile/pubspec.yaml`) et pas les dossiers de plateforme générés (`android/`, `ios/`). Sur ta machine avec Flutter installé :

```bash
cd mobile
flutter create --project-name mypeugeot .   # génère android/ ios/ sans toucher à lib/ existant
flutter pub get
flutter run
```

Voir `mobile/README.md` pour le détail et la configuration de l'URL du backend.

## Prochaines étapes

- [ ] Valider le déploiement du backend et récupérer le VIN + un premier statut véhicule
- [ ] Confirmer les routes exposées par la version de `psa_car_controller` déployée (`api_spec.md` du projet) et ajuster `mobile/lib/services/api_service.dart` en conséquence
- [ ] Générer les dossiers de plateforme Flutter (`flutter create .`) et lancer l'app sur un simulateur/téléphone
- [ ] Écran de connexion réel (au lieu du stub) relié au backend
- [ ] Notifications push (Firebase Cloud Messaging)
