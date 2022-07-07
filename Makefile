FORMAT?=yaml

#SHELL:= env OUTDIR=$(OUTDIR) SRCDIR=$(SRCDIR) BINDIR=$(BINDIR) VERSION=$(VERSION) $(SHELL)
ifndef VERSION
	VERSION:=$(shell ls $(BINDIR) | sort -rV | head -n 1)
endif
OUTDIR?="generated/$(VERSION)"
SRCDIR?="pkg/"
BINDIR?="bin/"

export TMPOUT:=$(shell mktemp -d)
export PATH:=$(BINDIR)/$(VERSION):bin:/usr/local/bin:$$PATH

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
SOURCES:=$(call rwildcard,$(SRCDIR),*.yaml)
SRCIMG:=$(call rwildcard,$(SRCDIR),*imagelist)
SRCSH:=$(call rwildcard,$(SRCDIR),*.sh)
SRCDIRS:=$(dir $(SOURCES)) $(dir $(SRCIMG)) $(dir $(SRCSH))

.PHONY: all generate validate commit clean FORCE

all: generate validate commit clean

generate: $(SOURCES) | $(SRCDIRS)
	@echo $(SOURCES)

validate:
	opm validate $(TMPOUT)

commit: clean
	mv $(TMPOUT) $(OUTDIR)

clean:
	rm -rf $(OUTDIR)

$(SRCDIRS): 
	mkdir -p $(TMPOUT)/$@

#pre-rendered catalogs
%.yaml: FORCE
	cp $@ $(TMPOUT)/$(*D)/$(*F).$(FORMAT)

#basic-veneer
%.veneer.yaml: FORCE
	opm alpha render-veneer basic --output=$(FORMAT) $@ > $(TMPOUT)/$(*D)/$(*F).$(FORMAT)

#semver-veneer
%.semver.veneer.yaml: FORCE
	opm alpha render-veneer semver --output=$(FORMAT) $@ > $(TMPOUT)/$(*D)/$(*F).$(FORMAT)

#catalog image list
%imagelist: FORCE
	foreach src,$(shell cat $@),$(shell opm render $(src))

