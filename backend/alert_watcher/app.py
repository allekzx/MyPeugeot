"""Service compagnon de `psa_car_controller` : détecte le démarrage du
véhicule et les entrées/sorties de zones géofencées, puis pousse une
notification via ntfy.sh (gratuit, sans compte).

Tourne en continu sur le même serveur (VM/Raspberry) que
`psa_car_controller`, car c'est le seul endroit qui peut vraiment
surveiller la voiture même quand le téléphone est éteint ou l'app fermée —
un simple polling depuis l'app mobile ne serait pas fiable en arrière-plan,
surtout sur iOS.
"""
import os
import threading
import time

import requests
from flask import Flask, jsonify, request

from state import build_current_state, detect_events, parse_vehicle_state
from storage import DEFAULT_SETTINGS, DEFAULT_STATE, load_json, save_json

CONFIG_PATH = os.environ.get("ALERT_CONFIG_PATH", "/config/alert_settings.json")
STATE_PATH = os.environ.get("ALERT_STATE_PATH", "/config/alert_state.json")
PSACC_URL = os.environ.get("PSACC_URL", "http://psa_car_controller:5000")
VIN = os.environ.get("VIN", "")
POLL_SECONDS = int(os.environ.get("ALERT_POLL_SECONDS", "180"))

app = Flask(__name__)
_lock = threading.Lock()

SETTINGS_FIELDS = ("movement_alert_enabled", "ntfy_topic")
ZONE_FIELDS = ("lat", "lon", "radius_m", "enabled")


@app.get("/health")
def health():
    return jsonify({"ok": True, "vin_configured": bool(VIN)})


@app.get("/settings")
def get_settings():
    with _lock:
        settings = load_json(CONFIG_PATH, DEFAULT_SETTINGS)
    return jsonify({k: settings.get(k) for k in SETTINGS_FIELDS})


@app.put("/settings")
def put_settings():
    body = request.get_json(force=True, silent=True) or {}
    with _lock:
        settings = load_json(CONFIG_PATH, DEFAULT_SETTINGS)
        for key in SETTINGS_FIELDS:
            if key in body:
                settings[key] = body[key]
        save_json(CONFIG_PATH, settings)
    return jsonify({k: settings.get(k) for k in SETTINGS_FIELDS})


@app.get("/zones")
def get_zones():
    with _lock:
        settings = load_json(CONFIG_PATH, DEFAULT_SETTINGS)
    return jsonify(settings.get("zones", []))


@app.post("/zones")
def add_zone():
    """Crée une zone centrée sur la position *actuellement connue* de la
    voiture (pas de sélecteur de carte côté app : on utilise la dernière
    position reçue, ex: juste après s'être garé)."""
    body = request.get_json(force=True, silent=True) or {}
    name = (body.get("name") or "").strip()
    radius_m = body.get("radius_m", 300)
    if not name:
        return jsonify({"error": "name requis"}), 400

    with _lock:
        state = load_json(STATE_PATH, DEFAULT_STATE)
        if state.get("lat") is None or state.get("lon") is None:
            return jsonify({
                "error": "Position de la voiture pas encore connue. Réessaie dans quelques minutes "
                         "(le service doit d'abord recevoir un premier statut)."
            }), 409

        settings = load_json(CONFIG_PATH, DEFAULT_SETTINGS)
        zones = settings.setdefault("zones", [])
        if any(z["name"] == name for z in zones):
            return jsonify({"error": "Une zone porte déjà ce nom."}), 409

        zones.append({
            "name": name,
            "lat": state["lat"],
            "lon": state["lon"],
            "radius_m": radius_m,
            "enabled": True,
        })
        save_json(CONFIG_PATH, settings)
    return jsonify(zones), 201


@app.put("/zones/<name>")
def update_zone(name):
    body = request.get_json(force=True, silent=True) or {}
    with _lock:
        settings = load_json(CONFIG_PATH, DEFAULT_SETTINGS)
        zones = settings.setdefault("zones", [])
        zone = next((z for z in zones if z["name"] == name), None)
        if zone is None:
            return jsonify({"error": "zone inconnue"}), 404
        for key in ZONE_FIELDS:
            if key in body:
                zone[key] = body[key]
        save_json(CONFIG_PATH, settings)
    return jsonify(zones)


@app.delete("/zones/<name>")
def delete_zone(name):
    with _lock:
        settings = load_json(CONFIG_PATH, DEFAULT_SETTINGS)
        zones = settings.setdefault("zones", [])
        settings["zones"] = [z for z in zones if z["name"] != name]
        save_json(CONFIG_PATH, settings)
    return jsonify(settings["zones"])


def send_notification(topic, message):
    if not topic:
        return
    try:
        requests.post(f"https://ntfy.sh/{topic}", data=message.encode("utf-8"), timeout=10)
    except requests.RequestException:
        pass  # pas de connectivité momentanée : on retentera au prochain événement


def poll_once(previous):
    """Un cycle de sondage. Renvoie le nouveau `previous` à conserver."""
    if not VIN:
        return previous

    response = requests.get(f"{PSACC_URL}/get_vehicleinfo/{VIN}?from_cache=1", timeout=15)
    if response.status_code != 200:
        return previous

    with _lock:
        settings = load_json(CONFIG_PATH, DEFAULT_SETTINGS)
    zones = settings.get("zones", [])

    ignition_on, lat, lon = parse_vehicle_state(response.json())
    current = build_current_state(ignition_on, lat, lon, zones)
    events = detect_events(previous, current, zones, settings.get("movement_alert_enabled", True))

    for event in events:
        send_notification(settings.get("ntfy_topic", ""), event["message"])

    with _lock:
        save_json(STATE_PATH, current)
    return current


def poll_loop():
    previous = load_json(STATE_PATH, DEFAULT_STATE)
    while True:
        try:
            previous = poll_once(previous)
        except requests.RequestException:
            pass  # psa_car_controller pas encore prêt / momentanément injoignable
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    threading.Thread(target=poll_loop, daemon=True).start()
    app.run(host="0.0.0.0", port=5050)
