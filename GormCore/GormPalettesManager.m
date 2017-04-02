/* GormPalettesManager.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2004
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include "GormPrivate.h"
#include <Foundation/NSArray.h>
#include <Foundation/NSSet.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSSound.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include "GormFunctions.h"
#include <GNUStepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>


#define BUILTIN_PALETTES @"BuiltinPalettes"
#define USER_PALETTES    @"UserPalettes"

@interface GormPalettePanel : NSPanel
@end

@implementation	GormPalettePanel
/*
- (BOOL) canBecomeKeyWindow
{
  return NO;
}
- (BOOL) canBecomeMainWindow
{
  return YES;
}
*/
@end

@interface GormPaletteView : NSView
{
  NSPasteboard	*dragPb;
}
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL)flag;
@end

@implementation	GormPaletteView

static NSImage	*dragImage = nil;
+ (void) initialize
{
  if (self == [GormPaletteView class])
    {
      // nothing to do...
    }
}

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;	/* Ensure we get initial mouse down event.	*/
}

/*
 *	Initialisation - register to receive DnD with our own types.
 */
- (id) initWithFrame: (NSRect)aFrame
{
  self = [super initWithFrame: aFrame];
  if (self != nil)
    {
      [self registerForDraggedTypes: [NSArray arrayWithObjects:
	IBCellPboardType, IBMenuPboardType, IBMenuCellPboardType,
	IBObjectPboardType, IBViewPboardType, IBWindowPboardType,
        IBFormatterPboardType,nil]];

      [self setAutoresizingMask: 
	      NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(dragPb);
  [super dealloc];
}

/*
 *	Dragging source protocol implementation
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f
{
  NSString	*type = [[dragPb types] lastObject];

  /*
   * Windows and Menus are an exception to the normal DnD mechanism - 
   * we create them if they are dropped anywhere except back in the \
   * pallettes view ie. if they are dragged, but the drop fails.
   */
  if (f == NO && ([type isEqual: IBWindowPboardType] == YES || 
		  [type isEqual: IBMenuPboardType] == YES))
    {
      id<IBDocuments>	active = [(id<IB>)NSApp activeDocument];

      if (active != nil)
	{
          /*
	  if([active objectForName: @"NSMenu"] != nil && 
	     [type isEqual: IBMenuPboardType] == YES)
	    return;
	  */
	  [active pasteType: type fromPasteboard: dragPb parent: nil];
	}
    }
}

- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  return NSDragOperationCopy;
}

/*
 *	Dragging destination protocol implementation
 *
 *	We actually don't handle anything being dropped on the palette,
 *	but we pretend to accept drops from ourself, so that the drag
 *	session quietly terminates - and it looks like the drop has
 *	been successful - this stops windows being created when they are
 *	dropped back on the palette (a window is normally created if the
 *	dnd drop is refused).
 */
- (NSDragOperation) draggingEntered: (id<NSDraggingInfo>)sender
{
  return NSDragOperationCopy;;
}
- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  return YES;
}
- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  return YES;
}


/*
 *	Intercepting events in the view and handling them
 */
