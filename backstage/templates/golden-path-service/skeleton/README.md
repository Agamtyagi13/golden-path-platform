# ${{ values.name }}

${{ values.description }}

Created from the **Golden Path - Python Microservice** template.

| | |
|---|---|
| Owner | `${{ values.owner }}` |
| System | `${{ values.system }}` |
| Environment | `${{ values.environment }}` (namespace `${{ values.name }}-${{ values.environment }}`) |

## Develop

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
pytest
PORT=${{ values.port }} gunicorn -b 0.0.0.0:${{ values.port }} app.main:app
```

## What the pipeline does (`.github/workflows/ci.yml`)

1. Unit tests (pytest)
2. Render the Helm chart, run `helm lint`, and check it against OPA policies (`policy/`) with Conftest
3. Build the image, scan with Trivy (fails on HIGH/CRITICAL), push to GHCR on `main`
4. Deploy with Helm to `${{ values.name }}-${{ values.environment }}` (needs the `KUBECONFIG_B64` secret)

The cluster independently enforces the same rules with Kyverno, so a manifest that skips CI is still rejected.
