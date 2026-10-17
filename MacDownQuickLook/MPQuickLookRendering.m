//
//  MPQuickLookRendering.m
//  MacDownQuickLook
//
//  Partagé par l'aperçu et la vignette Quick Look.
//

#import "MPQuickLookRendering.h"
#import <pwd.h>
#import "document.h"
#import "html.h"

static NSString * const kMPMacDownDomain = @"com.uranusjr.macdown";


NS_INLINE id MPMacDownPreference(NSString *key)
{
    CFPropertyListRef value = CFPreferencesCopyAppValue(
        (__bridge CFStringRef)key, (__bridge CFStringRef)kMPMacDownDomain);
    return CFBridgingRelease(value);
}

// NSHomeDirectory() renvoie le conteneur du bac à sable, pas le vrai dossier.
NS_INLINE NSString *MPRealHomeDirectory(void)
{
    struct passwd *pw = getpwuid(getuid());
    return pw ? @(pw->pw_dir) : NSHomeDirectory();
}

NSString *MPReadText(NSURL *url)
{
    if (!url)
        return nil;
    NSString *s = [NSString stringWithContentsOfURL:url
                                           encoding:NSUTF8StringEncoding
                                              error:NULL];
    if (!s)
        s = [NSString stringWithContentsOfURL:url
                                     encoding:NSISOLatin1StringEncoding
                                        error:NULL];
    return s;
}

// Le style choisi dans MacDown, lu dans Application Support ; à défaut,
// GitHub Moderne, embarqué dans l'extension.
static NSString *MPStyleSheetContent(void)
{
    NSString *name = MPMacDownPreference(@"htmlStyleName");
    if ([name isKindOfClass:[NSString class]] && name.length)
    {
        if (![name.pathExtension isEqualToString:@"css"])
            name = [name stringByAppendingPathExtension:@"css"];
        NSString *dir = [MPRealHomeDirectory() stringByAppendingPathComponent:
            @"Library/Application Support/MacDown/Styles"];
        NSString *css = MPReadText(
            [NSURL fileURLWithPath:[dir stringByAppendingPathComponent:name]]);
        if (css.length)
            return css;
    }
    NSURL *fallback = [[NSBundle mainBundle] URLForResource:@"GitHub Moderne"
                                              withExtension:@"css"];
    return MPReadText(fallback) ?: @"";
}

// Retire un en-tête YAML (Jekyll) en tête de fichier.
static NSString *MPStripFrontMatter(NSString *markdown)
{
    if (![markdown hasPrefix:@"---"])
        return markdown;
    NSRegularExpression *re = [NSRegularExpression
        regularExpressionWithPattern:@"\\A---[ \\t]*\\r?\\n.*?\\r?\\n(---|\\.\\.\\.)[ \\t]*(\\r?\\n|\\z)"
                             options:NSRegularExpressionDotMatchesLineSeparators
                               error:NULL];
    NSTextCheckingResult *m = [re firstMatchInString:markdown options:0
                                               range:NSMakeRange(0, markdown.length)];
    return m ? [markdown substringFromIndex:NSMaxRange(m.range)] : markdown;
}

static NSString *MPRenderMarkdown(NSString *markdown)
{
    unsigned int extensions = HOEDOWN_EXT_TABLES | HOEDOWN_EXT_FENCED_CODE
        | HOEDOWN_EXT_FOOTNOTES | HOEDOWN_EXT_AUTOLINK
        | HOEDOWN_EXT_STRIKETHROUGH | HOEDOWN_EXT_HIGHLIGHT
        | HOEDOWN_EXT_SUPERSCRIPT | HOEDOWN_EXT_NO_INTRA_EMPHASIS;
    hoedown_renderer *renderer = hoedown_html_renderer_new(0, 0);
    hoedown_document *document =
        hoedown_document_new(renderer, extensions, 16);
    hoedown_buffer *ob = hoedown_buffer_new(64);

    NSData *data = [markdown dataUsingEncoding:NSUTF8StringEncoding];
    hoedown_document_render(document, ob, data.bytes, data.length);
    NSString *html = [[NSString alloc] initWithBytes:ob->data length:ob->size
                                            encoding:NSUTF8StringEncoding];

    hoedown_buffer_free(ob);
    hoedown_document_free(document);
    hoedown_html_renderer_free(renderer);

    // Listes de tâches, comme dans MacDown.
    NSRegularExpression *task = [NSRegularExpression
        regularExpressionWithPattern:@"<li>(<p>)?\\[([ xX])\\]\\s"
                             options:0 error:NULL];
    NSMutableString *result = [html mutableCopy] ?: [NSMutableString string];
    NSArray *matches = [task matchesInString:result options:0
                                       range:NSMakeRange(0, result.length)];
    for (NSTextCheckingResult *m in matches.reverseObjectEnumerator)
    {
        NSString *p = [m rangeAtIndex:1].location != NSNotFound ? @"<p>" : @"";
        BOOL checked = ![[result substringWithRange:[m rangeAtIndex:2]]
                         isEqualToString:@" "];
        NSString *box = [NSString stringWithFormat:
            @"<li class=\"task-list-item\">%@<input type=\"checkbox\" disabled%@> ",
            p, checked ? @" checked" : @""];
        [result replaceCharactersInRange:m.range withString:box];
    }
    return result;
}



NSString *MPQuickLookHTMLDocument(NSURL *url, BOOL allowSticky)
{
    NSString *markdown = MPReadText(url) ?: @"";
    NSString *body = MPRenderMarkdown(MPStripFrontMatter(markdown));

    NSMutableString *head = [NSMutableString string];
    [head appendFormat:@"<style>%@</style>", MPStyleSheetContent()];
    [head appendString:@"<style>li.task-list-item { list-style: none; }"
                       @" li.task-list-item input { margin: 0 0.4em 0 -1.4em; }"
                       @"</style>"];
    // Sans JavaScript dans Quick Look : la classe est posée d'office
    // et les hauteurs de titre sont des valeurs typiques.
    BOOL sticky = allowSticky
        && [MPMacDownPreference(@"htmlStickyHeaders") boolValue];
    if (sticky)
    {
        NSURL *css = [[NSBundle mainBundle]
            URLForResource:@"sticky-headers" withExtension:@"css"];
        [head appendFormat:@"<style>%@\n:root { --mpd-h1-height: 3.2em;"
                           @" --mpd-pad-left: 30px; --mpd-pad-right: 30px; }"
                           @"</style>", MPReadText(css) ?: @""];
    }
    return [NSString stringWithFormat:
        @"<!DOCTYPE html><html%@><head><meta charset=\"utf-8\">"
        @"<title>%@</title>%@</head><body>%@</body></html>",
        sticky ? @" class=\"mpd-sticky\"" : @"",
        url.lastPathComponent, head, body];
}
