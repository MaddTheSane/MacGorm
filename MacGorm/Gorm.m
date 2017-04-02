/* Gorm.m
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003, 2004
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111
 * USA.
 */


#include <GormCore/GormGenericEditor.h>
#include <GormCore/GormPrivate.h>
#include <GormCore/GormFontViewController.h>
#include <GormCore/GormSetNameController.h>
#include <GormCore/GormFunctions.h>
#include <GormCore/GormPluginManager.h>
#include <GormCore/GormDocumentController.h>
#include <GormCore/GormServer.h>

#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#include <GNUstepBase/NSString+GNUstepBase.h>
#include <GormPrefs/GormPrefController.h>

#undef GS_LOCALISATION_BUNDLE
#define GS_LOCALISATION_BUNDLE [NSBundle mainBundle]

NSString * const GormAddClassNotification = @"GormAddClassNotification";
NSString * const GormDeleteClassNotification = @"GormDeleteClassNotification";
NSString * const GormParseClassNotification = @"GormParseClassNotification";

@interface Gorm : NSApplication <IB, Gorm, NSApplicationDelegate>
{
  GormPrefController		*preferencesController;
  GormClassManager			*classManager;
  GormInspectorsManager		*inspectorsManager;
  GormPalettesManager		*palettesManager;
  GormPluginManager			*pluginManager;
  id<IBSelectionOwners>		selectionOwner;
  NSMutableArray	*documents;
  BOOL				isConnecting;
  BOOL				isTesting;
  id             	testContainer;
  id				gormMenu;
  NSMenu			*mainMenu; // saves the main menu...
  NSMenu			*servicesMenu; // saves the services menu...
  NSMenu			*classMenu; // so we can set it for the class view
  NSMenuItem		*guideLineMenuItem;
  NSDictionary		*menuLocations;
  NSImage			*linkImage;
  NSImage			*sourceImage;
  NSImage			*targetImage;
  NSImage			*gormImage;
  NSImage			*testingImage;
  id				connectSource;
  id				connectDestination;
  NSPoint			cascadePoint;
  NSMutableArray	*testingWindows;
  NSSet				*topObjects;
}

// handle notifications the object recieves.
- (void) handleNotification: (NSNotification*)aNotification;
@end

// Handle server protocol methods...
@interface Gorm () <GormServer>
@end

@implementation Gorm
@synthesize testingInterface = isTesting;
@synthesize connecting = isConnecting;

- (id<IBDocuments>) activeDocument
{
  return [[NSDocumentController sharedDocumentController] currentDocument];
}

/*
   NSApp
*/
- (id) init
{
	if (self = [super init]) {
		NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
		NSNotificationCenter	*ndc = [NSDistributedNotificationCenter defaultCenter];
		NSBundle				*bundle = [NSBundle mainBundle];
		NSString				*path;
		NSConnection			*conn = [NSConnection defaultConnection];
		
		linkImage = [[NSImage imageNamed: @"GormLinkImage"] retain];
		sourceImage = [[NSImage imageNamed: @"GormSourceTag"] retain];
		targetImage = [[NSImage imageNamed: @"GormTargetTag"] retain];
		gormImage = [[NSImage imageNamed: @"Gorm"] retain];
		testingImage = [[NSImage imageNamed: @"GormTesting"] retain];
		
		documents = [[NSMutableArray alloc] init];
		// regular notifications...
		[nc addObserver: self
			   selector: @selector(handleNotification:)
				   name: IBSelectionChangedNotification
				 object: nil];
		[nc addObserver: self
			   selector: @selector(handleNotification:)
				   name: IBWillCloseDocumentNotification
				 object: nil];
		
		// distibuted notifications...
		[ndc addObserver: self
				selector: @selector(handleNotification:)
					name: GormAddClassNotification
				  object: nil];
		[ndc addObserver: self
				selector: @selector(handleNotification:)
					name: GormDeleteClassNotification
				  object: nil];
		[ndc addObserver: self
				selector: @selector(handleNotification:)
					name: GormParseClassNotification
				  object: nil];
		
		/*
		 * establish registration domain defaults from file.
		 */
		path = [bundle pathForResource: @"Defaults" ofType: @"plist"];
		if (path != nil) {
			NSDictionary	*dict;
			
			dict = [NSDictionary dictionaryWithContentsOfFile: path];
			if (dict != nil) {
				NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
				
				[defaults registerDefaults: dict];
			}
		}
		
		/*
		 * load the interface...
		 */
		if (![NSBundle loadNibNamed: @"Gorm" owner: self]) {
			NSLog(@"Failed to load interface");
			exit(-1);
		}
		
		/*
		 * Make sure the palettes/plugins managers exist, so that the
		 * editors and inspectors provided in the standard palettes
		 * are available.
		 */
		[self palettesManager];
		[self pluginManager];
		
		/*
		 * set the delegate.
		 */
		[self setDelegate: self];
		
		/*
		 * Start the server
		 */
		[conn setRootObject: self];
		if ([conn registerName: @"GormServer"] == NO) {
			NSLog(@"Could not register GormServer");
		}
	}
	return self;
}


