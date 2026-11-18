#!/usr/bin/env python3
"""Render the Backstage template locally (no Backstage needed) so CI can test what developers will get.

Mimics fetch:template for the subset of syntax we use: ${{ values.<key> }}.
copyWithoutRender globs are read from template.yaml (single source of truth).

Usage: render_skeleton.py OUT_DIR [key=value ...]
"""
import fnmatch, pathlib, re, sys
import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
TPL_DIR = ROOT / "backstage" / "templates" / "golden-path-service"
VAR = re.compile(r"\$\{\{\s*values\.(\w+)\s*\}\}")

DEFAULTS = {
    "name": "hello-svc", "description": "Demo service", "owner": "group:default/payments-team",
    "ownerName": "payments-team", "system": "payments", "environment": "dev", "port": "8080",
    "replicas": "2", "repoOwner": "acme", "repoName": "hello-svc", "tier": "small", "costCenter": "ENG-1042",
}


def copy_without_render_globs():
    tpl = yaml.safe_load((TPL_DIR / "template.yaml").read_text())
    for step in tpl["spec"]["steps"]:
        if step["action"] == "fetch:template" and step["input"]["url"] == "./skeleton":
            return step["input"]["copyWithoutRender"]
    raise SystemExit("skeleton fetch step not found")


def render_text(text, values):
    def sub(m):
        key = m.group(1)
        if key not in values:
            raise KeyError(f"template uses undefined value '{key}'")
        return str(values[key])
    return VAR.sub(sub, text)


def render_tree(src, dst, values, skip_globs=()):
    for path in sorted(src.rglob("*")):
        if path.is_dir():
            continue
        rel = path.relative_to(src).as_posix()
        out = dst / render_text(rel, values)
        out.parent.mkdir(parents=True, exist_ok=True)
        if any(fnmatch.fnmatch(rel, g) for g in skip_globs):
            out.write_bytes(path.read_bytes())
        else:
            out.write_text(render_text(path.read_text(), values))


def render(out_dir, overrides=None):
    values = {**DEFAULTS, **(overrides or {})}
    out_dir = pathlib.Path(out_dir)
    render_tree(TPL_DIR / "skeleton", out_dir / "service", values, copy_without_render_globs())
    render_tree(TPL_DIR / "tenant", out_dir / "tenant-out", values)
    return out_dir


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    ov = dict(a.split("=", 1) for a in sys.argv[2:])
    print("rendered to", render(sys.argv[1], ov))
