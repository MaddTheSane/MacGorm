#ifndef INCLUDED_GormPalettesPref_h
#define INCLUDED_GormPalettesPref_h

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSView.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSButton.h>

@interface GormPalettesPref : NSObject <NSTableViewDelegate>
{
  id table;
  NSButton *addButton;
  NSButton *removeButton;
  id window;
  id _view;
}

/**
 * View to be shown in the preferences panel.
 */
- (NSView *) view;

/**
 * Add a palette to the list.
 */
- (void) addAction: (id)sender;

/**
 * Remove a palette from the list.
 */
- (void) removeAction: (id)sender;
@end

#endif
