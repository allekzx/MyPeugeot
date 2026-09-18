import importlib
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))

from geofence import haversine_m, is_inside  # noqa: E402
from state import build_current_state, detect_events, parse_vehicle_state  # noqa: E402

HOME = {"name": "Domicile", "lat": 45.0, "lon": 6.0, "radius_m": 200, "enabled": True}


class GeofenceTest(unittest.TestCase):
    def test_haversine_zero_distance(self):
        self.assertAlmostEqual(haversine_m(45.0, 6.0, 45.0, 6.0), 0.0, places=3)

    def test_haversine_known_distance(self):
        # ~111.2 km pour 1 degré de latitude à l'équateur.
        d = haversine_m(0.0, 0.0, 1.0, 0.0)
        self.assertAlmostEqual(d, 111195, delta=200)

    def test_is_inside_true_within_radius(self):
        self.assertTrue(is_inside(45.0005, 6.0005, HOME))

    def test_is_inside_false_outside_radius(self):
        self.assertFalse(is_inside(45.1, 6.1, HOME))


class ParseVehicleStateTest(unittest.TestCase):
    def test_stop_is_not_moving(self):
        ignition_on, lat, lon = parse_vehicle_state({"ignition": {"type": "Stop"}})
        self.assertFalse(ignition_on)

    def test_other_type_is_moving(self):
        ignition_on, _, _ = parse_vehicle_state({"ignition": {"type": "Start"}})
        self.assertTrue(ignition_on)

    def test_missing_ignition_is_not_moving(self):
        ignition_on, _, _ = parse_vehicle_state({})
        self.assertFalse(ignition_on)

    def test_position_parsed_from_geojson(self):
        payload = {
            "last_position": {
                "geometry": {"coordinates": [2.2945, 48.8584, 35.0]},
            }
        }
        _, lat, lon = parse_vehicle_state(payload)
        self.assertEqual(lon, 2.2945)
        self.assertEqual(lat, 48.8584)

    def test_missing_position(self):
        _, lat, lon = parse_vehicle_state({})
        self.assertIsNone(lat)
        self.assertIsNone(lon)


class DetectEventsTest(unittest.TestCase):
    def test_no_event_on_first_ever_reading(self):
        previous = {"known": False, "ignition_on": None, "lat": None, "lon": None, "zones": {}}
        current = build_current_state(True, 45.0, 6.0, [HOME])
        events = detect_events(previous, current, [HOME])
        self.assertEqual(events, [])

    def test_movement_alert_on_ignition_start(self):
        previous = build_current_state(False, 45.0, 6.0, [HOME])
        current = build_current_state(True, 45.0, 6.0, [HOME])
        events = detect_events(previous, current, [HOME])
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["type"], "movement")

    def test_no_movement_alert_when_disabled(self):
        previous = build_current_state(False, 45.0, 6.0, [HOME])
        current = build_current_state(True, 45.0, 6.0, [HOME])
        events = detect_events(previous, current, [HOME], movement_alert_enabled=False)
        self.assertEqual(events, [])

    def test_no_movement_alert_when_already_on(self):
        previous = build_current_state(True, 45.0, 6.0, [HOME])
        current = build_current_state(True, 45.0, 6.0, [HOME])
        events = detect_events(previous, current, [HOME])
        self.assertEqual(events, [])

    def test_geofence_exit_alert(self):
        previous = build_current_state(True, 45.0, 6.0, [HOME])  # dans la zone
        current = build_current_state(True, 45.1, 6.1, [HOME])  # loin de la zone
        events = detect_events(previous, current, [HOME])
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["type"], "geofence")
        self.assertIn("quitté", events[0]["message"])

    def test_geofence_enter_alert(self):
        previous = build_current_state(True, 45.1, 6.1, [HOME])  # loin
        current = build_current_state(True, 45.0, 6.0, [HOME])  # dans la zone
        events = detect_events(previous, current, [HOME])
        self.assertEqual(len(events), 1)
        self.assertIn("entrée", events[0]["message"])

    def test_disabled_zone_produces_no_event(self):
        disabled = {**HOME, "enabled": False}
        previous = build_current_state(True, 45.0, 6.0, [disabled])
        current = build_current_state(True, 45.1, 6.1, [disabled])
        events = detect_events(previous, current, [disabled])
        self.assertEqual(events, [])

    def test_multiple_zones_independent(self):
        work = {"name": "Travail", "lat": 46.0, "lon": 7.0, "radius_m": 200, "enabled": True}
        zones = [HOME, work]
        previous = build_current_state(True, 45.0, 6.0, zones)  # dans Domicile seulement
        current = build_current_state(True, 46.0, 7.0, zones)  # dans Travail seulement
        events = detect_events(previous, current, zones)
        types = sorted(e["message"] for e in events)
        self.assertEqual(len(events), 2)
        self.assertTrue(any("quitté la zone « Domicile »" in m for m in types))
        self.assertTrue(any("entrée dans la zone « Travail »" in m for m in types))


