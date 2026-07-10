"""Persistance JSON très simple (fichiers locaux, un seul véhicule/foyer :
pas besoin d'une vraie base de données)."""
import json
import os

DEFAULT_SETTINGS = {"movement_alert_enabled": True, "ntfy_topic": "", "zones": []}
DEFAULT_STATE = {"known": False, "ignition_on": None, "lat": None, "lon": None, "zones": {}}


def load_json(path, default):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return json.loads(json.dumps(default))  # copie profonde


def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp_path = f"{path}.tmp"
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    os.replace(tmp_path, path)