- (void) dealloc
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc removeObserver: self];
  RELEASE(inspectorsManager);
  RELEASE(palettesManager);
  RELEASE(documents);
  RELEASE(classManager);
  [super dealloc];
}

- (void) stop: (id)sender
{
	if(isTesting == NO) {
		[super stop: sender];
	} else {
		[self endTesting: sender];
	}
}

- (BOOL)applicationShouldOpenUntitledFile: (NSApplication *)sender
{
	if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil) ==
		NSWindows95InterfaceStyle) {
		return YES;
	}
	
	return NO;
}

- (BOOL) applicationOpenUntitledFile: (id)sender
{
	GormDocumentController *dc = [NSDocumentController sharedDocumentController];
	// open a new document and build an application type document by default...
	[dc newDocument: sender];
	return YES;
}

- (void) applicationDidFinishLaunching: (NSApplication*)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if ( [defaults boolForKey: @"ShowInspectors"] )
    {
      [[[self inspectorsManager] panel] makeKeyAndOrderFront: self];
    }
  if ( [defaults boolForKey: @"ShowPalettes"] )
    {
      [[[self palettesManager] panel] makeKeyAndOrderFront: self];
    }
}

- (void) applicationWillTerminate: (NSApplication*)sender
{
	[[NSUserDefaults standardUserDefaults]
	 setBool: [[[self inspectorsManager] panel] isVisible]
	 forKey: @"ShowInspectors"];
	[[NSUserDefaults standardUserDefaults]
	 setBool: [[[self palettesManager] panel] isVisible]
	 forKey: @"ShowPalettes"];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (id)sender
{
	if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil) ==
		NSWindows95InterfaceStyle) {
		NSDocumentController *docController;
		docController = [NSDocumentController sharedDocumentController];
		
		if ([[docController documents] count] > 0) {
			return NO;
		} else {
			return YES;
		}
	} else {
		return NO;
	}
}

- (GormClassManager*) classManager
{
	id document = [self activeDocument];
	
	if (document != nil) {
		return [document classManager];
		
		/* kept in the case one want access to the classManager without document */
	} else if (classManager == nil) {
		classManager = [[GormClassManager alloc] init];
	}
	return classManager;
	
}

- (id) connectDestination
{
  return connectDestination;
}

- (id) connectSource
{
  return connectSource;
}

