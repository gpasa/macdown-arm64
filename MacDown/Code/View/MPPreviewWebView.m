//
//  MPPreviewWebView.m
//  MacDown
//

#import "MPPreviewWebView.h"

@implementation MPWeakScriptMessageHandler

- (instancetype)initWithTarget:(id<WKScriptMessageHandler>)target
{
    self = [super init];
    if (self)
        _target = target;
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self.target userContentController:userContentController
               didReceiveScriptMessage:message];
}

@end


static NSString * const kMPPreviewUserScript = @"(function() {\
window.MathJaxListener = {\
  invokeCallbackForKey_: function(key) {\
    try {\
      window.webkit.messageHandlers.mathjax.postMessage(String(key || ''));\
    } catch (e) {}\
  }\
};\
window.MacDownPreview = {\
  metrics: function() {\
    var root = document.scrollingElement || document.documentElement;\
    var html = document.documentElement;\
    html.classList.add('mpd-measuring');\
    var nodes = Array.prototype.slice.call(\
      document.querySelectorAll('h1, h2, h3, h4, h5, h6, img:only-child'));\
    var offset = root.scrollTop || window.pageYOffset || 0;\
    var headers = nodes.map(function(n) { return n.getBoundingClientRect().top + offset; });\
    html.classList.remove('mpd-measuring');\
    return {\
      headers: headers,\
      scrollTop: offset,\
      scrollHeight: root.scrollHeight || 0,\
      clientHeight: window.innerHeight || 0\
    };\
  },\
  scrollTo: function(y) {\
    var root = document.scrollingElement || document.documentElement;\
    root.scrollTop = y;\
  },\
  bodyBackground: function() {\
    return document.body ? getComputedStyle(document.body).backgroundColor : '';\
  },\
  textCount: function() {\
    function wordsIn(text) {\
      var s = String(text || '');\
      if (!s.trim()) return 0;\
      try {\
        var seg = new Intl.Segmenter(undefined, {granularity: 'word'});\
        var n = 0;\
        for (var part of seg.segment(s)) {\
          if (part.isWordLike) n++;\
        }\
        return n;\
      } catch (e) {\
        return s.trim().split(/\\s+/).filter(Boolean).length;\
      }\
    }\
    function countNode(node) {\
      var type = node.nodeType;\
      if (type === 1 || type === 9 || type === 11) {\
        var tag = (node.tagName || '').toUpperCase();\
        if (tag === 'SCRIPT' || tag === 'STYLE' || tag === 'HEAD')\
          return {words:0, characters:0, characterWithoutSpaces:0};\
        if (tag === 'CODE') {\
          var child = countChildren(node);\
          var inPre = node.parentElement && node.parentElement.tagName === 'PRE';\
          return {\
            words: inPre ? 0 : (child.words ? 1 : 0),\
            characters: child.characters,\
            characterWithoutSpaces: child.characterWithoutSpaces\
          };\
        }\
        return countChildren(node);\
      }\
      if (type === 3 || type === 4) {\
        var text = node.nodeValue || '';\
        return {\
          words: wordsIn(text),\
          characters: text.replace(/[\\n\\r]/g, '').length,\
          characterWithoutSpaces: text.replace(/\\s/g, '').length\
        };\
      }\
      return {words:0, characters:0, characterWithoutSpaces:0};\
    }\
    function countChildren(node) {\
      var total = {words:0, characters:0, characterWithoutSpaces:0};\
      for (var c = node.firstChild; c; c = c.nextSibling) {\
        var r = countNode(c);\
        total.words += r.words;\
        total.characters += r.characters;\
        total.characterWithoutSpaces += r.characterWithoutSpaces;\
      }\
      return total;\
    }\
    return countNode(document);\
  }\
};\
window.addEventListener('scroll', function() {\
  try {\
    var root = document.scrollingElement || document.documentElement;\
    window.webkit.messageHandlers.previewScroll.postMessage(root.scrollTop || 0);\
  } catch (e) {}\
}, {passive: true});\
})();";


@implementation MPPreviewWebView

+ (WKWebViewConfiguration *)defaultConfiguration
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    config.defaultWebpagePreferences.allowsContentJavaScript = YES;
    config.suppressesIncrementalRendering = YES;

    WKUserScript *script =
        [[WKUserScript alloc] initWithSource:kMPPreviewUserScript
                               injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                            forMainFrameOnly:YES];
    [config.userContentController addUserScript:script];

    [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    @try {
        [config setValue:@YES forKey:@"allowUniversalAccessFromFileURLs"];
    } @catch (NSException *exception) {
        (void)exception;
    }
    return config;
}

- (instancetype)initWithFrame:(NSRect)frameRect
                configuration:(WKWebViewConfiguration *)configuration
{
    self = [super initWithFrame:frameRect configuration:configuration];
    if (self)
        [self unregisterDraggedTypes];
    return self;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    return NO;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self unregisterDraggedTypes];
}

@end
