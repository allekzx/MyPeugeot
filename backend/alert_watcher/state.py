"""Détection de transitions (mouvement / entrée-sortie de zone) à partir de
deux snapshots successifs du statut véhicule. Logique pure, sans I/O, pour
rester testable sans backend ni réseau.
"""
from geofence import is_inside


def parse_vehicle_state(vehicleinfo_json):
    """Extrait (ignition_on, lat, lon) d'une réponse `get_vehicleinfo`.

    `ignition.type` vaut `"Stop"` à l'arrêt (confirmé sur une e-208 réelle) ;
    on considère toute autre valeur connue comme "en mouvement" — l'API PSA
    ne documente pas la liste exhaustive des valeurs, donc c'est une
    heuristique volontairement large plutôt qu'une liste figée de valeurs
    "on" qui pourrait manquer un cas réel.
    """
    ignition_type = (vehicleinfo_json.get("ignition") or {}).get("type")
    ignition_on = ignition_type is not None and ignition_type != "Stop"

    position = vehicleinfo_json.get("last_position") or {}
    geometry = position.get("geometry") or {}
    coordinates = geometry.get("coordinates") or []
    lon = coordinates[0] if len(coordinates) > 0 else None
    lat = coordinates[1] if len(coordinates) > 1 else None
    return ignition_on, lat, lon


def build_current_state(ignition_on, lat, lon, zones):
    zones_state = {}
    if lat is not None and lon is not None:
        for zone in zones:
            zones_state[zone["name"]] = is_inside(lat, lon, zone)
    return {"known": True, "ignition_on": ignition_on, "lat": lat, "lon": lon, "zones": zones_state}


def detect_events(previous, current, zones, movement_alert_enabled=True):
    """Compare deux snapshots et renvoie la liste des événements à notifier.

    Aucun événement n'est émis au tout premier passage (`previous["known"]`
    faux) : on n'a pas encore de référence pour dire qu'il y a eu un
    changement.
    """
    events = []
    if not previous.get("known"):
        return events

    if movement_alert_enabled:
        prev_ignition = previous.get("ignition_on")
        cur_ignition = current.get("ignition_on")
        if prev_ignition is False and cur_ignition is True:
            events.append({"type": "movement", "message": "La voiture vient de démarrer."})

    zone_by_name = {zone["name"]: zone for zone in zones}
    prev_zones = previous.get("zones", {})
    cur_zones = current.get("zones", {})
    for name, inside_now in cur_zones.items():
        zone = zone_by_name.get(name)
        if zone is not None and not zone.get("enabled", True):
            continue
        was_inside = prev_zones.get(name)
        if was_inside is not None and was_inside != inside_now:
            verb = "est entrée dans la zone" if inside_now else "a quitté la zone"
            events.append({"type": "geofence", "message": f"La voiture {verb} « {name} »."})

    return events
