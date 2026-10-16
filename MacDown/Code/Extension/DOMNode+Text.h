//
//  DOMNode+Text.h
//  MacDown
//
//  Created by Tzu-ping Chung on 18/1.
//  Copyright (c) 2015 Tzu-ping Chung . All rights reserved.
//

#import <WebKit/WebKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

struct DOMNodeTextCount
{
    NSUInteger words;
    NSUInteger characters;
    NSUInteger characterWithoutSpaces;
};

typedef struct DOMNodeTextCount DOMNodeTextCount;


@interface DOMNode (Text)

@property (readonly, nonatomic) DOMNodeTextCount textCount;

@end

#pragma clang diagnostic pop
