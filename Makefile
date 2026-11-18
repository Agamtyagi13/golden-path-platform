.PHONY: test policy-test render up smoke down evidence
test: policy-test
	python3 -m pytest tests -q
policy-test:
	conftest verify -p policies/opa
	kyverno test policies/tests
render:
	python3 scripts/render_skeleton.py /tmp/gp-render
up:
	./scripts/bootstrap-local.sh
smoke:
	mkdir -p docs/testing-evidence && ./scripts/smoke-test.sh | tee docs/testing-evidence/smoke-test.log
down:
	kind delete cluster --name golden-path
