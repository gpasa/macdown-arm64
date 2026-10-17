//
//  MPHtmlPreferencesViewController.m
//  MacDown
//
//  Created by Tzu-ping Chung  on 8/06/2014.
//  Copyright (c) 2014 Tzu-ping Chung . All rights reserved.
//

#import "MPHtmlPreferencesViewController.h"
#import "MPUtilities.h"
#import "MPPreferences.h"
#import <WebKit/WebKit.h>


static NSString * const kMPQuickLookBundleID = @"com.uranusjr.macdown.QuickLook";

static NSString *MPRunTool(NSString *path, NSArray<NSString *> *arguments)
{
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:path];
    task.arguments = arguments;
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = [NSFileHandle fileHandleWithNullDevice];
    if (![task launchAndReturnError:NULL])
        return @"";
    NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
    [task waitUntilExit];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

// pluginkit marque « - » une extension désactivée, « + » ou rien sinon.
static BOOL MPQuickLookEnabled(void)
{
    NSString *out = MPRunTool(@"/usr/bin/pluginkit",
                              @[@"-m", @"-i", kMPQuickLookBundleID]);
    NSString *line = [out stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return line.length && ![line hasPrefix:@"-"];
}

NS_INLINE NSString *MPPrismDefaultThemeName(void)
{
    return NSLocalizedString(@"(Default)", @"Prism theme title");
}


@interface MPHtmlPreferencesViewController ()
@property (weak) IBOutlet NSPopUpButton *stylesheetSelect;
@property (weak) IBOutlet NSSegmentedControl *stylesheetFunctions;
@property (weak) IBOutlet NSPopUpButton *highlightingThemeSelect;
@property (weak) IBOutlet NSButton *scaleCheckbox;
@property (weak) IBOutlet NSTextField *defaultPathLabel;
@property (strong) NSButton *stickyCheckbox;
@property (strong) NSButton *quickLookCheckbox;
@property (strong) WKWebView *stylePreview;
@end


@interface MPHtmlPreferencesViewController () <NSMenuDelegate>
@end


@implementation MPHtmlPreferencesViewController

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"HtmlPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"PreferencesRendering"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Rendering", @"Preference pane title.");
}


#pragma mark - Override

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSSize size = self.view.frame.size;
    [self addStickyCheckbox];
    [self addQuickLookCheckbox];
    [self addStylePreview];
    // Deux cases de plus à gauche, l'aperçu (440 + marge) à droite ; la
    // hauteur suit la colonne de gauche (libellés traduits sur deux lignes).
    NSSize fitting = self.view.fittingSize;
    [self.view setFrameSize:NSMakeSize(size.width + 460,
                                       MAX(fitting.height, size.height + 48))];
    self.stylesheetSelect.menu.delegate = self;
}

- (void)viewWillAppear
{
    [self loadStylesheets];
    [self loadHighlightingThemes];
    self.stickyCheckbox.state = self.preferences.htmlStickyHeaders ?
        NSControlStateValueOn : NSControlStateValueOff;
    self.quickLookCheckbox.state = MPQuickLookEnabled() ?
        NSControlStateValueOn : NSControlStateValueOff;
    [self showPreviewForStyleName:self.preferences.htmlStyleName];
}


#pragma mark - NSMenuDelegate

