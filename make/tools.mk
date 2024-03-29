.PHONY: mindthegap
mindthegap: $(MINDTHEGAP_BIN)
	$(call print-target)

$(MINDTHEGAP_BIN):
	$(call print-target)
	mkdir -p $(dir $@) _install
	curl -fsSL https://github.com/mesosphere/mindthegap/releases/download/$(MINDTHEGAP_VERSION)/mindthegap_$(MINDTHEGAP_VERSION)_$(GOOS)_$(GOARCH).tar.gz | tar xz -C _install 'mindthegap'
	mv _install/mindthegap $@
	rm -rf _install

.PHONY: gojq
gojq: $(GOJQ_BIN)
	$(call print-target)

ifeq ($(GOOS),darwin)
  GOJQ_EXT := zip
else
  GOJQ_EXT := tar.gz
endif
$(GOJQ_BIN):
	$(call print-target)
	mkdir -p $(dir $@) _install
	curl -fsSL https://github.com/itchyny/gojq/releases/download/$(GOJQ_VERSION)/gojq_$(GOJQ_VERSION)_$(GOOS)_$(GOARCH).$(GOJQ_EXT) | tar xz -C _install $(WILDCARDS) --strip-components 1 '*/gojq'
	mv _install/gojq $@
	chmod 755 $@
	rm -rf _install

.PHONY: bloodhound
bloodhound: $(DKP_BLOODHOUND_BIN)
	$(call print-target)

$(DKP_BLOODHOUND_BIN):
	$(call print-target)
	mkdir -p $(dir $@) _install
	curl -fsSL https://downloads.d2iq.com/dkp-bloodhound/dkp-bloodhound_v$(DKP_BLOODHOUND_VERSION)_$(GOOS)_$(GOARCH).tar.gz | tar xz -C _install 'dkp-bloodhound'
	mv _install/dkp-bloodhound $@
	chmod 755 $@
	rm -rf _install

.PHONY: dkp-cli
dkp-cli: $(DKP_CLI_BIN)
	$(call print-target)

$(DKP_CLI_BIN):
	$(call print-target)
	mkdir -p $(dir $@) _install
	curl -fsSL https://downloads.d2iq.com/dkp/$(DKP_CLI_VERSION)/dkp_$(DKP_CLI_VERSION)_$(GOOS)_$(GOARCH).tar.gz | tar xz -C _install 'dkp'
	mv _install/dkp $@
	chmod 755 $@
	rm -rf _install