- (void) displayConnectionBetween: (id)source
							  and: (id)destination
{
	NSWindow	*window;
	NSRect		rect;
	
	if (source != connectSource) {
		if (connectSource != nil) {
			window = [(GormDocument *)[self activeDocument] windowAndRect: &rect
																forObject: connectSource];
			if (window != nil) {
				NSView	*view = [[window contentView] superview];
				
				rect.origin.x --;
				rect.size.width ++;
				
				rect.size.height ++;
				
				[window disableFlushWindow];
				[view displayRect: rect];
				
				[window enableFlushWindow];
				[window flushWindow];
			}
		}
		connectSource = source;
	}
	if (destination != connectDestination) {
		if (connectDestination != nil) {
			window = [(GormDocument *)[self activeDocument] windowAndRect: &rect
																forObject: connectDestination];
			if (window != nil) {
				NSView	*view = [[window contentView] superview];
				
				/*
				 * Erase image from old location.
				 */
				rect.origin.x --;
				rect.size.width ++;
				rect.size.height ++;
				
				[view lockFocus];
				[view displayRect: rect];
				[view unlockFocus];
				[window flushWindow];
			}
		}
		connectDestination = destination;
	}
	if (connectSource != nil) {
		window = [(GormDocument *)[self activeDocument] windowAndRect: &rect forObject: connectSource];
		if (window != nil) {
			NSView	*view = [[window contentView] superview];
			NSRect	imageRect = rect;
			
			imageRect.origin.x++;
			//rect.size.width--;
			//rect.size.height--;
			[view lockFocus];
			[[NSColor greenColor] set];
			NSFrameRectWithWidth(rect, 1);
			
			[sourceImage drawAtPoint: imageRect.origin
							fromRect: NSZeroRect
						   operation: NSCompositingOperationSourceOver
							fraction: 1];
			[view unlockFocus];
			[window flushWindow];
		}
	}
	if (connectDestination != nil && connectDestination == connectSource) {
		window = [(GormDocument *)[self activeDocument] windowAndRect: &rect
															forObject: connectDestination];
		if (window != nil) {
			NSView	*view = [[window contentView] superview];
			NSRect	imageRect = rect;
			
			imageRect.origin.x += 3;
			imageRect.origin.y += 2;
			// rect.size.width -= 5;
			// rect.size.height -= 5;
			[view lockFocus];
			[[NSColor purpleColor] set];
			NSFrameRectWithWidth(rect, 1);
			
			imageRect.origin.x += [targetImage size].width;
			
			[targetImage drawAtPoint: imageRect.origin
							fromRect: NSZeroRect
						   operation: NSCompositingOperationSourceOver
							fraction: 1];
			[view unlockFocus];
			[window flushWindow];
		}
	} else if (connectDestination != nil) {
		window = [(GormDocument *)[self activeDocument] windowAndRect: &rect
															forObject: connectDestination];
		if (window != nil) {
			NSView	*view = [[window contentView] superview];
			NSRect	imageRect = rect;
			
			imageRect.origin.x++;
			// rect.size.width--;
			// rect.size.height--;
			[view lockFocus];
			[[NSColor purpleColor] set];
			NSFrameRectWithWidth(rect, 1);
			
			[targetImage drawAtPoint: imageRect.origin
							fromRect: NSZeroRect
						   operation: NSCompositingOperationSourceOver
							fraction: 1];
			[view unlockFocus];
			[window flushWindow];
		}
	}
}

/** Info Menu Actions */
- (void) preferencesPanel: (id) sender
{
	if (!preferencesController) {
		preferencesController =  [[GormPrefController alloc] init];
	}
	
	[[preferencesController panel] makeKeyAndOrderFront:nil];
}

/** Document Menu Actions */
- (void) close: (id)sender
{
	GormDocument  *document = (GormDocument *)[self activeDocument];
	if ([document canCloseDocument]) {
		[document close];
	}
}

- (void) debug: (id) sender
{
	[[self activeDocument] performSelector: @selector(printAllEditors)];
}

- (void) loadSound: (id) sender
{
	[(GormDocument *)[self activeDocument] openSound: sender];
}

- (void) loadImage: (id) sender
{
	[(GormDocument *)[self activeDocument] openImage: sender];
}

- (void) arrangeInFront: (id)sender
{
	if ([self isTestingInterface] == NO) {
		[super arrangeInFront: sender];
	}
}

