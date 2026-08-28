# Builds the prebuilt universal launcher committed to this repo.
# End-user machines never run this — they receive the committed binary and the
# bundler re-signs it per game at install time.
CC ?= clang
ARCHS := -arch arm64 -arch x86_64
CFLAGS := -O2 -mmacosx-version-min=11.0
FRAMEWORKS := -framework Foundation -framework CoreFoundation

launcher: launcher.m
	$(CC) $(ARCHS) $(CFLAGS) $(FRAMEWORKS) -o $@ $<
	codesign --force -s - $@

verify: launcher
	lipo -info launcher
	codesign --verify --strict launcher
	@echo OK

clean:
	rm -f launcher

.PHONY: verify clean
