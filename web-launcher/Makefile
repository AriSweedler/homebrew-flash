# Builds the universal web-launcher stub committed to the repo.
# Rebuild + verify after any web-launcher.m change:  make && make verify
SHELL := /bin/bash
CC ?= clang
CFLAGS = -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=11.0
FRAMEWORKS = -framework Cocoa -framework WebKit

web-launcher: web-launcher.m
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $@ $<
	codesign --force -s - $@

.PHONY: verify drift clean
verify: web-launcher
	lipo -info web-launcher
	codesign --verify --strict web-launcher

# Detects source/binary drift: rebuilds to a temp file and diffs the
# disassembled text section per arch (plus LC_BUILD_VERSION minos) against the
# committed binary, ignoring link-time noise (LC_UUID, signature).
drift:
	@tmp="$${TMPDIR:-/tmp}/web-launcher-drift-$$$$"; \
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o "$$tmp" web-launcher.m; \
	status=0; \
	for arch in arm64 x86_64; do \
	  diff <(otool -arch $$arch -tv web-launcher | tail -n +2) \
	       <(otool -arch $$arch -tv "$$tmp" | tail -n +2) \
	    || { echo "DRIFT: $$arch text differs from committed web-launcher"; status=1; }; \
	done; \
	diff <(otool -l web-launcher | grep -A4 LC_BUILD_VERSION | grep minos) \
	     <(otool -l "$$tmp" | grep -A4 LC_BUILD_VERSION | grep minos) \
	  || { echo "DRIFT: LC_BUILD_VERSION minos differs from committed web-launcher"; status=1; }; \
	rm -f "$$tmp"; \
	[ $$status -eq 0 ] && echo "no drift: committed web-launcher matches web-launcher.m"; \
	exit $$status

clean:
	rm -f web-launcher
