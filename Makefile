# Resolves to ~/Library/texmf on macOS and ~/texmf on Linux, automatically.
TEXMFHOME := $(shell kpsewhich -var-value=TEXMFHOME)
STYDIR    := $(TEXMFHOME)/tex/latex/ou-refs
BIBDIR    := $(TEXMFHOME)/bibtex/bib/ou-refs

.PHONY: install link uninstall check test

## copy files in (machines where you don't keep the repo checked out)
install:
	@mkdir -p "$(STYDIR)" "$(BIBDIR)"
	@install -m 644 ou-refs.sty "$(STYDIR)/"
	@install -m 644 ou-refs.bib "$(BIBDIR)/"
	@echo "installed into $(TEXMFHOME)"

## symlink instead, so edits in the repo take effect immediately
link:
	@mkdir -p "$(STYDIR)" "$(BIBDIR)"
	@ln -sf "$(CURDIR)/ou-refs.sty" "$(STYDIR)/ou-refs.sty"
	@ln -sf "$(CURDIR)/ou-refs.bib" "$(BIBDIR)/ou-refs.bib"
	@echo "linked $(CURDIR) into $(TEXMFHOME)"

uninstall:
	@rm -f "$(STYDIR)/ou-refs.sty" "$(BIBDIR)/ou-refs.bib"
	@echo "removed from $(TEXMFHOME)"

# cd / first: kpsewhich searches "." before the trees, so running this
# from the repo would find the local copies and always look like success.
check:
	@echo "TEXMFHOME = $(TEXMFHOME)"
	@cd / && echo "sty: $$(kpsewhich ou-refs.sty || echo 'NOT FOUND')"
	@cd / && echo "bib: $$(kpsewhich ou-refs.bib || echo 'NOT FOUND')"

## build the smoke test from a directory holding no copy of ou-refs.{sty,bib},
## so a pass proves both were resolved from TEXMFHOME. local-refs.bib goes
## along because it stands in for the Mendeley export next to a real document.
test:
	@rm -rf .test && mkdir -p .test && cp example.tex local-refs.bib .test/
	@cd .test && latexmk -pdf -interaction=nonstopmode example.tex >build.log 2>&1 || true
	@# example.log is rewritten by each pass, so it reflects the FINAL state.
	@# build.log accumulates every pass and still holds the pre-biber warnings.
	@cd .test && if grep -q "Veto of running of 'biber" build.log; then \
	    echo "FAILED: latexmk skipped biber -- a .bib could not be found"; false; \
	  elif grep -q "undefined" example.log; then \
	    echo "FAILED: undefined citations"; grep -m5 "undefined" example.log; false; \
	  elif grep -qE '^! ' example.log; then \
	    echo "FAILED:"; grep -m5 -E '^! ' example.log; false; \
	  else echo "OK -- see .test/example.pdf"; fi
