# Builds the universal godot-launcher stub committed to the repo.
# Rebuild + verify after any godot-launcher.m change:  make && make verify
CC ?= clang
CFLAGS = -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=11.0
FRAMEWORKS = -framework Foundation -framework CoreFoundation

godot-launcher: godot-launcher.m
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $@ $<
	codesign --force -s - $@

.PHONY: verify clean
verify: godot-launcher
	lipo -info godot-launcher
	codesign --verify --strict godot-launcher

clean:
	rm -f godot-launcher
