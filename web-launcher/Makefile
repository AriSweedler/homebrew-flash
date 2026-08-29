# Builds the universal web-launcher stub committed to the repo.
# Rebuild + verify after any web-launcher.m change:  make && make verify
CC ?= clang
CFLAGS = -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=11.0
FRAMEWORKS = -framework Cocoa -framework WebKit

web-launcher: web-launcher.m
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $@ $<
	codesign --force -s - $@

.PHONY: verify clean
verify: web-launcher
	lipo -info web-launcher
	codesign --verify --strict web-launcher

clean:
	rm -f web-launcher
