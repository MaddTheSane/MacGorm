#ifndef INCLUDED_GormPluginsPref_h
#define INCLUDED_GormPluginsPref_h

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSView.h>

@interface GormPluginsPref : NSObject <NSTableViewDelegate>
{
  id table;
  id addButton;
  id removeButton;
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
