// web-launcher stub: a minimal "emulator" window for web games.
// Three modes, decided by marker files in Resources/<GamePayload default "web">:
//   - serve.conf (optional `index=` line) -> serve the payload dir through an
//     in-app WKURLSchemeHandler ("local web server", no sockets): needed by
//     games that XHR/fetch their own files, which file:// forbids. Missing
//     files get a clean 404 (some games probe for optional files).
//   - site.conf with a `url=` line -> load that LIVE site (wrapper mode; used
//     for games we may not redistribute — nothing of theirs ships in the app)
//   - otherwise -> load the payload's index.html fully offline via file://
// Build: clang -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
//   -framework Cocoa -framework WebKit -o web-launcher web-launcher.m
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include <stdio.h>
#include <stdlib.h>

// In-app static file server over a custom URL scheme. WKWebView routes every
// load (document, subresource, XHR/fetch) for ari-flash:// through this.
@interface PayloadSchemeHandler : NSObject <WKURLSchemeHandler>
@property(copy) NSString *root; // resolved payload dir; requests must stay inside
@end

@implementation PayloadSchemeHandler
+ (NSString *)mimeForExtension:(NSString *)ext {
    static NSDictionary<NSString *, NSString *> *map;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        map = @{ @"html": @"text/html", @"htm": @"text/html",
                 @"js": @"text/javascript", @"mjs": @"text/javascript",
                 @"css": @"text/css", @"json": @"application/json",
                 @"ini": @"text/plain", @"txt": @"text/plain",
                 @"png": @"image/png", @"jpg": @"image/jpeg",
                 @"jpeg": @"image/jpeg", @"gif": @"image/gif",
                 @"svg": @"image/svg+xml", @"ico": @"image/x-icon",
                 @"mp3": @"audio/mpeg", @"ogg": @"audio/ogg",
                 @"wav": @"audio/wav", @"m4a": @"audio/mp4",
                 @"woff": @"font/woff", @"woff2": @"font/woff2",
                 @"ttf": @"font/ttf", @"wasm": @"application/wasm" };
    });
    return map[ext.lowercaseString] ?: @"application/octet-stream";
}
- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)task {
    NSURL *url = task.request.URL;
    NSString *rel = url.path.length ? url.path : @"/";
    NSString *full = [[self.root stringByAppendingPathComponent:rel]
                         stringByStandardizingPath];
    NSData *data = nil;
    // Traversal guard: the standardized path must stay inside the payload.
    if ([full hasPrefix:[self.root stringByAppendingString:@"/"]] ||
        [full isEqualToString:self.root]) {
        data = [NSData dataWithContentsOfFile:full];
    }
    if (!data) {
        NSHTTPURLResponse *resp404 =
            [[NSHTTPURLResponse alloc] initWithURL:url statusCode:404
                                       HTTPVersion:@"HTTP/1.1" headerFields:@{}];
        [task didReceiveResponse:resp404];
        [task didReceiveData:[NSData data]];
        [task didFinish];
        return;
    }
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc]
        initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"
       headerFields:@{ @"Content-Type": [PayloadSchemeHandler
                            mimeForExtension:full.pathExtension],
                       @"Content-Length":
                           [NSString stringWithFormat:@"%lu",
                                     (unsigned long)data.length] }];
    [task didReceiveResponse:resp];
    [task didReceiveData:data];
    [task didFinish];
}
- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)task {}
@end

@interface WrapDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property(strong) NSWindow *window;
@property(strong) PayloadSchemeHandler *scheme;
@end

@implementation WrapDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)note {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *name = [bundle objectForInfoDictionaryKey:@"CFBundleName"] ?: @"Game";
    NSString *payload = [bundle objectForInfoDictionaryKey:@"GamePayload"] ?: @"web";
    NSNumber *w = [bundle objectForInfoDictionaryKey:@"GameWindowWidth"] ?: @1040;
    NSNumber *h = [bundle objectForInfoDictionaryKey:@"GameWindowHeight"] ?: @620;

    NSString *payloadDir = [[bundle.resourcePath
        stringByAppendingPathComponent:payload] stringByStandardizingPath];

    // Served mode: serve.conf routes the payload through the in-app scheme
    // server (optional `index=` line, default index.html).
    NSString *serveIndex = nil;
    NSString *servePath = [payloadDir stringByAppendingPathComponent:@"serve.conf"];
    NSString *serveConf = [NSString stringWithContentsOfFile:servePath
                                                    encoding:NSUTF8StringEncoding error:NULL];
    if (serveConf) {
        serveIndex = @"index.html";
        for (NSString *rawLine in [serveConf componentsSeparatedByCharactersInSet:
                                        [NSCharacterSet newlineCharacterSet]]) {
            NSString *line = [rawLine stringByTrimmingCharactersInSet:
                                        [NSCharacterSet whitespaceCharacterSet]];
            if ([line hasPrefix:@"index="]) { serveIndex = [line substringFromIndex:6]; break; }
        }
        NSString *indexOnDisk = [payloadDir stringByAppendingPathComponent:serveIndex];
        if (![[NSFileManager defaultManager] fileExistsAtPath:indexOnDisk]) {
            fprintf(stderr, "Game files not found: missing %s. "
                    "Reinstall with: brew reinstall <game>\n", indexOnDisk.UTF8String);
            if (getenv("ARI_FLASH_NO_DIALOG")) exit(1);
            NSAlert *a = [NSAlert new];
            a.messageText = @"Game files not found";
            a.informativeText = [NSString stringWithFormat:
                @"Missing %@. Reinstall with: brew reinstall <game>", indexOnDisk];
            [a runModal];
            exit(1);
        }
    }

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
    if (!remote && !serveIndex && ![[NSFileManager defaultManager] fileExistsAtPath:index]) {
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
    if (serveIndex) {
        self.scheme = [PayloadSchemeHandler new];
        self.scheme.root = payloadDir;
        [cfg setURLSchemeHandler:self.scheme forURLScheme:@"ari-flash"];
    }
    WKWebView *web = [[WKWebView alloc] initWithFrame:frame configuration:cfg];
    web.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    if (serveIndex) {
        NSString *u = [NSString stringWithFormat:@"ari-flash://game/%@", serveIndex];
        [web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:u]]];
    } else if (remote) {
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