- (NSView*) hitTest: (NSPoint)loc
{
  /*
   * Stop the subviews receiving events - we grab them all.
   */
  if ([super hitTest: loc] != nil)
    return self;
  return nil;
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSPoint	dragPoint = [theEvent locationInWindow];
  NSWindow	*w = [self window];
  NSView	*view;
  GormDocument	*active = (GormDocument *)[(id<IB>)NSApp activeDocument];
  NSRect	rect;
  NSString	*type;
  id		obj;
  NSPasteboard	*pb;
  NSImageRep	*rep;
  NSMenu        *menu;

  if ([self superview] != nil)
    {
      dragPoint = [[self superview] convertPoint: dragPoint fromView: nil];
    }
  view = [super hitTest: dragPoint];
  if (view == self || view == nil)
    {
      return;		// No subview to drag.
    }
  /* Make sure we're dragging the proper control and not a subview of a 
     control (like the contentView of an NSBox) */
  while (view != nil && [view superview] != self)
    view = [view superview];
  // this will always get the correct coordinates...
  rect = [[view superview] convertRect: [view frame] toView: nil];

  if (active == nil) {
		NSAlert *alert = [[NSAlert alloc] init];
		//alert.messageText = _(@"Settings");
		alert.informativeText = _(@"No document is currently active");
		[alert runModal];
		DESTROY(alert);

      return;
    }

  RELEASE(dragImage);
  dragImage = [[NSImage alloc] init];
  [dragImage setSize: rect.size];
  rep = [[NSCachedImageRep alloc] initWithSize: rect.size
					 depth: [w depthLimit]
				      separate: YES
					 alpha: [w alphaValue]>0.0 ? YES : NO];
  [dragImage addRepresentation: rep];
  RELEASE(rep);

  /* Copy the contents of the clicked view from our window into the
   * cached image representation.
   * NB. We use lockFocusOnRepresentation: for this because it sets
   * up cached image representation information in the image, and if
   * that's not done before our copy, the image will overwrite our
   * copied data when asked to draw the representation.
   */
  [dragImage lockFocusOnRepresentation: rep];
  NSCopyBits([w gState], rect, NSZeroPoint);
  [dragImage unlockFocus];

  type = [IBPalette typeForView: view];
  obj = [IBPalette objectForView: view];
  pb = [NSPasteboard pasteboardWithName: NSDragPboard];
  ASSIGN(dragPb, pb);
  [active copyObject: obj type: type toPasteboard: pb];
  NSDebugLog(@"type: %@, obj: %@,", type, obj);

  menu = [active objectForName: @"NSMenu"];
  
  [self dragImage: dragImage
	       at: [view frame].origin
	   offset: NSMakeSize(0,0)
	    event: theEvent
       pasteboard: pb
	   source: self
	slideBack: ([type isEqual: IBWindowPboardType] || 
		    ([type isEqual: IBMenuPboardType] && menu == nil)) ? NO : YES];

  // Temporary fix for the art backend.  This is harmless, and
  // shouldn't effect users of xlib, but it's necessary for now
  // so that users can work.
  [self setNeedsDisplay: YES]; 
}
@end


@implementation GormPalettesManager

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(panel);
  RELEASE(bundles);
  RELEASE(palettes);
  RELEASE(importedClasses);
  RELEASE(importedImages);
  RELEASE(importedSounds);
  RELEASE(substituteClasses);
  [super dealloc];
}

- (void) handleNotification: (NSNotification*)aNotification
{
  NSString	*name = [aNotification name];

  if ([name isEqual: IBWillBeginTestingInterfaceNotification] == YES)
    {
      if ([panel isVisible] == YES)
	{
	  hiddenDuringTest = YES;
	  [panel orderOut: self];
	}
    }
  else if ([name isEqual: IBWillEndTestingInterfaceNotification] == YES)
    {
      if (hiddenDuringTest == YES)
	{
	  hiddenDuringTest = NO;
	  [panel orderFront: self];
	}
    }
}

