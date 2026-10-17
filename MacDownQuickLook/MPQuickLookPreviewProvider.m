//
//  MPQuickLookPreviewProvider.m
//  MacDownQuickLook
//

#import "MPQuickLookPreviewProvider.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "MPQuickLookRendering.h"


@implementation MPQuickLookPreviewProvider

- (void)providePreviewForFileRequest:(QLFilePreviewRequest *)request
                   completionHandler:(void (^)(QLPreviewReply *, NSError *))handler
{
    NSURL *url = request.fileURL;
    QLPreviewReply *reply = [[QLPreviewReply alloc]
        initWithDataOfContentType:UTTypeHTML contentSize:CGSizeMake(820, 1000)
        dataCreationBlock:^NSData *(QLPreviewReply *r, NSError **error) {
            r.title = url.lastPathComponent;
            NSString *html = MPQuickLookHTMLDocument(url, YES);
            return [html dataUsingEncoding:NSUTF8StringEncoding];
        }];
    reply.stringEncoding = NSUTF8StringEncoding;
    handler(reply, nil);
}

@end
