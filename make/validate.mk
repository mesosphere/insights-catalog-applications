.PHONY: validate-manifests
validate-manifests: $(DKP_BLOODHOUND_BIN)
	@$(DKP_BLOODHOUND_BIN) . --helm-repo-path ./helm-repositories --skip-applications=dkp-insights
