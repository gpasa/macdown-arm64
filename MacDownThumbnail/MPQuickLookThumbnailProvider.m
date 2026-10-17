//
//  MPQuickLookThumbnailProvider.m
//  MacDownThumbnail
//

#import "MPQuickLookThumbnailProvider.h"
#import <AppKit/AppKit.h>
#import "MPQuickLookRendering.h"

// Page virtuelle, mise à l'échelle de la vignette demandée.
static const CGFloat kMPPageWidth = 640.0;
static const CGFloat kMPPageHeight = 828.0;
static const CGFloat kMPPageMargin = 36.0;

static NSAttributedString *MPAttributedPage(NSURL *url)
{
    // L'importeur HTML d'AppKit ne connaît pas les tableaux en bloc
    // défilant : on les rend en tableaux ordinaires.
    NSString *html = [MPQuickLookHTMLDocument(url, NO)
        stringByReplacingOccurrencesOfString:@"</head>"
        withString:@"<style>table { display: table !important; width: auto !important; }"
                   @" body { padding: 0 !important; width: auto !important; }</style></head>"];
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    __block NSAttributedString *result = nil;
    void (^import)(void) = ^{
        result = [[NSAttributedString alloc]
            initWithHTML:data
                 options:@{NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding),
                           NSTimeoutDocumentOption: @5}
      documentAttributes:NULL];
    };
    if (NSThread.isMainThread)
        import();
    else
        dispatch_sync(dispatch_get_main_queue(), import);
    return result;
}

@implementation MPQuickLookThumbnailProvider

- (void)provideThumbnailForFileRequest:(QLFileThumbnailRequest *)request
                     completionHandler:(void (^)(QLThumbnailReply *, NSError *))handler
{
    NSAttributedString *page = MPAttributedPage(request.fileURL);
    if (!page.length)
    {
        handler(nil, nil);
        return;
    }

    CGSize max = request.maximumSize;
    CGFloat scale = MIN(max.width / kMPPageWidth, max.height / kMPPageHeight);
    CGSize size = CGSizeMake(floor(kMPPageWidth * scale),
                             floor(kMPPageHeight * scale));

    QLThumbnailReply *reply = [QLThumbnailReply
        replyWithContextSize:size
        currentContextDrawingBlock:^BOOL {
            NSRect bounds = NSMakeRect(0, 0, size.width, size.height);
            [[NSColor whiteColor] setFill];
            NSRectFill(bounds);

            NSAffineTransform *t = [NSAffineTransform transform];
            [t scaleBy:scale];
            [t concat];

            NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:page];
            NSLayoutManager *layout = [[NSLayoutManager alloc] init];
            NSTextContainer *container = [[NSTextContainer alloc] initWithSize:
                NSMakeSize(kMPPageWidth - 2 * kMPPageMargin,
                           kMPPageHeight - 2 * kMPPageMargin)];
            [layout addTextContainer:container];
            [storage addLayoutManager:layout];

            NSRange glyphs = [layout glyphRangeForTextContainer:container];
            // Dessin dans un contexte retourné : origine en haut à gauche.
            NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
            NSGraphicsContext *flipped = [NSGraphicsContext
                graphicsContextWithCGContext:ctx.CGContext flipped:YES];
            [NSGraphicsContext saveGraphicsState];
            NSGraphicsContext.currentContext = flipped;
            CGContextTranslateCTM(ctx.CGContext, 0, kMPPageHeight);
            CGContextScaleCTM(ctx.CGContext, 1, -1);
            NSPoint origin = NSMakePoint(kMPPageMargin, kMPPageMargin);
            [layout drawBackgroundForGlyphRange:glyphs atPoint:origin];
            [layout drawGlyphsForGlyphRange:glyphs atPoint:origin];
            [NSGraphicsContext restoreGraphicsState];
            return YES;
        }];
    handler(reply, nil);
}

@end