- (id) init
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSScrollView	 *scrollView;
  NSArray	 *array;
  NSRect	 contentRect = {{0, 0}, {272, 266}};
  NSRect	 selectionRect = {{0, 0}, {52, 52}};
  NSRect	 scrollRect = {{0, 192}, {272, 74}};
  NSRect	 dragRect = {{0, 0}, {272, 192}};
  unsigned int	 style = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray        *userPalettes = [defaults arrayForKey: USER_PALETTES];
  
  panel = [[GormPalettePanel alloc] initWithContentRect: contentRect
				     styleMask: style
				       backing: NSBackingStoreRetained
					 defer: NO];
  [panel setTitle: _(@"Palettes")];
  [panel setMinSize: [panel frame].size];

  // allocate arrays and dictionaries.
  bundles = [[NSMutableArray alloc] init];
  palettes = [[NSMutableArray alloc] init];
  importedClasses = [[NSMutableDictionary alloc] init];
  importedImages = [[NSMutableArray alloc] init];
  importedSounds = [[NSMutableArray alloc] init];
  substituteClasses = [[NSMutableDictionary alloc] init];

  scrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: NO];
  [scrollView setAutoresizingMask: NSViewMinYMargin | NSViewWidthSizable];
  [scrollView setBorderType: NSBezelBorder];

  selectionView = [[NSMatrix alloc] initWithFrame: selectionRect
					     mode: NSRadioModeMatrix
					cellClass: [NSImageCell class]
				     numberOfRows: 1
				  numberOfColumns: 0];
  [selectionView setTarget: self];
  [selectionView setAction: @selector(setCurrentPalette:)];
  [selectionView setCellSize: NSMakeSize(52,52)];
  [selectionView setIntercellSpacing: NSMakeSize(0,0)];
  [scrollView setDocumentView: selectionView];
  RELEASE(selectionView);
  [[panel contentView] addSubview: scrollView]; 
  RELEASE(scrollView);

  dragView = [[GormPaletteView alloc] initWithFrame: dragRect];
  [dragView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
  [[panel contentView] addSubview: dragView]; 
  RELEASE(dragView);

  [panel setFrameUsingName: @"Palettes"];
  [panel setFrameAutosaveName: @"Palettes"];
  current = -1;

  array = [[NSBundle mainBundle] pathsForResourcesOfType: @"palette"
					     inDirectory: nil];
   if ([array count] > 0)
    {
      unsigned	index;

      array = [array sortedArrayUsingSelector: @selector(compare:)];

      for (index = 0; index < [array count]; index++)
	{
	  [self loadPalette: [array objectAtIndex: index]];
	}
    }

   // if we have any user palettes load them as well.
   if(userPalettes != nil)
     {
       NSEnumerator *en = [userPalettes objectEnumerator];
       id paletteName = nil;
       while((paletteName = [en nextObject]) != nil)
	 {
	   [self loadPalette: paletteName];
	 }
     }

  /*
   * Select initial palette - this should be the standard controls palette.
   */
  [selectionView selectCellAtRow: 0 column: 2];
  [self setCurrentPalette: selectionView];

  [nc addObserver: self
	 selector: @selector(handleNotification:)
	     name: IBWillBeginTestingInterfaceNotification
	   object: nil];
  [nc addObserver: self
	 selector: @selector(handleNotification:)
	     name: IBWillEndTestingInterfaceNotification
	   object: nil];

  return self;
}

- (BOOL) bundlePathIsLoaded: (NSString *)path
{
  int		col = 0;  
  NSBundle	*bundle;
  for (col = 0; col < [bundles count]; col++)
    {
      bundle = [bundles objectAtIndex: col];
      if ([path isEqualToString: [bundle bundlePath]] == YES)
	{
	  return YES;
	}
    }
  return NO;
}

