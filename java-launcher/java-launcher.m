// ari-flash java-launcher stub: runs a legacy Java applet from this bundle's
// Resources/<GamePayload>/ dir via the SlimeRunner harness, on the JRE
// installed by the ari-flash-jre cask (probed through the stable
// $(brew --prefix)/bin/ari-flash-java symlink; the JVM home resolves through
// its realpath). Mirrors {launcher,godot-launcher}.m; no first-run copy is
// needed because applet payloads are read-only.
//
// The applet class name lives in the payload as <payload>/applet.conf
// (newline-separated key=value; required `class`, optional repeated
// `param.<name>=<value>` forwarded to the harness as --param-<name> <value>)
// because wrap-bundler writes only its fixed plist key set.
// Build: make (universal arm64+x86_64, ad-hoc signed)
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

static BOOL isExecutableFile(NSString *p) {
    return p.length > 0 && [[NSFileManager defaultManager] isExecutableFileAtPath:p];
}

static NSString *findJava(void) {
    const char *env = getenv("ARI_FLASH_JAVA");
    if (env && *env) {
        NSString *p = @(env);
        if (isExecutableFile(p)) return p;
    }
    // The ari-flash-jre cask's `binary` symlink, per brew prefix. Never probe
    // the Caskroom keg directly — its path is version-dependent.
    NSArray<NSString *> *candidates = @[
        @"/opt/homebrew/bin/ari-flash-java",
        @"/usr/local/bin/ari-flash-java",
    ];
    for (NSString *p in candidates) if (isExecutableFile(p)) return p;
    return nil;
}

// Duplicated in {launcher,godot-launcher,java-launcher}.m by design — each dir
// ships standalone in its release asset; keep in sync.
static void fail(NSString *title, NSString *msg) {
    fprintf(stderr, "%s: %s\n", title.UTF8String, msg.UTF8String);
    if (!getenv("ARI_FLASH_NO_DIALOG")) {
        CFUserNotificationDisplayNotice(0, kCFUserNotificationStopAlertLevel,
            NULL, NULL, NULL, (__bridge CFStringRef)title, (__bridge CFStringRef)msg, CFSTR("OK"));
    }
    exit(1);
}