// Survoler un style dans le menu l'affiche aussitôt dans l'aperçu ;
// fermer le menu revient au style retenu.
- (void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{
    if (item)
        [self showPreviewForStyleName:item.title];
}

- (void)menuDidClose:(NSMenu *)menu
{
    [self showPreviewForStyleName:self.preferences.htmlStyleName];
}


#pragma mark - IBAction

- (IBAction)changeStylesheet:(NSPopUpButton *)sender
{
    NSString *title = sender.selectedItem.title;

    // Special case: the first (empty) item. No stylesheets will be used.
    if (!title.length)
        self.preferences.htmlStyleName = nil;
    else
        self.preferences.htmlStyleName = title;
    [self showPreviewForStyleName:self.preferences.htmlStyleName];
}

- (IBAction)changeQuickLook:(NSButton *)sender
{
    BOOL on = (sender.state == NSControlStateValueOn);
    MPRunTool(@"/usr/bin/pluginkit",
              @[@"-e", on ? @"use" : @"ignore", @"-i", kMPQuickLookBundleID]);
    MPRunTool(@"/usr/bin/qlmanage", @[@"-r"]);
    sender.state = MPQuickLookEnabled() ?
        NSControlStateValueOn : NSControlStateValueOff;
}

- (IBAction)changeStickyHeaders:(NSButton *)sender
{
    self.preferences.htmlStickyHeaders = (sender.state == NSControlStateValueOn);
    [self showPreviewForStyleName:self.preferences.htmlStyleName];
}

- (IBAction)changeHighlightingTheme:(NSPopUpButton *)sender
{
    NSString *title = sender.selectedItem.title;
    if ([title isEqualToString:MPPrismDefaultThemeName()])
        self.preferences.htmlHighlightingThemeName = @"";
    else
        self.preferences.htmlHighlightingThemeName = title;
    [self showPreviewForStyleName:self.preferences.htmlStyleName];
}

- (IBAction)invokeStylesheetFunction:(NSSegmentedControl *)sender
{
    switch (sender.selectedSegment)
    {
        case 0:     // Reveal
        {
            NSString *dirPath = MPDataDirectory(kMPStylesDirectoryName);
            NSURL *url = [NSURL fileURLWithPath:dirPath];
            NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
            [workspace activateFileViewerSelectingURLs:@[url]];
            break;
        }
        case 1:     // Reload
        {
            [self loadStylesheets];
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            [center postNotificationName:MPDidRequestPreviewRenderNotification
                                  object:self];
            break;
        }
        default:
            break;
    }
}


#pragma mark - Private

- (void)addStickyCheckbox
{
    NSString *title = NSLocalizedString(@"Sticky headings and table headers",
                                        @"Preference checkbox");
    NSButton *box = [NSButton checkboxWithTitle:title target:self
                                         action:@selector(changeStickyHeaders:)];
    box.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:box];
    self.stickyCheckbox = box;

    // S'insère entre « Scale preview… » et la ligne du dossier par défaut.
    NSView *above = self.scaleCheckbox;
    NSView *below = self.defaultPathLabel;
    for (NSLayoutConstraint *c in self.view.constraints)
    {
        if (c.firstItem == below && c.firstAttribute == NSLayoutAttributeTop
                && c.secondItem == above)
            c.active = NO;
    }
    [NSLayoutConstraint activateConstraints:@[
        [box.topAnchor constraintEqualToAnchor:above.bottomAnchor constant:6],
        [box.leadingAnchor constraintEqualToAnchor:above.leadingAnchor],
        [below.topAnchor constraintEqualToAnchor:box.bottomAnchor constant:18],
    ]];
}

- (void)addQuickLookCheckbox
{
    NSString *title = NSLocalizedString(@"Quick Look preview in Finder",
                                        @"Preference checkbox");
    NSButton *box = [NSButton checkboxWithTitle:title target:self
                                         action:@selector(changeQuickLook:)];
    box.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:box];
    self.quickLookCheckbox = box;

    NSView *above = self.stickyCheckbox;
    NSView *below = self.defaultPathLabel;
    for (NSLayoutConstraint *c in self.view.constraints)
    {
        if (c.firstItem == below && c.firstAttribute == NSLayoutAttributeTop
                && c.secondItem == above)
            c.active = NO;
    }
    [NSLayoutConstraint activateConstraints:@[
        [box.topAnchor constraintEqualToAnchor:above.bottomAnchor constant:6],
        [box.leadingAnchor constraintEqualToAnchor:above.leadingAnchor],
        [below.topAnchor constraintEqualToAnchor:box.bottomAnchor constant:18],
    ]];
}

- (void)addStylePreview
{
    WKWebView *preview = [[WKWebView alloc] initWithFrame:NSZeroRect];
    preview.translatesAutoresizingMaskIntoConstraints = NO;
    preview.pageZoom = 0.8;
    preview.wantsLayer = YES;
    preview.layer.cornerRadius = 6;
    preview.layer.masksToBounds = YES;
    preview.layer.borderWidth = 1;
    preview.layer.borderColor = [NSColor separatorColor].CGColor;
    [self.view addSubview:preview];
    self.stylePreview = preview;

    // Ce qui touchait le bord droit s'arrête désormais à l'aperçu.
    NSView *root = self.view;
    NSMutableArray *rightmost = [NSMutableArray array];
    for (NSLayoutConstraint *c in root.constraints)
    {
        if (c.firstItem == root && c.firstAttribute == NSLayoutAttributeTrailing
                && c.secondItem != preview)
        {
            [rightmost addObject:c.secondItem];
            c.active = NO;
        }
        else if (c.secondItem == root
                 && c.secondAttribute == NSLayoutAttributeTrailing
                 && c.firstItem != preview)
        {
            [rightmost addObject:c.firstItem];
            c.active = NO;
        }
    }
    for (NSView *view in rightmost)
    {
        [view.trailingAnchor constraintEqualToAnchor:preview.leadingAnchor
                                            constant:-20].active = YES;
    }
    [NSLayoutConstraint activateConstraints:@[
        [preview.topAnchor constraintEqualToAnchor:root.topAnchor constant:20],
        [preview.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-20],
        [preview.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-20],
        [preview.widthAnchor constraintEqualToConstant:440],
        [preview.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:405],
    ]];
}