- (BOOL) loadPalette: (NSString*)path
{
  NSBundle	*bundle;
  NSWindow	*window;
  Class		paletteClass;
  NSDictionary	*paletteInfo;
  NSString	*className;
  NSArray       *exportClasses;
  NSArray       *exportSounds;
  NSArray       *exportImages;
  NSDictionary  *subClasses;
  IBPalette	*palette;
  NSImageCell	*cell;
  NSInteger		col;

  if([self bundlePathIsLoaded: path])
    {
		NSAlert *alert = [[NSAlert alloc] init];
		//alert.messageText = _(@"Settings");
		alert.informativeText = _(@"Palette has already been loaded");
		[alert runModal];
		DESTROY(alert);

      return NO;
    }
  bundle = [NSBundle bundleWithPath: path]; 
  if (bundle == nil)
    {
		NSAlert *alert = [[NSAlert alloc] init];
		//alert.messageText = _(@"Settings");
		alert.informativeText = _(@"Could not load Palette");
		[alert runModal];
		DESTROY(alert);

      return NO;
    }

  path = [bundle pathForResource: @"palette" ofType: @"table"];
  if (path == nil)
    {
		NSAlert *alert = [[NSAlert alloc] init];
		//alert.messageText = _(@"Settings");
		alert.informativeText = _(@"File 'palette.table' missing");
		[alert runModal];
		DESTROY(alert);

      return NO;
    }

  // attempt to load the palette table in either the strings or plist format.
  @try
    {
      paletteInfo = [[NSString stringWithContentsOfFile: path usedEncoding: NULL error: NULL] propertyList];
      if (paletteInfo == nil)
	{
	  paletteInfo = [[NSString stringWithContentsOfFile: path usedEncoding: NULL error: NULL] propertyListFromStringsFileFormat];
	  if(paletteInfo == nil)
	    {
			NSAlert *alert = [[NSAlert alloc] init];
			alert.messageText = _(@"Problem Loading Palette");
			alert.informativeText = _(@"Failed to load 'palette.table' using strings or property list format.");
			[alert runModal];
			DESTROY(alert);

	      return NO;
	    }
	}
    }
  @catch (NSException *localException)
    {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = _(@"Problem Loading Palette");
		alert.informativeText = [NSString stringWithFormat:
								 _(@"Encountered exception %@ attempting to load 'palette.table'."),
								 [localException reason]];
		[alert runModal];
		DESTROY(alert);

      return NO;
    }

  className = [paletteInfo objectForKey: @"Class"];
  if (className == nil)
    {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = _(@"Problem Loading Palette");
		alert.informativeText = _(@"No palette class in 'palette.table'");
		[alert runModal];
		DESTROY(alert);

      return NO;
    }

  paletteClass = [bundle classNamed: className];
  if (paletteClass == 0)
    {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = _(@"Problem Loading Palette");
		alert.informativeText = _(@"Could not load palette class");
		[alert runModal];
		DESTROY(alert);

      return NO;
    }

  palette = [[paletteClass alloc] init];
  if ([palette isKindOfClass: [IBPalette class]] == NO)
    {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = _(@"Problem Loading Palette");
		alert.informativeText = _(@"Palette contains wrong type of class");
		[alert runModal];
		DESTROY(alert);
      RELEASE(palette);
      return NO;
    }

  // add to the bundles list...
  [bundles addObject: bundle];	

  exportClasses = [paletteInfo objectForKey: @"ExportClasses"];
  if(exportClasses != nil)
    {
      [self importClasses: exportClasses withDictionary: nil];
    }

  exportImages = [paletteInfo objectForKey: @"ExportImages"];
  if(exportImages != nil)
    {
      [self importImages: exportImages withBundle: bundle];
    }

  exportSounds = [paletteInfo objectForKey: @"ExportSounds"];
  if(exportSounds != nil)
    {
      [self importSounds: exportSounds withBundle: bundle];
    }

  subClasses = [paletteInfo objectForKey: @"SubstituteClasses"];
  if(subClasses != nil)
    {
      [substituteClasses addEntriesFromDictionary: subClasses];
    }

  [palette finishInstantiate];
  window = [palette originalWindow];
  [window setExcludedFromWindowsMenu: YES];

  // Resize the window appropriately so that we don't have issues
  // with scrolling.
  if([window styleMask] & NSWindowStyleMaskBorderless)
    {
      [window setFrame: NSMakeRect(0,0,272,160) display: NO];
    }
  else
    {
      [window setFrame: NSMakeRect(0,0,272,192) display: NO];
    }

  [palettes addObject: palette];
  [selectionView addColumn];
  [[palette paletteIcon] setBackgroundColor: [selectionView backgroundColor]];
  col = [selectionView numberOfColumns] - 1;
  cell = [selectionView cellAtRow: 0 column: col];
  [cell setImageFrameStyle: NSImageFrameButton];
  [cell setImage: [palette paletteIcon]];
  [selectionView sizeToCells];
  [selectionView selectCellAtRow: 0 column: col];
  [self setCurrentPalette: selectionView];
  RELEASE(palette);

  return YES;
}