int main(void) {
    @autoreleasepool {
        NSBundle *bundle = [NSBundle mainBundle];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *payloadName = [bundle objectForInfoDictionaryKey:@"GamePayload"] ?: @"game";
        NSString *payload = [bundle.resourcePath stringByAppendingPathComponent:payloadName];
        NSString *harness = [payload stringByAppendingPathComponent:@"slime-harness.jar"];
        if (![fm fileExistsAtPath:harness]) {
            fail(@"Game payload missing",
                 [NSString stringWithFormat:@"Missing %@. Reinstall with: brew reinstall --cask <game>", harness]);
        }

        // applet.conf: `class` names the applet; `param.<name>` lines become
        // --param-<name> <value> pairs (name passed through verbatim; the
        // harness lowercases its parameter map keys).
        NSString *confPath = [payload stringByAppendingPathComponent:@"applet.conf"];
        NSString *conf = [NSString stringWithContentsOfFile:confPath
                                                   encoding:NSUTF8StringEncoding error:NULL];
        if (!conf) {
            fail(@"Game payload missing",
                 [NSString stringWithFormat:@"Missing %@. Reinstall with: brew reinstall --cask <game>", confPath]);
        }
        NSString *cls = nil;
        NSMutableArray<NSString *> *paramArgs = [NSMutableArray array];
        for (NSString *rawLine in [conf componentsSeparatedByCharactersInSet:
                                        [NSCharacterSet newlineCharacterSet]]) {
            NSString *line = [rawLine stringByTrimmingCharactersInSet:
                                        [NSCharacterSet whitespaceCharacterSet]];
            if (!line.length || [line hasPrefix:@"#"]) continue;
            NSRange eq = [line rangeOfString:@"="];
            if (eq.location == NSNotFound) continue;
            NSString *key = [line substringToIndex:eq.location];
            NSString *value = [line substringFromIndex:NSMaxRange(eq)];
            if ([key isEqualToString:@"class"]) {
                cls = value;
            } else if ([key hasPrefix:@"param."] && key.length > @"param.".length) {
                [paramArgs addObject:[NSString stringWithFormat:@"--param-%@",
                                      [key substringFromIndex:@"param.".length]]];
                [paramArgs addObject:value];
            }
        }
        if (!cls.length) {
            fail(@"Game payload missing",
                 [NSString stringWithFormat:@"Missing `class` line in %@. Reinstall with: brew reinstall --cask <game>", confPath]);
        }

        NSString *java = findJava();
        if (!java) {
            fail(@"Java runtime is not installed",
                 @"Install it with:\n\nbrew install --cask arisweedler/flash/ari-flash-jre");
        }

        // Window size baked by wrap-bundler (--window WxH) as plist integers;
        // .description stringifies them (same trick as launcher.m). Optional.
        NSString *width = [[bundle objectForInfoDictionaryKey:@"GameWindowWidth"] description];
        NSString *height = [[bundle objectForInfoDictionaryKey:@"GameWindowHeight"] description];
        NSString *title = [bundle objectForInfoDictionaryKey:@"CFBundleName"] ?: cls;
        NSString *cp = [NSString stringWithFormat:@"%@:%@", harness, payload];

        NSMutableArray<NSString *> *argStrings = [NSMutableArray arrayWithArray:@[
            java,
            // Dock/menu-bar identity for the AWT process
            [NSString stringWithFormat:@"-Xdock:name=%@", title] ]];
        // CFBundleIconFile is the extensionless executable name wrap-bundler writes.
        NSString *iconFile = [bundle objectForInfoDictionaryKey:@"CFBundleIconFile"];
        if (iconFile.length) {
            NSString *icns = [bundle.resourcePath stringByAppendingPathComponent:
                              [iconFile stringByAppendingPathExtension:@"icns"]];
            if ([fm fileExistsAtPath:icns]) {
                [argStrings addObject:[NSString stringWithFormat:@"-Xdock:icon=%@", icns]];
            }
        }
        // Pipeline note: JDK 17 defaults java2d to Metal, which is vsynced
        // (displaySync) — the games are internally double-buffered, so Metal
        // presents them tear-free. A briefly-shipped -Dsun.java2d.metal=false
        // default caused visible tearing ("flickery") and was reverted.
        // ARI_FLASH_JAVA_OPTS passes arbitrary JVM flags for A/B, e.g.:
        //   ARI_FLASH_JAVA_OPTS="-Dsun.java2d.metal=false" <app>/Contents/MacOS/<Exe>
        const char *extraOpts = getenv("ARI_FLASH_JAVA_OPTS");
        if (extraOpts && *extraOpts) {
            for (NSString *opt in [@(extraOpts) componentsSeparatedByCharactersInSet:
                                       [NSCharacterSet whitespaceCharacterSet]]) {
                if (opt.length) [argStrings addObject:opt];
            }
        }
        [argStrings addObjectsFromArray:@[ @"-cp", cp, @"SlimeRunner",
                                           @"--class", cls, @"--title", title ]];
        if (width.length && height.length) {
            [argStrings addObjectsFromArray:@[ @"--width", width, @"--height", height ]];
        }
        [argStrings addObjectsFromArray:paramArgs];

        char **args = calloc(argStrings.count + 1, sizeof(char *));
        for (NSUInteger i = 0; i < argStrings.count; i++) {
            args[i] = (char *)argStrings[i].fileSystemRepresentation;
        }
        // Finder launches have cwd "/"; the harness resolves the applet
        // codebase from cwd, so run java from inside the payload dir.
        if (chdir(payload.fileSystemRepresentation) != 0) {
            fail(@"Failed to launch Java",
                 [NSString stringWithFormat:@"chdir %@: %s", payload, strerror(errno)]);
        }
        execv(args[0], args);
        fail(@"Failed to launch Java", @(strerror(errno)));
    }
    return 1;
}
