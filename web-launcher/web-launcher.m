// web-launcher stub: a minimal "emulator" window for web games.
// Two modes, decided by the payload dir Resources/<GamePayload default "web">:
//   - site.conf with a `url=` line -> load that LIVE site (wrapper mode; used
//     for games we may not redistribute — nothing of theirs ships in the app)
//   - otherwise -> load the payload's index.html fully offline
// Build: clang -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
//   -framework Cocoa -framework WebKit -o web-launcher web-launcher.m
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include <stdio.h>
#include <stdlib.h>

@interface WrapDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property(strong) NSWindow *window;
@end

@implementation WrapDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)note {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *name = [bundle objectForInfoDictionaryKey:@"CFBundleName"] ?: @"Game";
    NSString *payload = [bundle objectForInfoDictionaryKey:@"GamePayload"] ?: @"web";
    NSNumber *w = [bundle objectForInfoDictionaryKey:@"GameWindowWidth"] ?: @1040;
    NSNumber *h = [bundle objectForInfoDictionaryKey:@"GameWindowHeight"] ?: @620;

    NSString *payloadDir = [bundle.resourcePath stringByAppendingPathComponent:payload];

    // Wrapper mode: site.conf names a remote URL to load instead of index.html.
    NSURL *remote = nil;
    NSString *confPath = [payloadDir stringByAppendingPathComponent:@"site.conf"];
    NSString *conf = [NSString stringWithContentsOfFile:confPath
                                               encoding:NSUTF8StringEncoding error:NULL];
    if (conf) {
        for (NSString *rawLine in [conf componentsSeparatedByCharactersInSet:
                                        [NSCharacterSet newlineCharacterSet]]) {
            NSString *line = [rawLine stringByTrimmingCharactersInSet:
                                        [NSCharacterSet whitespaceCharacterSet]];
            if ([line hasPrefix:@"url="]) {
                remote = [NSURL URLWithString:[line substringFromIndex:4]];
                break;
            }
        }
        if (!remote || !([remote.scheme isEqualToString:@"https"])) {
            fprintf(stderr, "Bad site.conf: need a `url=https://...` line in %s\n",
                    confPath.UTF8String);
            exit(1);
        }
    }

    NSString *index = [payloadDir stringByAppendingPathComponent:@"index.html"];
    if (!remote && ![[NSFileManager defaultManager] fileExistsAtPath:index]) {
        // Mirror the fail() semantics of the exec-style launchers: always log
        // to stderr, dialog only when interactive, and exit nonzero so
        // headless/CI checks (ARI_FLASH_NO_DIALOG=1) see a real failure.
        NSString *title = @"Game files not found";
        NSString *msg = [NSString stringWithFormat:
            @"Missing %@. Reinstall with: brew reinstall <game>", index];
        fprintf(stderr, "%s: %s\n", title.UTF8String, msg.UTF8String);
        if (!getenv("ARI_FLASH_NO_DIALOG")) {
            NSAlert *a = [NSAlert new];
            a.messageText = title;
            a.informativeText = msg;
            [a runModal];
        }
        exit(1);
    }

    NSRect frame = NSMakeRect(0, 0, w.doubleValue, h.doubleValue);
    self.window = [[NSWindow alloc]
        initWithContentRect:frame
                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                            NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                    backing:NSBackingStoreBuffered
                      defer:NO];
    self.window.title = name;
    self.window.delegate = self;

    WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
    WKWebView *web = [[WKWebView alloc] initWithFrame:frame configuration:cfg];
    web.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    if (remote) {
        [web loadRequest:[NSURLRequest requestWithURL:remote]];
    } else {
        [web loadFileURL:[NSURL fileURLWithPath:index]
            allowingReadAccessToURL:[NSURL fileURLWithPath:payloadDir isDirectory:YES]];
    }
    self.window.contentView = web;

    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app { return YES; }
@end

static void addQuitMenu(void) {
    NSMenu *bar = [NSMenu new];
    NSMenuItem *appItem = [NSMenuItem new];
    [bar addItem:appItem];
    NSMenu *appMenu = [NSMenu new];
    [appMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    appItem.submenu = appMenu;
    NSApp.mainMenu = bar;
}

int main(void) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        app.activationPolicy = NSApplicationActivationPolicyRegular;
        addQuitMenu();
        WrapDelegate *delegate = [WrapDelegate new];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