- (id) openPalette: (id) sender
{
	NSArray			*fileTypes = [NSArray arrayWithObject: @"palette"];
	NSOpenPanel		*oPanel = [NSOpenPanel openPanel];
	NSInteger		result;
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	NSArray			*userPalettes = [defaults arrayForKey: USER_PALETTES];
	NSMutableArray	*newUserPalettes =
	(userPalettes == nil)?[NSMutableArray array]:[NSMutableArray arrayWithArray: userPalettes];
	
	[oPanel setAllowsMultipleSelection: YES];
	[oPanel setCanChooseFiles: YES];
	[oPanel setCanChooseDirectories: NO];
	oPanel.directoryURL = [NSURL fileURLWithPath:NSHomeDirectory()];
	oPanel.allowedFileTypes = fileTypes;
	result = [oPanel runModal];
	
	if (result == NSFileHandlingPanelOKButton) {
		for (NSURL *aURL in oPanel.URLs) {
			NSString *aFile = [aURL path];
			
			if([self bundlePathIsLoaded: aFile] == YES &&
			   [userPalettes containsObject: aFile] == NO){
				// This is done here so that, if we try to reload a palette
				// that has previously been deleted during this session that
				// the palette manager won't fail, but it will simply add
				// the palette back in.  If this returns NO, then we should
				// flag a problem otherwise it's successful if the palette is
				// already in the bundles array.  This is to address bug#15989.
				[newUserPalettes addObject: aFile];
			} else if([self loadPalette: aFile] == NO) {
				return nil;
			} else {
				[newUserPalettes addObject: aFile];
			}
		}
		
		// reset the defaults to include the new palette.
		[defaults setObject: newUserPalettes forKey: USER_PALETTES];
		return self;
	}
	return nil;
}

- (NSPanel*) panel
{
  return panel;
}

- (void) setCurrentPalette: (id)anObj
{
	NSView	*wv;
	NSEnumerator	*enumerator;
	
	if (current >= 0) {
		/*
		 * Move the views in the drag view back to the content view of the
		 * window they originally came from.
		 */
		wv = [[[palettes objectAtIndex: current] originalWindow] contentView];
		enumerator = [[dragView subviews] objectEnumerator];
		for (NSView *sv in [dragView subviews]) {
			RETAIN(sv);
			[sv removeFromSuperview];
			[wv addSubview: sv];
			RELEASE(sv);
		}
	}
	
	current = [anObj selectedColumn];
	if (current >= 0 && current < [palettes count]) {
		id palette = [palettes objectAtIndex: current];
		
		/*
		 * Set the window title to reflect the palette selection.
		 */
		[panel setTitle: [NSString stringWithFormat: @"Palettes (%@)",
						  [palette className]]];
		
		/*
		 * Move the views from their original window into our drag view.
		 * Resize our drag view to the right size fitrst.
		 */
		wv = [[palette originalWindow] contentView];
		if (wv)
			[dragView setFrameSize: [wv frame].size];
		enumerator = [[wv subviews] objectEnumerator];
		for (NSView *sv in wv.subviews) {
			RETAIN(sv);
			[sv removeFromSuperview];
			[dragView addSubview: sv];
			RELEASE(sv);
		}
	} else {
		NSLog(@"Bad palette selection - %d", (int)[anObj selectedColumn]);
		current = -1;
	}
	[dragView setNeedsDisplay: YES];
}

- (NSMutableArray *) actionsForClass: (Class) cls
{
	NSArray *methodArray = _GSObjCMethodNamesForClass(cls, NO);
	NSMethodSignature *actionSig = [NSMethodSignature signatureWithObjCTypes: "v12@0:4@8"];
	NSMutableArray *actionsArray = [NSMutableArray array];
	NSRange setRange = NSMakeRange(0,3);
	
	for (NSString *methodName in methodArray) {
		SEL sel = NSSelectorFromString(methodName);
		NSMethodSignature *signature = [cls instanceMethodSignatureForSelector: sel];
		if([signature numberOfArguments] == 3) {
			if([actionSig isEqual: signature] && NSEqualRanges([methodName rangeOfString: @"set"], setRange) == NO &&
			   [methodName isEqual: @"encodeWithCoder:"] == NO && [methodName isEqual: @"mouseDown:"] == NO) {
				[actionsArray addObject: methodName];
			}
		}
	}
	
	return actionsArray;
}

