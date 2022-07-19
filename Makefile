#MAKEFLAGS+="-Orecurse -j 8 -l 2"
FORMAT?=yaml #output format
INPUT_FORMATS:=%.yaml# %.sh #accepted input formats
SRCDIR?=pkg
BINDIR?=bin
EXACT_VERSION:=$(or $(VERSION),$(shell ls $(BINDIR) | sort -rV | head -n 1))
STRIPPED_VERSION:=$(word 1,$(subst ., ,$(EXACT_VERSION))).X
VERSION_ORDER:=$(EXACT_VERSION) $(STRIPPED_VERSION)

OUTDIR?=output/$(EXACT_VERSION)
output_path=$(subst $(EXACT_VERSION),,$(subst $(STRIPPED_VERSION),,$(1)))

export TMPOUT:=$(shell mktemp -d)
export PATH:=$(BINDIR)/$(EXACT_VERSION):$(BINDIR):$(PATH)

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $2,$d))
SRCDIRS:=$(foreach f,$(dir $(foreach v,$(VERSION_ORDER),$(call rwildcard,$(SRCDIR),%/$(v)))),$(firstword $(dir $(wildcard $(patsubst %,$(f)%/*,$(VERSION_ORDER))))))
SOURCES:=$(subst //,/,$(foreach f,$(INPUT_FORMATS),$(foreach d,$(SRCDIRS),$(call rwildcard,$(d),$(f)))))

.PHONY: all generate validate commit FORCE

all: generate validate commit

generate: $(SRCDIRS) $(SOURCES)

validate:
	@echo Validate generated FBC
	opm validate $(TMPOUT)

commit:
	@mkdir -p $(OUTDIR)
	$(foreach f,$(wildcard $(TMPOUT)/$(SRCDIR)/*),@rm -rf $(OUTDIR)/$(notdir $f))
	@mv $(TMPOUT)/$(SRCDIR)/* $(OUTDIR)
	@rm -rf $(TMPOUT)

$(SRCDIRS): FORCE 
	@mkdir -p $(TMPOUT)/$(call output_path,$@)

#pre-rendered catalogs
%.yaml: FORCE
	@echo Copy rendered FBC $@ 
	@cp $@ $(TMPOUT)/$(call output_path,$(*D))$(*F).$(FORMAT)

#basic-veneer
%.veneer.yaml: FORCE
	@echo Render basic veneer $@
	@opm alpha render-veneer basic --output=$(FORMAT) $@ > $(TMPOUT)/$(call output_path,$(*D))$(*F).$(FORMAT)

#semver-veneer
%.semver.veneer.yaml: FORCE
	@echo Render semver veneer $@ $(*D)
	@opm alpha render-veneer semver --output=$(FORMAT) $@ > $(TMPOUT)/$(call output_path,$(*D))$(*F).$(FORMAT)
