# uFawkesDojo — lab verification.
#
# verify-labs is the local mirror of Live Acceptance (Nightly),
# .github/workflows/live-acceptance.yml: boot the real uFawkesObs stack,
# run the four stack-verified labs' own validate.sh against it, tear down.
# The nine student-artifact labs are excluded here exactly as in CI (#73).

UF_OBS_DIR ?= $(HOME)/dojo-labs/uFawkesObs

verify-labs: ## Boot the real stack and run the 4 stack-verified labs' self-checks
	@UF_OBS_DIR="$(UF_OBS_DIR)" bash scripts/verify-labs.sh

.PHONY: verify-labs
