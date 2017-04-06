#ifndef INCLUDED_GormGeneralPref_h
#define INCLUDED_GormGeneralPref_h

#import <Foundation/NSObject.h>
#import <AppKit/NSView.h>
#import <AppKit/NSButton.h>

@interface GormGeneralPref : NSObject
{
  id window;
  NSButton *backupButton;
  id interfaceMatrix;
  NSButton *checkConsistency;
  id _view;
}

/**
 * View to be shown.
 */
- (NSView *) view;

/**
 * Should create a backup file.
 */
- (void) backupAction: (id)sender;

/**
 * Show the classes view as a browser or an outline.
 */
- (void) classesAction: (id)sender;

- (void) consistencyAction: (id)sender;
@end


#endif
