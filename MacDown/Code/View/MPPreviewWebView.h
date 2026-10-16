//
//  MPPreviewWebView.h
//  MacDown
//

#import <WebKit/WebKit.h>

@interface MPWeakScriptMessageHandler : NSObject <WKScriptMessageHandler>
@property (weak) id<WKScriptMessageHandler> target;
- (instancetype)initWithTarget:(id<WKScriptMessageHandler>)target;
@end

@interface MPPreviewWebView : WKWebView

+ (WKWebViewConfiguration *)defaultConfiguration;

@end