- (NSMutableArray *) outletsForClass: (Class) cls
{
	NSArray *methodArray = _GSObjCMethodNamesForClass(cls, NO);
	NSMethodSignature *outletSig = [NSMethodSignature signatureWithObjCTypes: "v12@0:4@8"];
	NSMutableArray *outletsArray = [[NSMutableArray alloc] init];
	NSRange setRange = NSMakeRange(0,3);
	
	for (NSString *methodName in methodArray) {
		SEL sel = NSSelectorFromString(methodName);
		NSMethodSignature *signature = [cls instanceMethodSignatureForSelector: sel];
		if([signature numberOfArguments] == 3) {
			if([outletSig isEqual: signature] && NSEqualRanges([methodName rangeOfString: @"set"], setRange) == YES &&
			   [methodName isEqual: @"encodeWithCoder:"] == NO && [methodName isEqual: @"mouseDown:"] == NO) {
				NSRange range = NSMakeRange(3,([methodName length] - 4));
				NSString *outletMethod = [[methodName substringWithRange: range] lowercaseString];
				if([methodArray containsObject: outletMethod]) {
					[outletsArray addObject: outletMethod];
				}
			}
		}
	}
	
	return [outletsArray autorelease];
}

- (void) importClasses: (NSArray *)classes withDictionary: (NSDictionary *)dict
{
	NSMutableDictionary *masterDict = [NSMutableDictionary dictionary];
	
	// import the classes.
	for (id className in classes) {
		NSMutableDictionary *classDict = [NSMutableDictionary dictionary];
		Class cls = NSClassFromString(className);
		Class supercls = [cls superclass];
		NSString *superClassName = NSStringFromClass(supercls);
		NSMutableArray *actions = [self actionsForClass: cls];
		NSMutableArray *outlets = [self outletsForClass: cls];
		
		// if the superclass is defined, set it.  if not, don't since
		// this might be a palette which adds a root class.
		if (superClassName != nil) {
			[classDict setObject: superClassName forKey: @"Super"];
		}
		
		// set the action/outlet keys
		if (actions != nil) {
			[classDict setObject: actions forKey: @"Actions"];
		}
		if (outlets != nil) {
			[classDict setObject: outlets forKey: @"Outlets"];
		}
		
		[masterDict setObject: classDict forKey: className];
	}
	
	// override any elements needed, if it's present.
	if (dict != nil) {
		[masterDict addEntriesFromDictionary: dict];
	}
	
	// add the classes to the dictionary...
	[importedClasses addEntriesFromDictionary: masterDict];
}

- (NSDictionary *) importedClasses
{
  return importedClasses;
}

- (void) importImages: (NSArray *)images withBundle: (NSBundle *) bundle
{
  NSEnumerator *en = [images objectEnumerator];
  id name = nil;
  NSMutableArray *paths = [NSMutableArray array];

  while((name = [en nextObject]) != nil)
    {
      NSString *path = [bundle pathForImageResource: name];
      [paths addObject: path];
    }

  [importedImages addObjectsFromArray: paths];
}

- (NSArray *) importedImages
{
  return importedImages;
}

- (void) importSounds: (NSArray *)sounds withBundle: (NSBundle *) bundle
{
	NSMutableArray *paths = [NSMutableArray array];
	
	for (id name in sounds) {
		NSString *path = [bundle pathForSoundResource: name];
		[paths addObject: path];
	}
	
	[importedSounds addObjectsFromArray: paths];
}

- (NSArray *) importedSounds
{
  return importedSounds;
}

- (NSDictionary *) substituteClasses
{
  return substituteClasses;
}
@end