- (void)showPreviewForStyleName:(NSString *)name
{
    if (!self.stylePreview)
        return;

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *(^read)(NSURL *) = ^NSString *(NSURL *url) {
        if (!url)
            return @"";
        NSString *s = [NSString stringWithContentsOfURL:url
                                               encoding:NSUTF8StringEncoding
                                                  error:NULL];
        return s ?: @"";
    };

    NSMutableString *head = [NSMutableString string];
    NSString *stylePath = name.length ? MPStylePathForName(name) : nil;
    if (stylePath)
    {
        [head appendFormat:@"<style>%@</style>",
            read([NSURL fileURLWithPath:stylePath])];
    }
    if (self.preferences.htmlStickyHeaders)
    {
        NSURL *css = [bundle URLForResource:@"sticky-headers" withExtension:@"css"
                               subdirectory:@"Extensions"];
        NSURL *js = [bundle URLForResource:@"sticky-headers" withExtension:@"js"
                              subdirectory:@"Extensions"];
        [head appendFormat:@"<style>%@</style><script>%@</script>",
            read(css), read(js)];
    }
    // Le code de l'exemple est colorisé avec le thème choisi, comme dans
    // l'aperçu du document.
    NSMutableString *tail = [NSMutableString string];
    if (self.preferences.htmlSyntaxHighlighting)
    {
        NSURL *theme = MPHighlightingThemeURLForName(
            self.preferences.htmlHighlightingThemeName);
        [head appendFormat:@"<style>%@</style>", read(theme)];
        for (NSString *name in @[@"prism-core.min", @"prism-clike.min",
                                 @"prism-swift.min"])
        {
            NSURL *js = [bundle URLForResource:name withExtension:@"js"
                                  subdirectory:@"Prism/components"];
            [tail appendFormat:@"<script>%@</script>", read(js)];
        }
    }
    NSURL *sample = [bundle URLForResource:@"style-preview" withExtension:@"html"
                              subdirectory:@"Data"];
    NSString *html = [NSString stringWithFormat:
        @"<!DOCTYPE html><html><head><meta charset=\"utf-8\">%@</head>"
        @"<body>%@%@</body></html>", head, read(sample), tail];
    [self.stylePreview loadHTMLString:html baseURL:nil];
}

- (void)loadStylesheets
{
    self.stylesheetSelect.enabled = NO;
    [self.stylesheetSelect removeAllItems];

    NSArray *itemTitles = MPListEntriesForDirectory(
        kMPStylesDirectoryName,
        MPFileNameHasExtensionProcessor(kMPStyleFileExtension)
    );

    [self.stylesheetSelect addItemWithTitle:@""];
    [self.stylesheetSelect addItemsWithTitles:itemTitles];

    NSString *title = self.preferences.htmlStyleName;
    if (title.length)
        [self.stylesheetSelect selectItemWithTitle:title];

    self.stylesheetSelect.enabled = YES;
}

- (void)loadHighlightingThemes
{
    self.highlightingThemeSelect.enabled = NO;
    [self.highlightingThemeSelect removeAllItems];

    NSBundle *bundle = [NSBundle mainBundle];
    NSArray *urls = [bundle URLsForResourcesWithExtension:@"css"
                                             subdirectory:@"Prism/themes"];
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSURL *url in urls)
    {
        NSString *name = url.lastPathComponent;
        if (name.length <= 10)
            continue;
        name = [name substringWithRange:NSMakeRange(6, name.length - 10)];
        [titles addObject:[name capitalizedString]];
    }

    [self.highlightingThemeSelect addItemWithTitle:MPPrismDefaultThemeName()];
    [self.highlightingThemeSelect addItemsWithTitles:titles];

    NSString *currentName = self.preferences.htmlHighlightingThemeName;
    if (currentName.length)
        [self.highlightingThemeSelect selectItemWithTitle:currentName];

    if (self.preferences.htmlSyntaxHighlighting)
        self.highlightingThemeSelect.enabled = YES;
}

@end
