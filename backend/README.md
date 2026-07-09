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

## Où l'héberger en continu (gratuit) : Google Cloud Free Tier

Pour ne pas dépendre d'un PC qui doit rester allumé : une VM **`e2-micro`** sur Google Cloud, gratuite en permanence (pas un essai limité dans le temps).

Limites de l'offre gratuite à connaître :
- Une seule instance `e2-micro` gratuite par compte de facturation, uniquement dans les régions `us-west1`, `us-central1` ou `us-east1` (ailleurs = facturé).
- 1 vCPU partagé / 1 Go RAM, 30 Go de disque, 1 Go de trafic sortant/mois hors Amérique du Nord (largement suffisant pour du polling d'API perso).
- 1 Go de RAM est juste pour Docker + `psa_car_controller` : on ajoute un fichier de swap ci-dessous pour éviter tout plantage par manque de mémoire.

### 1. Créer la VM
1. Créer un compte sur [cloud.google.com](https://cloud.google.com/free) (carte bancaire demandée pour vérification, rien n'est facturé sur l'offre gratuite tant que tu restes sur `e2-micro` dans une région éligible).
2. Créer une instance **`e2-micro`**, région `us-central1` (ou `us-west1`/`us-east1`), image Ubuntu.
3. Ouvrir le port 22 (SSH) le temps de la config ; ne pas ouvrir le port 5000 publiquement (voir Tailscale ci-dessous).

### 2. Ajouter un fichier de swap (recommandé vu le peu de RAM)
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 3. Installer Docker + Tailscale sur la VM
```bash
curl -fsSL https://get.docker.com | sh
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```
Connecte aussi ton téléphone (et éventuellement ton PC) au même réseau Tailscale (app officielle iOS/Android). Comme ça, seuls tes appareils peuvent atteindre la VM — jamais exposée sur Internet public, pas besoin d'authentification supplémentaire devant l'API.

### 4. Déployer le backend
```bash
git clone -b claude/mypeugeot-replacement-app-bv7ct4 https://github.com/allekzx/mypeugeot.git
cd mypeugeot/backend
cp .env.example .env
docker compose up -d
```
Puis refaire la configuration PSA (étape "Configuration initiale" ci-dessus) : elle est propre à cette machine, elle ne se transfère pas automatiquement depuis un précédent test.

### 5. Configurer l'app mobile
Récupère l'IP Tailscale de la VM (`tailscale ip -4` sur la VM), puis lance l'app avec :
```bash
flutter run --dart-define=API_BASE_URL=http://100.x.x.x:5000
```

### Alternatives
- **Raspberry Pi/NAS à la maison** + Tailscale : même principe, si tu préfères un jour garder la main sur du matériel physique plutôt que sur une offre cloud gratuite (qui reste une offre commerciale réversible).
- **VPS payant exposé en HTTPS** : viable mais nécessite un reverse proxy + authentification devant l'API pour ne pas laisser le contrôle de la voiture ouvert à tous — Tailscale évite ce problème par design.

## Notes

- Le dossier `config/` (créé au premier lancement) contient les secrets PSA et les tokens de session : ne pas le committer. Il est déjà exclu via `.gitignore`.
- Les routes exactes de l'API REST exposée peuvent varier selon la version de `psa_car_controller` : se référer à `api_spec.md` dans ce projet pour la version déployée, et ajuster `mobile/lib/services/api_service.dart` en conséquence.
