BUILD_DIR := _build
IMAGE_TAR_FILE := $(BUILD_DIR)/dkp-insights-image-bundle.tar.gz
REPO_ARCHIVE_FILE := $(BUILD_DIR)/dkp-insights.tar.gz
CATALOG_IMAGES_TXT := $(BUILD_DIR)/dkp_insights_images.txt
INSIGHTS_CATALOG_APPLICATIONS_CHART_BUNDLE := $(BUILD_DIR)/dkp-insights-charts-bundle.tar.gz
RELEASE_S3_BUCKET ?= downloads.mesosphere.io

CATALOG_APPLICATIONS_VERSION ?= ""

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

.PHONY: release.save-images.tar
release.save-images.tar: $(GOJQ_BIN) $(MINDTHEGAP_BIN) $(BUILD_DIR)
release.save-images.tar:
	$(call print-target)
	@$(GOJQ_BIN) -r --yaml-input '.|flatten|sort|.[]' hack/images.yaml > $(CATALOG_IMAGES_TXT)
	@$(MINDTHEGAP_BIN) create image-bundle --platform linux/amd64 --images-file $(CATALOG_IMAGES_TXT) --output-file $(IMAGE_TAR_FILE)
	@ls -latrh $(IMAGE_TAR_FILE)

.PHONY: release.repo-archive
release.repo-archive: $(BUILD_DIR)
ifeq ($(CATALOG_APPLICATIONS_VERSION),"")
	$(info CATALOG_APPLICATIONS_VERSION should be set to the version which is part of the s3 file path)
else
	git archive --format "tar.gz" -o $(REPO_ARCHIVE_FILE) \
	                              $(CATALOG_APPLICATIONS_VERSION) -- \
	                              helm-repositories services
endif

.PHONY: release.s3
release.s3: CHART_BUNDLE_URL = https://downloads.d2iq.com/dkp/$(CATALOG_APPLICATIONS_VERSION)/dkp-insights-charts-bundle-$(CATALOG_APPLICATIONS_VERSION).tar.gz
release.s3: REPO_ARCHIVE_URL = https://downloads.d2iq.com/dkp/$(CATALOG_APPLICATIONS_VERSION)/dkp-insights-$(CATALOG_APPLICATIONS_VERSION).tar.gz
release.s3: IMAGE_BUNDLE_URL = https://downloads.d2iq.com/dkp/$(CATALOG_APPLICATIONS_VERSION)/dkp-insights-image-bundle-$(CATALOG_APPLICATIONS_VERSION).tar.gz
release.s3:
	$(call print-target)
ifeq ($(CATALOG_APPLICATIONS_VERSION),"")
	$(info CATALOG_APPLICATIONS_VERSION should be set to the version which is part of the s3 file path)
else
	aws s3 cp --no-progress --acl bucket-owner-full-control $(INSIGHTS_CATALOG_APPLICATIONS_CHART_BUNDLE) s3://$(RELEASE_S3_BUCKET)/dkp/$(CATALOG_APPLICATIONS_VERSION)/dkp-insights-charts-bundle-$(CATALOG_APPLICATIONS_VERSION).tar.gz
	echo "Published Chart Bundle to $(CHART_BUNDLE_URL)"
	aws s3 cp --no-progress --acl bucket-owner-full-control $(REPO_ARCHIVE_FILE) s3://$(RELEASE_S3_BUCKET)/dkp/$(CATALOG_APPLICATIONS_VERSION)/dkp-insights-$(CATALOG_APPLICATIONS_VERSION).tar.gz
	echo "Published Repo Archive File to $(REPO_ARCHIVE_URL)"
	aws s3 cp --no-progress --acl bucket-owner-full-control $(IMAGE_TAR_FILE) s3://$(RELEASE_S3_BUCKET)/dkp/$(CATALOG_APPLICATIONS_VERSION)/dkp-insights-image-bundle-$(CATALOG_APPLICATIONS_VERSION).tar.gz
	echo "Published Image Bundle to $(IMAGE_BUNDLE_URL)"
ifeq (,$(findstring dev,$(CATALOG_APPLICATIONS_VERSION)))
	# Make sure to set SLACK_WEBHOOK environment variable to webhook url for the below mentioned channel
	curl -X POST -H 'Content-type: application/json' \
	--data '{"channel":"#eng-shipit","blocks":[{"type":"header","text":{"type":"plain_text","text":":announce: DKP Insights Catalog Applications $(CATALOG_APPLICATIONS_VERSION) is out!","emoji":true}},{"type":"section","text":{"type":"mrkdwn","text":"*Bundles:*\n:airgap: Airgapped Image Bundle: $(IMAGE_BUNDLE_URL)\n:package: Chart Bundle: $(CHART_BUNDLE_URL)\n:github: Git Repo Tarball: $(REPO_ARCHIVE_URL)"}}]}' \
	$(SLACK_WEBHOOK)
endif
endif

.PHONY: insights-catalog-applications
insights-catalog-applications: ## Clones the insights-catalog-applications repo locally or updates the clone
insights-catalog-applications:
	$(call print-target)
	rm -rf $(INSIGHTS_CATALOG_APPLICATIONS_DIR) && \
	  mkdir -p $(INSIGHTS_CATALOG_APPLICATIONS_DIR) && \
	  git clone -q https://github.com/mesosphere/insights-catalog-applications.git $(INSIGHTS_CATALOG_APPLICATIONS_DIR) && \
	  cd $(INSIGHTS_CATALOG_APPLICATIONS_DIR) && \
	  git checkout $(INSIGHTS_CATALOG_APPLICATIONS_REF);

.PHONY: release.charts-bundle
release.charts-bundle: ## Creates the chart bundle via the Kommander CLI
release.charts-bundle: $(DKP_CLI_BIN) insights-catalog-applications
	$(call print-target)
	echo "Building charts bundle from insights-catalog-applications repository: "
	rm -f $(INSIGHTS_CATALOG_APPLICATIONS_CHART_BUNDLE)
	mkdir -p $(BUILD_DIR)
	$(DKP_CLI_BIN) create chart-bundle \
		--catalog-repository $(INSIGHTS_CATALOG_APPLICATIONS_DIR) \
		--output $(INSIGHTS_CATALOG_APPLICATIONS_CHART_BUNDLE)
