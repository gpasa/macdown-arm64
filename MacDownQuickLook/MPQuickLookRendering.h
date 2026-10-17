//
//  MPQuickLookRendering.h
//  MacDownQuickLook
//

#import <Foundation/Foundation.h>

NSString *MPReadText(NSURL *url);

// Page HTML complète d'un fichier Markdown, avec le style choisi dans MacDown.
NSString *MPQuickLookHTMLDocument(NSURL *url, BOOL allowSticky);
