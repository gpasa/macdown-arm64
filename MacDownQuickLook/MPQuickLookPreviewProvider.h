//
//  MPQuickLookPreviewProvider.h
//  MacDownQuickLook
//

#import <QuickLookUI/QuickLookUI.h>

// Aperçu Quick Look des fichiers Markdown, rendu avec le style choisi dans
// les préférences de MacDown.
@interface MPQuickLookPreviewProvider : QLPreviewProvider <QLPreviewingController>
@end
