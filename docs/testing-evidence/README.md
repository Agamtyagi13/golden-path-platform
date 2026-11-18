# Test evidence (executed during authoring)

Environment: Ubuntu 24, Python 3.12, conftest 0.56.0 (OPA 0.69), Kyverno CLI 1.13.4, OpenTofu 1.8.5. Date: 2026-11-18

## 1. pytest - template, generated service, tenant schema
```
tests/test_template_render.py::test_template_is_valid_backstage_template PASSED [  9%]
tests/test_template_render.py::test_template_parameters_have_guardrails PASSED [ 18%]
tests/test_template_render.py::test_every_template_value_is_supplied_by_a_step PASSED [ 27%]
tests/test_template_render.py::test_no_unrendered_placeholders_left PASSED [ 36%]
tests/test_template_render.py::test_github_actions_and_helm_syntax_preserved PASSED [ 45%]
tests/test_template_render.py::test_catalog_info_has_ownership_metadata PASSED [ 54%]
tests/test_template_render.py::test_chart_metadata_and_values_parse PASSED [ 63%]
tests/test_template_render.py::test_tenant_request_matches_terraform_schema PASSED [ 72%]
tests/test_template_render.py::test_generated_service_unit_tests_pass PASSED [ 81%]
tests/test_template_render.py::test_opa_policy_copy_in_skeleton_is_in_sync PASSED [ 90%]
tests/test_template_render.py::test_committed_tenants_are_valid[path0] PASSED [100%]
============================== 11 passed in 0.36s ==============================
```

## 2. OPA / Conftest unit tests
```

10 tests, 10 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped
```

## 3. Kyverno policy tests (good passes, each bad fails)
```
Test Summary: 18 tests passed and 0 tests failed
```

## 4. Violation samples vs both engines
```
latest-tag.yaml                    OPA:REJECTED  Kyverno:REJECTED
no-owner-label.yaml                OPA:REJECTED  Kyverno:REJECTED
no-resources-no-probes.yaml        OPA:REJECTED  Kyverno:REJECTED
runs-as-root.yaml                  OPA:REJECTED  Kyverno:REJECTED
untrusted-registry.yaml            OPA:REJECTED  Kyverno:REJECTED
```

## 5. Static checks
```
yamllint: clean
tofu fmt: clean
```

## Not executed in the authoring sandbox (run these yourself - CI does)

- `helm lint` / `helm template` (Helm binary unavailable) -> job `rendered-chart` in `platform-ci.yml`
- `terraform validate` / `plan` (provider registry unreachable) -> job `terraform`
- `make up && make smoke` against a real kind cluster -> paste the log in `smoke-test.log`
- Backstage UI run of the template and the screenshots in `docs/screenshots/`
