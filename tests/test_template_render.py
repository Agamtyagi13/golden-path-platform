"""Tests for the Backstage template and the service it generates."""
import pathlib, re, subprocess, sys

import pytest
import yaml

import render_skeleton as rs

ROOT = pathlib.Path(__file__).resolve().parent.parent
TPL = ROOT / "backstage" / "templates" / "golden-path-service" / "template.yaml"


@pytest.fixture(scope="module")
def rendered(tmp_path_factory):
    out = tmp_path_factory.mktemp("render")
    rs.render(out)
    return out


def test_template_is_valid_backstage_template():
    t = yaml.safe_load(TPL.read_text())
    assert t["kind"] == "Template" and t["apiVersion"] == "scaffolder.backstage.io/v1beta3"
    actions = [s["action"] for s in t["spec"]["steps"]]
    assert actions == ["fetch:template", "publish:github", "catalog:register",
                       "fetch:template", "publish:github:pull-request"]
    ids = [s["id"] for s in t["spec"]["steps"]]
    assert len(ids) == len(set(ids))


def test_template_parameters_have_guardrails():
    t = yaml.safe_load(TPL.read_text())
    props = {}
    for page in t["spec"]["parameters"]:
        props.update(page["properties"])
    assert re.fullmatch(props["name"]["pattern"], "orders-api")
    assert not re.fullmatch(props["name"]["pattern"], "Orders_API")
    assert props["environment"]["enum"] == ["dev", "staging", "prod"]
    assert re.fullmatch(props["costCenter"]["pattern"], "ENG-1042")
    assert not re.fullmatch(props["costCenter"]["pattern"], "whatever")


def test_every_template_value_is_supplied_by_a_step():
    """Every ${{ values.x }} used in files must be passed in the matching fetch:template step."""
    t = yaml.safe_load(TPL.read_text())
    steps = [s for s in t["spec"]["steps"] if s["action"] == "fetch:template"]
    for step in steps:
        supplied = set(step["input"]["values"])
        base = TPL.parent / step["input"]["url"]
        used = set()
        for f in base.rglob("*"):
            if f.is_file():
                used |= set(rs.VAR.findall(f.read_text())) | set(rs.VAR.findall(f.name))
        # workflow/chart templates are copied raw, so skip them
        for f in (base / ".github").rglob("*") if (base / ".github").exists() else []:
            pass
        missing = used - supplied
        assert not missing, f"{step['id']}: values used but not supplied: {missing}"


def test_no_unrendered_placeholders_left(rendered):
    for f in (rendered / "service").rglob("*"):
        if f.is_file() and ".github/workflows" not in f.as_posix() and "chart/templates" not in f.as_posix():
            assert "${{ values" not in f.read_text(), f


def test_github_actions_and_helm_syntax_preserved(rendered):
    ci = (rendered / "service/.github/workflows/ci.yml").read_text()
    assert "${{ github.sha }}" in ci and "${{ secrets.GITHUB_TOKEN }}" in ci
    dep = (rendered / "service/chart/templates/deployment.yaml").read_text()
    assert '{{ include "svc.name" . }}' in dep


def test_catalog_info_has_ownership_metadata(rendered):
    ci = yaml.safe_load((rendered / "service/catalog-info.yaml").read_text())
    assert ci["kind"] == "Component"
    assert ci["spec"]["owner"] == "group:default/payments-team"
    assert ci["spec"]["system"] == "payments"
    assert ci["metadata"]["annotations"]["github.com/project-slug"] == "acme/hello-svc"
    assert ci["metadata"]["annotations"]["backstage.io/kubernetes-namespace"] == "hello-svc-dev"


def test_chart_metadata_and_values_parse(rendered):
    chart = yaml.safe_load((rendered / "service/chart/Chart.yaml").read_text())
    vals = yaml.safe_load((rendered / "service/chart/values.yaml").read_text())
    assert chart["name"] == "hello-svc"
    assert vals["owner"] == "payments-team" and vals["image"]["tag"] != "latest"
    assert vals["resources"]["limits"]["memory"]


def test_tenant_request_matches_terraform_schema(rendered):
    files = list((rendered / "tenant-out/tenants").glob("*.yaml"))
    assert [f.name for f in files] == ["hello-svc-dev.yaml"]
    t = yaml.safe_load(files[0].read_text())
    assert set(t) == {"name", "environment", "owner", "tier", "cost_center"}


def test_generated_service_unit_tests_pass(rendered):
    r = subprocess.run([sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider"],
                       cwd=rendered / "service", capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr


def test_opa_policy_copy_in_skeleton_is_in_sync():
    a = (ROOT / "policies/opa/deployment.rego").read_text()
    b = (TPL.parent / "skeleton/policy/deployment.rego").read_text()
    assert a == b, "run: cp policies/opa/deployment.rego backstage/templates/golden-path-service/skeleton/policy/"


@pytest.mark.parametrize("path", sorted((ROOT / "tenants").glob("*.yaml")))
def test_committed_tenants_are_valid(path):
    t = yaml.safe_load(path.read_text())
    assert re.fullmatch(r"[a-z][a-z0-9-]{2,29}", t["name"])
    assert t["environment"] in {"dev", "staging", "prod"}
    assert t["tier"] in {"small", "medium", "large"}
    assert not (t["environment"] == "dev" and t["tier"] == "large"), "guardrail: no large tier in dev"
    assert path.stem == f"{t['name']}-{t['environment']}"
