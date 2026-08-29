// ari-flash launcher stub: resolves its game SWF from its own bundle and execs Ruffle.
// Build: clang -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 -framework Foundation -framework CoreFoundation -o launcher launcher.m
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

static NSString *findRuffle(void) {
    const char *env = getenv("RUFFLE_PATH");
    if (env && *env) {
        NSString *p = @(env);
        if (isExecutableFile(p)) return p;
    }
    NSArray<NSString *> *candidates = @[
        @"/Applications/Ruffle.app/Contents/MacOS/ruffle",
        [NSHomeDirectory() stringByAppendingPathComponent:@"Applications/Ruffle.app/Contents/MacOS/ruffle"],
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

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *swf = nil;
        if (argc > 1) swf = @(argv[1]);                       // optional CLI override
        if (!swf.length) swf = [bundle objectForInfoDictionaryKey:@"FlashGameSWF"];
        if (swf.length && ![swf isAbsolutePath]) {
            swf = [bundle.resourcePath stringByAppendingPathComponent:swf];
        }
        if (!swf.length) swf = [bundle pathForResource:@"game" ofType:@"swf"];
        if (!swf.length || ![[NSFileManager defaultManager] fileExistsAtPath:swf]) {
            fail(@"Flash game not found",
                 [NSString stringWithFormat:@"Missing SWF (looked for %@). Reinstall with: brew reinstall <game>", swf ?: @"Resources/game.swf"]);
        }
        NSString *ruffle = findRuffle();
        if (!ruffle) {
            fail(@"Ruffle is not installed",
                 @"Install it with:\n\nbrew install arisweedler/flash/ruffle");
        }
        // Old movies declare tiny stages (Get On Top: 500x375); without an
        // explicit size Ruffle opens the window at exactly that. The bundler
        // bakes RuffleWindowWidth/Height into Info.plist (--window WxH).
        NSString *width = [[bundle objectForInfoDictionaryKey:@"RuffleWindowWidth"] description];
        NSString *height = [[bundle objectForInfoDictionaryKey:@"RuffleWindowHeight"] description];
        NSMutableArray<NSString *> *argStrings = [NSMutableArray arrayWithObject:ruffle];
        if (width.length && height.length) {
            [argStrings addObjectsFromArray:@[ @"--width", width, @"--height", height ]];
        }
        [argStrings addObject:swf];
        char **args = calloc(argStrings.count + 1, sizeof(char *));
        for (NSUInteger i = 0; i < argStrings.count; i++) {
            args[i] = (char *)argStrings[i].fileSystemRepresentation;
        }
        execv(args[0], args);
        fail(@"Failed to launch Ruffle", @(strerror(errno)));
    }
    return 1;
}
