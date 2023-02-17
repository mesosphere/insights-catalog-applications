.DEFAULT_GOAL := help

SHELL := /bin/bash -euo pipefail

REPO_ROOT := $(shell git rev-parse --show-toplevel)
# REPO_ROOT := $(CURDIR)

INTERACTIVE := $(shell [ -t 0 ] && echo 1)

export GITHUB_ORG ?= mesosphere
export GITHUB_REPOSITORY ?= insights-catalog-applications
export INSIGHTS_CATALOG_APPLICATIONS_REF ?= main
export INSIGHTS_CATALOG_APPLICATIONS_DIR ?= $(GITHUB_REPOSITORY)

GOARCH ?= $(shell go env GOARCH)
GOOS ?= $(shell go env GOOS)
MINDTHEGAP_VERSION ?= v0.13.1
GOJQ_VERSION ?= v0.12.4
DKP_BLOODHOUND_VERSION ?= 0.2.1
DKP_CLI_VERSION ?= v2.2.0-rc.8
export GOJQ_BIN = bin/$(GOOS)/$(GOARCH)/gojq-$(GOJQ_VERSION)
export MINDTHEGAP_BIN = bin/$(GOOS)/$(GOARCH)/mindthegap
export DKP_BLOODHOUND_BIN = bin/$(GOOS)/$(GOARCH)/dkp-bloodhound
export DKP_CLI_BIN = bin/$(GOOS)/$(GOARCH)/dkp

ifneq (,$(filter tar (GNU tar)%, $(shell tar --version)))
WILDCARDS := --wildcards
endif

ifneq ($(wildcard $(REPO_ROOT)/.pre-commit-config.yaml),)
	PRE_COMMIT_CONFIG_FILE ?= $(REPO_ROOT)/.pre-commit-config.yaml
else
	PRE_COMMIT_CONFIG_FILE ?= $(REPO_ROOT)/repo-infra/.pre-commit-config.yaml
endif

include make/ci.mk
include make/validate.mk
include make/release.mk
include make/tools.mk

.PHONY: pre-commit
pre-commit: ## Runs pre-commit on all files
pre-commit: ; $(info $(M) running pre-commit)
ifeq ($(wildcard $(PRE_COMMIT_CONFIG_FILE)),)
	$(error Cannot find pre-commit config file $(PRE_COMMIT_CONFIG_FILE). Specify the config file via PRE_COMMIT_CONFIG_FILE variable)
endif
	git config --global --add safe.directory $(REPO_ROOT)
	env SKIP=$(SKIP) pre-commit run -a --show-diff-on-failure --config $(PRE_COMMIT_CONFIG_FILE)
	git fetch origin main && gitlint --ignore-stdin --commits origin/main..HEAD

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

define print-target
    @printf "Executing target: \033[36m$@\033[0m\n"
endef

.PHONY: test
test: validate-manifests
