# Backend

Wrapper Docker autour de [flobz/psa_car_controller](https://github.com/flobz/psa_car_controller), qui gère l'authentification PSA/Stellantis et expose l'API REST + un dashboard web consommés par l'app mobile.

## Lancer le backend

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f   # vérifier que le service démarre correctement
```

## Configuration initiale (une seule fois)

1. Ouvrir `http://<ip-du-serveur>:5000` dans un navigateur.
2. Suivre les instructions du projet `psa_car_controller` pour créer une app développeur PSA (client_id/client_secret) et se connecter avec ton compte PSA/Stellantis. Ces identifiants sont stockés uniquement côté serveur, dans `backend/config/` (jamais dans l'app mobile).
3. Une fois configuré, récupérer le VIN de ta e-208 depuis le dashboard : c'est l'identifiant utilisé pour les appels à l'API véhicule.

## Où l'héberger

Pour un usage perso, une petite machine tournant en continu suffit : Raspberry Pi à la maison, mini-PC, ou VM cloud gratuite/à faible coût (ex: Oracle Cloud Free Tier, Fly.io). Le service est léger (un conteneur Docker).

## Notes

- Le dossier `config/` (créé au premier lancement) contient les secrets PSA et les tokens de session : ne pas le committer. Il est déjà exclu via `.gitignore`.
- Les routes exactes de l'API REST exposée peuvent varier selon la version de `psa_car_controller` : se référer à `api_spec.md` dans ce projet pour la version déployée, et ajuster `mobile/lib/services/api_service.dart` en conséquence.