- (void) testInterface: (id)sender
{
	if (isTesting == YES) {
		return;
	} else {
		// top level objects
		@try {
			NSUserDefaults			*defaults;
			NSNotificationCenter	*notifCenter = [NSNotificationCenter defaultCenter];
			GormDocument			*activeDoc = (GormDocument*)[self activeDocument];
			NSData					*data;
			NSArchiver				*archiver;
			NSDictionary			*substituteClasses = [palettesManager substituteClasses];
			id						savedDelegate = [NSApp delegate];
			
			// which windows were open when testing started...
			testingWindows = [[NSMutableArray alloc] init];
			for (id obj in [self windows]) {
				if ([obj isVisible]) {
					[testingWindows addObject: obj];
				}
			}
			
			// set here, so that beginArchiving and endArchiving do not use templates.
			isTesting = YES;
			[self setApplicationIconImage: testingImage];
			archiver = [[NSArchiver alloc] init];
			[activeDoc deactivateEditors];
			[archiver encodeClassName: @"GormCustomView"
						intoClassName: @"GormTestCustomView"];
			
			// substitute classes from palettes.
			for (NSString *subClassName in substituteClasses) {
				NSString *realClassName = [substituteClasses objectForKey: subClassName];
				
				if ([realClassName isEqualToString: @"NSTableView"] ||
				   [realClassName isEqualToString: @"NSOutlineView"] ||
				   [realClassName isEqualToString: @"NSBrowser"]) {
					continue;
				}
				
				[archiver encodeClassName: subClassName
							intoClassName: realClassName];
			}
			
			// do not allow custom classes during testing.
			[GSClassSwapper setIsInInterfaceBuilder: YES];
			[archiver encodeRootObject: activeDoc];
			data = RETAIN([archiver archiverData]); // Released below...
			[activeDoc reactivateEditors];
			RELEASE(archiver);
			[GSClassSwapper setIsInInterfaceBuilder: NO];
			
			// signal the start of testing...
			[notifCenter postNotificationName: IBWillBeginTestingInterfaceNotification
									   object: self];
			
			if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES) {
				[selectionOwner makeSelectionVisible: NO];
			}
			
			defaults = [NSUserDefaults standardUserDefaults];
			menuLocations = [[defaults objectForKey: @"NSMenuLocations"] copy];
			[defaults removeObjectForKey: @"NSMenuLocations"];
			servicesMenu = [self servicesMenu];
			
			testContainer = [NSUnarchiver unarchiveObjectWithData: data];
			if (testContainer != nil) {
				NSMutableDictionary *nameTable = [testContainer nameTable];
				NSMenu *aMenu = [nameTable objectForKey: @"NSMenu"];
				
				[self setMainMenu: aMenu];
				// initialize the context.
				RETAIN(testContainer);
				topObjects = [testContainer topLevelObjects];
				
				[nameTable removeObjectForKey: @"NSServicesMenu"];
				[nameTable removeObjectForKey: @"NSWindowsMenu"];
				[testContainer awakeWithContext: nil];
				[NSApp setDelegate: savedDelegate]; // makes sure the delegate isn't reset.
				
				/*
				 * If the model didn't have a main menu, create one,
				 * otherwise, ensure that 'quit' ends testing mode.
				 */
				if (aMenu == nil) {
					NSMenu	*testMenu;
					
					testMenu = [[NSMenu alloc] initWithTitle: _(@"Test Menu (Gorm)")];
					[testMenu addItemWithTitle: _(@"Quit Test")
										action: @selector(deferredEndTesting:)
								 keyEquivalent: @"q"];
					[self setMainMenu: testMenu]; // released, when the menu is reset in endTesting.
				} else {
					NSMenu *testMenu = [self mainMenu];
					NSString  *newTitle = [[testMenu title] stringByAppendingString: @" (Gorm)"];
					NSArray *items = findAll(testMenu);
					BOOL found = NO;
					
					for (id item in items) {
						if ([item isKindOfClass: [NSMenuItem class]]) {
							SEL action = [item action];
							if (sel_isEqual(action, @selector(terminate:))) {
								found = YES;
								[item setTitle: _(@"Quit Test")];
								[item setTarget: self];
								[item setAction: @selector(deferredEndTesting:)];
							}
						}
					}
					
					// releast the items...
					RELEASE(items);
					
					// set the menu up so that it's easy to tell we're testing and how to quit.
					[testMenu setTitle: newTitle];
					if (found == NO) {
						[testMenu addItemWithTitle: _(@"Quit Test")
											action: @selector(deferredEndTesting:)
									 keyEquivalent: @"q"];
					}
				}
				
				// so we don't get the warning...
				[self setServicesMenu: nil];
				//[[self mainMenu] display];
				for (id obj in [self windows]) {
					if ([obj isVisible]) {
						[obj makeKeyAndOrderFront: self];
					}
				}
				
				// we're now in testing mode.
				[notifCenter postNotificationName: IBDidBeginTestingInterfaceNotification
										   object: self];
				
				[NSApp unhide: self];
			}
			
			RELEASE(data);
		} @catch (NSException *localException) {
			// reset the application after the error.
			NSLog(@"Problem while testing interface: %@",
				  [localException reason]);
			NSRunAlertPanel(_(@"Problem While Testing Interface"),
							@"Make sure connections are to appropriate objects.\n"
							@"Exception: %@",
							_(@"OK"), nil, nil, [localException reason]);
			[self endTesting: self];
		}
	}
}


/** Edit Menu Actions */

- (void) copy: (id)sender
{
	if ([[selectionOwner selection] count] == 0
		|| [selectionOwner respondsToSelector: @selector(copySelection)] == NO)
		return;
	
	if ([self isConnecting]) {
		[self stopConnecting];
	}
	
	[(id<IBSelectionOwners,IBEditors>)selectionOwner copySelection];
}


