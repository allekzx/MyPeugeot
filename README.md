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

## Fonctionnalités

### MVP (implémenté en stub, données simulées)

1. Connexion via compte PSA (login backend, session dans l'app)
2. Dashboard : niveau de batterie, autonomie, statut verrouillage/charge
3. Verrouillage / déverrouillage à distance
4. Contrôle de charge (start/stop)
5. Préconditionnement thermique (chauffage/clim avant départ)

### v2 (implémenté en stub, à brancher sur le backend)

6. Historique de trajets + conso/coûts estimés
7. Programmation de charge intelligente (seuil cible, heures creuses)
8. Alertes / géofencing (mouvement suspect, zones domicile/travail)

### Plus tard

9. Notifications push (fin de charge, batterie faible)
10. Widget écran d'accueil / raccourcis Siri / Google Assistant
11. Localisation en direct sur carte (actuellement pas de carte, juste l'historique de trajets)

## Look de l'app

Thème sombre, jaune/noir en clin d'œil à la teinte de la e-208 (illustration originale de la voiture en `CustomPainter`, pas de photo ni de logo tiers). Écran d'accueil en vue équilibrée : visuel de la voiture en haut, puis une grille de cartes de même poids (batterie, verrouillage, charge, dernière mise à jour), actions rapides en dessous. Navigation par onglets : Accueil / Trajets / Charge / Alertes.

## Démarrage rapide

### 1. Backend

```bash
cd backend
cp .env.example .env   # à adapter si besoin
docker compose up -d
```

Puis ouvrir `http://localhost:5000` pour terminer la configuration (connexion à ton compte PSA/Stellantis), comme décrit dans le [README de psa_car_controller](https://github.com/flobz/psa_car_controller). Voir `backend/README.md` pour le détail.

### 2. App mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<ip-backend>:5000
```

`android/` et `ios/` sont déjà générés et versionnés dans le dépôt. Voir `mobile/README.md` pour le détail de la structure et de la configuration.

## Prochaines étapes

- [ ] Valider le déploiement du backend et récupérer le VIN + un premier statut véhicule
- [ ] Confirmer les routes exposées par la version de `psa_car_controller` déployée (`api_spec.md` du projet) et ajuster `mobile/lib/services/api_service.dart` en conséquence (statut, actions, trajets)
- [ ] Brancher la programmation de charge et les alertes/géofencing sur le backend (actuellement 100% côté client)
- [ ] Écran de connexion réel (au lieu du stub) relié au backend
- [ ] Notifications push (Firebase Cloud Messaging)
- [ ] Tester sur simulateur/téléphone réel (non fait dans cet environnement distant, pas d'émulateur disponible)
