# Builds the universal godot-launcher stub committed to the repo.
# Rebuild + verify after any godot-launcher.m change:  make && make verify
SHELL := /bin/bash
CC ?= clang
CFLAGS = -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=11.0
FRAMEWORKS = -framework Foundation -framework CoreFoundation

godot-launcher: godot-launcher.m
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $@ $<
	codesign --force -s - $@

.PHONY: verify drift clean
verify: godot-launcher
	lipo -info godot-launcher
	codesign --verify --strict godot-launcher

# Detects source/binary drift: rebuilds to a temp file and diffs the
# disassembled text section per arch (plus LC_BUILD_VERSION minos) against the
# committed binary, ignoring link-time noise (LC_UUID, signature).
drift:
	@tmp="$${TMPDIR:-/tmp}/godot-launcher-drift-$$$$"; \
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o "$$tmp" godot-launcher.m; \
	status=0; \
	for arch in arm64 x86_64; do \
	  diff <(otool -arch $$arch -tv godot-launcher | tail -n +2) \
	       <(otool -arch $$arch -tv "$$tmp" | tail -n +2) \
	    || { echo "DRIFT: $$arch text differs from committed godot-launcher"; status=1; }; \
	done; \
	diff <(otool -l godot-launcher | grep -A4 LC_BUILD_VERSION | grep minos) \
	     <(otool -l "$$tmp" | grep -A4 LC_BUILD_VERSION | grep minos) \
	  || { echo "DRIFT: LC_BUILD_VERSION minos differs from committed godot-launcher"; status=1; }; \
	rm -f "$$tmp"; \
	[ $$status -eq 0 ] && echo "no drift: committed godot-launcher matches godot-launcher.m"; \
	exit $$status

clean:
	rm -f godot-launcher