- (void) cut: (id)sender
{
	if ([[selectionOwner selection] count] == 0
		|| [selectionOwner respondsToSelector: @selector(copySelection)] == NO
		|| [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO) {
		return;
	}
	
	if ([self isConnecting]) {
		[self stopConnecting];
	}
	
	[(id<IBSelectionOwners,IBEditors>)selectionOwner copySelection];
	[(id<IBSelectionOwners,IBEditors>)selectionOwner deleteSelection];
}

- (void) paste: (id)sender
{
	if ([selectionOwner respondsToSelector: @selector(pasteInSelection)] == NO)
		return;
	
	if ([self isConnecting]) {
		[self stopConnecting];
	}
	
	[(id<IBSelectionOwners,IBEditors>)selectionOwner pasteInSelection];
}


- (void) delete: (id)sender
{
	if ([[selectionOwner selection] count] == 0
		|| [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
		return;
	
	if([self isConnecting]) {
		[self stopConnecting];
	}
	
	[(id<IBSelectionOwners,IBEditors>)selectionOwner deleteSelection];
}

- (void) selectAll: (id)sender
{
	if ([[selectionOwner selection] count] == 0
		|| [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
		return;
	
	if ([self isConnecting]) {
		[self stopConnecting];
	}
	
	[(id<IBSelectionOwners,IBEditors>)selectionOwner deleteSelection];
}

/*
- (void) selectAllItems: (id)sender
{
  return;
}
*/

- (void) setName: (id)sender
{
	GormSetNameController *panel;
	NSInteger		returnPanel;
	NSTextField	*textField;
	NSArray		*selectionArray = [selectionOwner selection];
	id			obj = [selectionArray objectAtIndex: 0];
	NSString		*name;
	
	if ([(GormDocument *)[self activeDocument] isTopLevelObject: obj]) {
		panel = [[GormSetNameController alloc] init];
		returnPanel = [panel runAsModal];
		textField = [panel textField];
		
		if (returnPanel == NSAlertDefaultReturn) {
			name = [[textField stringValue] stringByTrimmingSpaces];
			if (name != nil && [name isEqual: @""] == NO) {
				[[self activeDocument] setName: name forObject: obj];
			}
		}
		RELEASE(panel);
	}
}

- (void) guideline: (id) sender
{
  [[NSNotificationCenter defaultCenter] postNotificationName: GormToggleGuidelineNotification
 					object:nil];
	if ([guideLineMenuItem tag] == 0) {
		[guideLineMenuItem setTitle:_(@"Enable GuideLine")];
		[guideLineMenuItem setTag:1];
	} else if ([guideLineMenuItem tag] == 1) {
		[guideLineMenuItem setTitle:_(@"Disable GuideLine")];
		[guideLineMenuItem setTag:0];
	}
}


- (void) orderFrontFontPanel: (id) sender
{
	NSFontPanel *fontPanel = [NSFontPanel sharedFontPanel];
	GormFontViewController *gfvc =
	[GormFontViewController sharedGormFontViewController];
	[fontPanel setAccessoryView: [gfvc view]];
	[[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}

/** Grouping */

- (void) groupSelectionInSplitView: (id)sender
{
	if ([[selectionOwner selection] count] < 2
		|| [selectionOwner respondsToSelector: @selector(groupSelectionInSplitView)] == NO) {
		return;
	}
	
	[(GormGenericEditor *)selectionOwner groupSelectionInSplitView];
}

- (void) groupSelectionInBox: (id)sender
{
	if ([selectionOwner respondsToSelector: @selector(groupSelectionInBox)] == NO) {
		return;
	}
	[(GormGenericEditor *)selectionOwner groupSelectionInBox];
}

- (void) groupSelectionInView: (id)sender
{
	if ([selectionOwner respondsToSelector: @selector(groupSelectionInView)] == NO) {
		return;
	}
	[(GormGenericEditor *)selectionOwner groupSelectionInView];
}

- (void) groupSelectionInScrollView: (id)sender
{
	if ([selectionOwner respondsToSelector: @selector(groupSelectionInScrollView)] == NO) {
		return;
	}
	[(GormGenericEditor *)selectionOwner groupSelectionInScrollView];
}

- (void) ungroup: (id)sender
{
	// NSLog(@"ungroup: selectionOwner %@", selectionOwner);
	if ([selectionOwner respondsToSelector: @selector(ungroup)] == NO)
		return;
	[(GormGenericEditor *)selectionOwner ungroup];
}

/** Classes actions */

- (void) createSubclass: (id)sender
{
	[(GormDocument *)[self activeDocument] createSubclass: sender];
}

- (void) loadClass: (id)sender
{
	// Call the current document and create the class
	// descibed by the header
	[(GormDocument *)[self activeDocument] loadClass: sender];
}

- (void) createClassFiles: (id)sender
{
	[(GormDocument *)[self activeDocument] createClassFiles: sender];
}

- (void) instantiateClass: (id)sender
{
	[(GormDocument *)[self activeDocument] instantiateClass: sender];
}

- (void) addAttributeToClass: (id)sender
{
	[(GormDocument *)[self activeDocument] addAttributeToClass: sender];
}

- (void) remove: (id)sender
{
	[(GormDocument *)[self activeDocument] remove: sender];
}

/** Palettes Actions... */

- (void) inspector: (id) sender
{
	[[[self inspectorsManager] panel] makeKeyAndOrderFront: self];
}

- (void) palettes: (id) sender
{
	[[[self palettesManager] panel] makeKeyAndOrderFront: self];
}

- (void) loadPalette: (id) sender
{
	[[self palettesManager] openPalette: sender];
}

/** Testing methods... */

- (void) deferredEndTesting: (id) sender
{
	[[NSRunLoop currentRunLoop]
	 performSelector: @selector(endTesting:)
	 target: self
	 argument: nil
	 order: 5000
	 modes: @[NSDefaultRunLoopMode,
			  NSModalPanelRunLoopMode,
			  NSEventTrackingRunLoopMode]];
}

- (id) endTesting: (id)sender
{
	if (isTesting == NO) {
		return nil;
	} else {
		NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
		NSUserDefaults			*defaults;
		
		[nc postNotificationName: IBWillEndTestingInterfaceNotification
						  object: self];
		
		/*
		 * Make sure windows will go away when the container is destroyed.
		 */
		for (id val in topObjects) {
			if ([val isKindOfClass: [NSWindow class]] == YES) {
				[val close];
			}
		}
		
		/*
		 * Make sure any peripheral windows: font panels, etc. which are brought
		 * up by the interface being tested are also closed.
		 */
		for (NSWindow *val in [self windows]) {
			if ([testingWindows containsObject: val] == NO &&
				[val isKindOfClass: [NSWindow class]] &&
				[val isVisible]) {
				[val orderOut: self];
			}
		}
		
		// prevent saving of this, if the menuLocations have not previously been set.
		if (menuLocations != nil) {
			defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject: menuLocations forKey: @"NSMenuLocations"];
			DESTROY(menuLocations);
		}
		
		[self setMainMenu: mainMenu];
		[self setApplicationIconImage: gormImage];
		
		@try {
			[self setServicesMenu: servicesMenu];
		} @catch (NSException *localException) {
			NSDebugLog(@"Exception while setting services menu");
		}
		
		//[mainMenu display]; // bring it to the front...
		isTesting = NO;
		
		if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES){
			[selectionOwner makeSelectionVisible: YES];
		}
		[nc postNotificationName: IBDidEndTestingInterfaceNotification
						  object: self];
		
		
		DESTROY(testingWindows);
		
		// deallocate
		RELEASE(testContainer);
		
		return self;
	}
}

- (void) handleNotification: (NSNotification*)notification
{
	NSString	*name = [notification name];
	id			obj = [notification object];
	
	if ([name isEqual: IBSelectionChangedNotification]) {
		/*
		 * If we are connecting - stop it - a change in selection must mean
		 * that the connection process has ended.
		 */
		if ([self isConnecting] == YES) {
			[self stopConnecting];
		}
		[selectionOwner makeSelectionVisible: NO];
		selectionOwner = obj;
		[[self inspectorsManager] updateSelection];
	} else if ([name isEqual: IBWillCloseDocumentNotification]) {
		selectionOwner = nil;
		[documents removeObjectIdenticalTo: obj];
	} else if ([name isEqual: GormAddClassNotification]) {
		id obj = [notification object];
		[self addClass: obj];
	} else if ([name isEqual: GormDeleteClassNotification]) {
		id obj = [notification object];
		[self deleteClass: obj];
	} else if ([name isEqual: GormParseClassNotification]) {
		NSString *pathToClass = (NSString *)[notification object];
		GormClassManager *cm = [(GormDocument *)[self activeDocument] classManager];
		[cm parseHeader: pathToClass];
	}
}

- (void) awakeFromNib
{
	// set the menu...
	mainMenu = (NSMenu *)gormMenu;
	//for cascadePoint
	cascadePoint = NSZeroPoint;
}


- (GormInspectorsManager*) inspectorsManager
{
	if (inspectorsManager == nil) {
		inspectorsManager = (GormInspectorsManager *)[GormInspectorsManager sharedInspectorManager];
	}
	return inspectorsManager;
}

- (NSImage*) linkImage
{
	return linkImage;
}


- (id) miniaturize: (id)sender
{
	NSWindow	*window = [(GormDocument *)[self activeDocument] window];
	
	[window miniaturize: self];
	return nil;
}

- (GormPalettesManager*) palettesManager
{
	if (palettesManager == nil) {
		palettesManager = [[GormPalettesManager alloc] init];
	}
	return palettesManager;
}

- (GormPluginManager*) pluginManager
{
	if (pluginManager == nil) {
		pluginManager = [[GormPluginManager alloc] init];
	}
	return pluginManager;
}

- (id<IBSelectionOwners>) selectionOwner
{
	return (id<IBSelectionOwners>)selectionOwner;
}

- (id) selectedObject
{
	return [[selectionOwner selection] lastObject];
}

- (id<IBDocuments>) documentForObject: (id)object
{
	id result = nil;
	
	for (id doc in documents) {
		if ([doc containsObject: object]) {
			result = doc;
			break;
		}
	}
	
	return result;
}

- (void) startConnecting
{
	if (isConnecting == YES) {
		return;
	}
	if (connectSource == nil) {
		return;
	}
	if (connectDestination
		&& [[self activeDocument] containsObject: connectDestination] == NO) {
		NSLog(@"Oops - connectDestination not in active document");
		return;
	}
	if ([[self activeDocument] containsObject: connectSource] == NO) {
		NSLog(@"Oops - connectSource not in active document");
		return;
	}
	isConnecting = YES;
	[[self inspectorsManager] updateSelection];
}

- (void) stopConnecting
{
	[self displayConnectionBetween: nil and: nil];
	isConnecting = NO;
	connectSource = nil;
	connectDestination = nil;
}

- (BOOL) validateMenuItem: (NSMenuItem*)item
{
	GormDocument		*active = (GormDocument*)[self activeDocument];
	SEL					action = [item action];
	GormClassManager	*cm = nil;
	NSArray				*s = nil;
	
	// if we have an active document...
	if (active != nil) {
		cm = [active classManager];
		s = [selectionOwner selection];
	}
	
	if (sel_isEqual(action, @selector(close:))
		|| sel_isEqual(action, @selector(miniaturize:))) {
		if (active == nil) {
			return NO;
		}
	} else if (sel_isEqual(action, @selector(testInterface:))) {
		if (active == nil) {
			return NO;
		}
	} else if (sel_isEqual(action, @selector(copy:))) {
		if ([s count] == 0) {
			return NO;
		} else {
			id	    o = [s objectAtIndex: 0];
			NSString *n = [active nameForObject: o];
			if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"]) {
				return NO;
			}
		}
		
		return [selectionOwner respondsToSelector: @selector(copySelection)];
	} else if (sel_isEqual(action, @selector(cut:))) {
		if ([s count] == 0) {
			return NO;
		} else {
			id	    o = [s objectAtIndex: 0];
			NSString *n = [active nameForObject: o];
			if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"]) {
				return NO;
			}
		}
		
		return ([selectionOwner respondsToSelector: @selector(copySelection)]
				&& [selectionOwner respondsToSelector: @selector(deleteSelection)]);
	} else if (sel_isEqual(action, @selector(delete:))) {
		if ([s count] == 0) {
			return NO;
		} else {
			id	    o = [s objectAtIndex: 0];
			NSString *n = [active nameForObject: o];
			if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"]) {
				return NO;
			}
		}
		
		return [selectionOwner respondsToSelector: @selector(deleteSelection)];
	} else if (sel_isEqual(action, @selector(paste:))) {
		if ([s count] == 0) {
			return NO;
		} else {
			id	o = [s objectAtIndex: 0];
			NSString *n = [active nameForObject: o];
			if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"]) {
				return NO;
			}
		}
		
		return [selectionOwner respondsToSelector: @selector(pasteInSelection)];
	} else if (sel_isEqual(action, @selector(setName:))) {
		NSString	*n;
		id	o;
		
		if ([s count] == 0) {
			return NO;
		}
		if ([s count] > 1) {
			return NO;
		}
		o = [s objectAtIndex: 0];
		n = [active nameForObject: o];
		
		if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"]
			|| [n isEqual: @"NSFont"] || [n isEqual: @"NSMenu"]) {
			return NO;
		} else if(![active isTopLevelObject: o]) {
			return NO;
		}
	} else if (sel_isEqual(action, @selector(createSubclass:)) ||
			   sel_isEqual(action, @selector(loadClass:)) ||
			   sel_isEqual(action, @selector(createClassFiles:)) ||
			   sel_isEqual(action, @selector(instantiateClass:)) ||
			   sel_isEqual(action, @selector(addAttributeToClass:)) ||
			   sel_isEqual(action, @selector(remove:))) {
		if (active == nil) {
			return NO;
		}
		
		if(![active isEditingClasses]) {
			return NO;
		}
		
		if (sel_isEqual(action, @selector(createSubclass:))) {
			NSArray *s = [selectionOwner selection];
			id o = nil;
			NSString *name = nil;
			
			if ([s count] == 0 || [s count] > 1) {
				return NO;
			}
			
			o = [s objectAtIndex: 0];
			name = [o className];
			
			if ([active classIsSelected] == NO) {
				return NO;
			}
			
			if ([name isEqual: @"FirstResponder"]) {
				return NO;
			}
		}
		
		if (sel_isEqual(action, @selector(createClassFiles:)) ||
			sel_isEqual(action, @selector(remove:))) {
			id o = nil;
			NSString *name = nil;
			
			if ([s count] == 0) {
				return NO;
			}
			if ([s count] > 1) {
				return NO;
			}
			
			o = [s objectAtIndex: 0];
			name = [o className];
			if (![cm isCustomClass: name]) {
				return NO;
			}
		}
		
		if (sel_isEqual(action, @selector(instantiateClass:))) {
			id o = nil;
			NSString *name = nil;
			
			if ([s count] == 0) {
				return NO;
			}
			if ([s count] > 1) {
				return NO;
			}
			
			if ([active classIsSelected] == NO) {
				return NO;
			}
			
			o = [s objectAtIndex: 0];
			name = [o className];
			if (name != nil) {
				id cm = [self classManager];
				return [cm canInstantiateClassNamed: name];
			}
		}
	} else if (sel_isEqual(action, @selector(loadSound:)) ||
			   sel_isEqual(action, @selector(loadImage:)) ||
			   sel_isEqual(action, @selector(debug:))) {
		if (active == nil) {
			return NO;
		}
	}
	
	return YES;
}