class AppEndpointsTest(unittest.TestCase):
    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        os.environ["ALERT_CONFIG_PATH"] = os.path.join(self._tmpdir.name, "settings.json")
        os.environ["ALERT_STATE_PATH"] = os.path.join(self._tmpdir.name, "state.json")
        os.environ["VIN"] = "TESTVIN"
        if "app" in sys.modules:
            del sys.modules["app"]
        self.app_module = importlib.import_module("app")
        self.client = self.app_module.app.test_client()

    def tearDown(self):
        self._tmpdir.cleanup()

    def test_health(self):
        resp = self.client.get("/health")
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.get_json()["vin_configured"])

    def test_settings_default_then_update(self):
        resp = self.client.get("/settings")
        self.assertEqual(resp.get_json()["movement_alert_enabled"], True)

        resp = self.client.put("/settings", json={"movement_alert_enabled": False, "ntfy_topic": "mon-topic"})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["movement_alert_enabled"], False)
        self.assertEqual(resp.get_json()["ntfy_topic"], "mon-topic")

    def test_add_zone_requires_known_position(self):
        resp = self.client.post("/zones", json={"name": "Domicile", "radius_m": 250})
        self.assertEqual(resp.status_code, 409)

    def test_add_zone_uses_last_known_position(self):
        with open(os.environ["ALERT_STATE_PATH"], "w", encoding="utf-8") as f:
            json.dump({"known": True, "ignition_on": False, "lat": 45.2, "lon": 6.6, "zones": {}}, f)

        resp = self.client.post("/zones", json={"name": "Domicile", "radius_m": 250})
        self.assertEqual(resp.status_code, 201)
        zones = resp.get_json()
        self.assertEqual(len(zones), 1)
        self.assertEqual(zones[0]["lat"], 45.2)
        self.assertEqual(zones[0]["lon"], 6.6)
        self.assertEqual(zones[0]["radius_m"], 250)
        self.assertTrue(zones[0]["enabled"])

    def test_duplicate_zone_name_rejected(self):
        with open(os.environ["ALERT_STATE_PATH"], "w", encoding="utf-8") as f:
            json.dump({"known": True, "ignition_on": False, "lat": 45.2, "lon": 6.6, "zones": {}}, f)
        self.client.post("/zones", json={"name": "Domicile", "radius_m": 250})
        resp = self.client.post("/zones", json={"name": "Domicile", "radius_m": 100})
        self.assertEqual(resp.status_code, 409)

    def test_update_and_delete_zone(self):
        with open(os.environ["ALERT_STATE_PATH"], "w", encoding="utf-8") as f:
            json.dump({"known": True, "ignition_on": False, "lat": 45.2, "lon": 6.6, "zones": {}}, f)
        self.client.post("/zones", json={"name": "Domicile", "radius_m": 250})

        resp = self.client.put("/zones/Domicile", json={"enabled": False, "radius_m": 400})
        self.assertEqual(resp.status_code, 200)
        zones = resp.get_json()
        self.assertFalse(zones[0]["enabled"])
        self.assertEqual(zones[0]["radius_m"], 400)

        resp = self.client.delete("/zones/Domicile")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json(), [])

    def test_update_unknown_zone_404(self):
        resp = self.client.put("/zones/Inconnue", json={"enabled": False})
        self.assertEqual(resp.status_code, 404)


if __name__ == "__main__":
    unittest.main()
