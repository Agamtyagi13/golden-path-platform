from app.main import create_app


def client():
    return create_app().test_client()


def test_index():
    r = client().get("/")
    assert r.status_code == 200
    assert r.get_json()["service"] == "${{ values.name }}"


def test_health_endpoints():
    c = client()
    assert c.get("/healthz").status_code == 200
    assert c.get("/readyz").status_code == 200
