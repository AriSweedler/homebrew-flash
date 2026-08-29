// godot-launcher stub: runs a bundled Godot 3 project via the Godot 3 runtime
// (the tap's godot3 cask), the way the flash launcher runs a swf via Ruffle.
//
// Godot 3 projects need editor-generated .import data, and the signed .app
// bundle must stay read-only — so on first run the project is copied to a
// per-game dir under Application Support and imported headlessly there
// (--no-window --editor --quit). Subsequent runs exec straight into the game.
// Build: clang -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
//   -framework Foundation -framework CoreFoundation -o godot-launcher godot-launcher.m
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

static NSString *findGodot(void) {
    const char *env = getenv("GODOT3_PATH");
    if (env && *env) {
        NSString *p = @(env);
        if (isExecutableFile(p)) return p;
    }
    NSArray<NSString *> *candidates = @[
        @"/Applications/Godot 3.app/Contents/MacOS/Godot",
        [NSHomeDirectory() stringByAppendingPathComponent:@"Applications/Godot 3.app/Contents/MacOS/Godot"],
    ];
    for (NSString *p in candidates) if (isExecutableFile(p)) return p;
    return nil;
}

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
        NSString *payload = [bundle objectForInfoDictionaryKey:@"GamePayload"] ?: @"project";
        NSString *src = [bundle.resourcePath stringByAppendingPathComponent:payload];
        if (![fm fileExistsAtPath:[src stringByAppendingPathComponent:@"project.godot"]]) {
            fail(@"Game project not found",
                 [NSString stringWithFormat:@"Missing %@/project.godot. Reinstall with: brew reinstall <game>", src]);
        }
        NSString *godot = findGodot();
        if (!godot) {
            fail(@"Godot 3 is not installed",
                 @"Install it with:\n\nbrew install arisweedler/flash/godot3");
        }

        // Writable per-game copy, keyed by bundle id and version so upgrades
        // re-copy and re-import automatically.
        NSString *bundleId = bundle.bundleIdentifier ?: @"com.arisweedler.flash.unknown";
        NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0";
        NSString *appSupport = [NSSearchPathForDirectoriesInDomains(
            NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
        NSString *dest = [[appSupport stringByAppendingPathComponent:bundleId]
                          stringByAppendingPathComponent:version];
        NSString *projectDir = [dest stringByAppendingPathComponent:@"project"];
        NSString *importedMarker = [dest stringByAppendingPathComponent:@".imported"];

        if (![fm fileExistsAtPath:importedMarker]) {
            NSError *err = nil;
            [fm removeItemAtPath:projectDir error:NULL];
            if (![fm createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:&err]
                || ![fm copyItemAtPath:src toPath:projectDir error:&err]) {
                fail(@"Could not stage game files",
                     [NSString stringWithFormat:@"%@ -> %@: %@", src, projectDir,
                                                err.localizedDescription ?: @"unknown error"]);
            }
            // Headless one-time import of the project's assets.
            NSString *cmd = [NSString stringWithFormat:
                @"'%@' --no-window --editor --quit --path '%@' >/dev/null 2>&1",
                godot, projectDir];
            int rc = system(cmd.UTF8String);
            if (rc != 0) {
                fprintf(stderr, "godot-launcher: headless import exited %d (continuing)\n", rc);
            }
            [@"" writeToFile:importedMarker atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        }

        char *const args[] = { (char *)godot.fileSystemRepresentation,
                               (char *)"--path",
                               (char *)projectDir.fileSystemRepresentation, NULL };
        execv(args[0], args);
        fail(@"Failed to launch Godot", @(strerror(errno)));
    }
    return 1;
}
