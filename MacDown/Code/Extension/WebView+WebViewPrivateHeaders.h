//
//  WebView+WebViewPrivateHeaders.h
//  MacDown
//
//  Created by Jan on 14.07.14.
//  Copyright (c) 2014 Tzu-ping Chung . All rights reserved.
//

#import <WebKit/WebKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

@interface WebView (WebViewPrivateHeaders)

/*!
 @method setPageSizeMultiplier:
 @abstract Change the zoom factor of the page in views managed by this webView.
 @param multiplier A fractional percentage value, 1.0 is 100%.
 */
- (void)setPageSizeMultiplier:(float)multiplier;

/*!
 @method pageSizeMultiplier
 @result The page size multipler.
 */
- (float)pageSizeMultiplier;

@end

#pragma clang diagnostic pop