- (NSMenu*) classMenu
{
	return classMenu;
}

- (BOOL) documentNameIsUnique: (NSString *)filename
{
	BOOL unique = YES;
	
	for (id document in documents) {
		NSString *docPath = [document documentPath];
		if ([docPath isEqual: filename]){
			unique = NO;
			break;
		}
	}
	
	return unique;
}

- (void) print: (id) sender
{
	[[self keyWindow] print: sender];
}

#pragma mark - GormServer
// Methods to support external apps adding and deleting
// classes from the current document...
- (void) addClass: (NSDictionary *) dict
{
	GormDocument *doc = (GormDocument *)[self activeDocument];
	GormClassManager *cm = [doc classManager];
	NSArray *outlets = [dict objectForKey: @"outlets"];
	NSArray *actions = [dict objectForKey: @"actions"];
	NSString *className = [dict objectForKey: @"className"];
	NSString *superClassName = [dict objectForKey: @"superClassName"];
	
	// If the class is known, delete it before proceeding.
	if ([cm isKnownClass: className]) {
		[cm removeClassNamed: className];
	}
	
	// Add the class to the class manager.
	[cm addClassNamed: className
  withSuperClassNamed: superClassName
		  withActions: actions
		  withOutlets: outlets];
}

- (void) deleteClass: (NSString *) className
{
	GormDocument *doc = (GormDocument *)[self activeDocument];
	GormClassManager *cm = [doc classManager];
	
	[cm removeClassNamed: className];
}
@end
