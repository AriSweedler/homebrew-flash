# Builds the universal launcher stub committed to the repo.
# End-user machines never run this — they receive the committed binary and the
# bundler re-signs it per game at install time.
# Rebuild + verify after any launcher.m change:  make && make verify
SHELL := /bin/bash
CC ?= clang
CFLAGS = -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=11.0
FRAMEWORKS = -framework Foundation -framework CoreFoundation

launcher: launcher.m
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $@ $<
	codesign --force -s - $@

.PHONY: verify drift clean
verify: launcher
	lipo -info launcher
	codesign --verify --strict launcher

# Detects source/binary drift: rebuilds to a temp file and diffs the
# disassembled text section per arch (plus LC_BUILD_VERSION minos) against the
# committed binary, ignoring link-time noise (LC_UUID, signature).
drift:
	@tmp="$${TMPDIR:-/tmp}/launcher-drift-$$$$"; \
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o "$$tmp" launcher.m; \
	status=0; \
	for arch in arm64 x86_64; do \
	  diff <(otool -arch $$arch -tv launcher | tail -n +2) \
	       <(otool -arch $$arch -tv "$$tmp" | tail -n +2) \
	    || { echo "DRIFT: $$arch text differs from committed launcher"; status=1; }; \
	done; \
	diff <(otool -l launcher | grep -A4 LC_BUILD_VERSION | grep minos) \
	     <(otool -l "$$tmp" | grep -A4 LC_BUILD_VERSION | grep minos) \
	  || { echo "DRIFT: LC_BUILD_VERSION minos differs from committed launcher"; status=1; }; \
	rm -f "$$tmp"; \
	[ $$status -eq 0 ] && echo "no drift: committed launcher matches launcher.m"; \
	exit $$status

clean:
	rm -f launcher
