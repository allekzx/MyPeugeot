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

## Où l'héberger en continu (gratuit)

Pour ne pas dépendre d'un PC/Pi qui doit rester allumé, la meilleure option gratuite et pérenne (pas un essai limité) est une VM **Oracle Cloud "Always Free"** :

### 1. Créer la VM
1. Créer un compte sur [cloud.oracle.com](https://cloud.oracle.com) (carte bancaire demandée pour vérification, rien n'est facturé sur l'offre Always Free).
2. Créer une instance **Ampere A1 (ARM)** — l'offre gratuite couvre jusqu'à 4 OCPU / 24 Go RAM au total ; 1 OCPU / 6 Go suffit largement pour ce service. Choisir une image Ubuntu.
   - Si la capacité ARM n'est pas disponible dans ta région (fréquent), alternative gratuite : instance `e2-micro` sur Google Cloud (gratuite en permanence, hors ARM).
3. Ouvrir le port 22 (SSH) le temps de la config ; ne pas ouvrir le port 5000 publiquement (voir Tailscale ci-dessous).

### 2. Installer Docker + Tailscale sur la VM
```bash
curl -fsSL https://get.docker.com | sh
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```
Connecte aussi ton téléphone (et éventuellement ton PC) au même réseau Tailscale (app officielle iOS/Android). Comme ça, seuls tes appareils peuvent atteindre la VM — jamais exposée sur Internet public, pas besoin d'authentification supplémentaire devant l'API.

### 3. Déployer le backend
```bash
git clone -b claude/mypeugeot-replacement-app-bv7ct4 https://github.com/allekzx/mypeugeot.git
cd mypeugeot/backend
cp .env.example .env
docker compose up -d
```

### 4. Configurer l'app mobile
Récupère l'IP Tailscale de la VM (`tailscale ip -4` sur la VM), puis lance l'app avec :
```bash
flutter run --dart-define=API_BASE_URL=http://100.x.x.x:5000
```

### Alternatives
- **Raspberry Pi/NAS à la maison** + Tailscale : même principe, si tu préfères garder la main sur le matériel.
- **VPS payant exposé en HTTPS** : viable mais nécessite un reverse proxy + authentification devant l'API pour ne pas laisser le contrôle de la voiture ouvert à tous — Tailscale évite ce problème par design.

## Notes

- Le dossier `config/` (créé au premier lancement) contient les secrets PSA et les tokens de session : ne pas le committer. Il est déjà exclu via `.gitignore`.
- Les routes exactes de l'API REST exposée peuvent varier selon la version de `psa_car_controller` : se référer à `api_spec.md` dans ce projet pour la version déployée, et ajuster `mobile/lib/services/api_service.dart` en conséquence.
