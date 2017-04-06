/* GModelDecoder
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author: Adam Fedor <fedor@gnu.org>
 * Date:   2002
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

#include <AppKit/NSWindow.h>
#include <AppKit/NSNibConnector.h>
#include <Foundation/NSFileWrapper.h>
#include <GNUstepBase/GNUstepBase.h>
#include <GNUstepGUI/GMArchiver.h>
#include <GNUstepGUI/IMLoading.h>
#include <GNUstepGUI/IMCustomObject.h>
//#include <GNUstepGUI/GSDisplayServer.h>
#include <GormCore/GormPrivate.h>
#include <GormCore/GormCustomView.h>
#include <GormCore/GormDocument.h>
#include <GormCore/GormFunctions.h>
#include "GormGModelWrapperLoader.h"
#include <AppKit/NSNibOutletConnector.h>
#include <AppKit/NSNibControlConnector.h>

static Class gmodel_class(NSString *className);

static id gormNibOwner;
static id gormRealObject;
static BOOL gormFileOwnerDecoded;

@interface NSWindow (GormPrivate)
- (void) gmSetStyleMask: (unsigned int)mask;
@end

@implementation NSWindow (GormPrivate)
// private method to change the Window style mask on the fly
- (void) gmSetStyleMask: (unsigned int)mask
{
   _styleMask = mask;
   //[GSServerForWindow(self) stylewindow: mask : [self windowNumber]];
}
@end

@interface NSWindow (GormNSWindowPrivate)
- (unsigned int) _styleMask;
@end

@interface GModelApplication : NSObject
{
  id mainMenu;
  id windowMenu;
  __unsafe_unretained id delegate;
  NSArray *windows;
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver;
- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver;

- mainMenu;
- windowMenu;
- delegate;
- (NSArray *) windows;

@end

@implementation GModelApplication

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSEnumerator *enumerator;
  NSWindow *win;

  mainMenu = [unarchiver decodeObjectWithName:@"mainMenu"];

  windows = [unarchiver decodeObjectWithName:@"windows"];
  enumerator = [windows objectEnumerator];
  while ((win = [enumerator nextObject]) != nil)
    {
      /* Fix up window frames */
      if ([win styleMask] == NSWindowStyleMaskBorderless)
	{
	  NSLog(@"Fixing borderless window %@", win);
	  [win gmSetStyleMask: NSWindowStyleMaskTitled];
	}

      /* Fix up the background color */
      [win setBackgroundColor: [NSColor windowBackgroundColor]];
    }

  delegate = [unarchiver decodeObjectWithName:@"delegate"];

  return self;
}

- (NSArray *) windows
{
  return windows;
}

- mainMenu
{
  return mainMenu;
}

- windowMenu
{
  return windowMenu;
}

- delegate
{
  return delegate;
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return AUTORELEASE([[GModelApplication alloc] init]);
}

@end

@interface GModelMenuTemplate : NSObject
{
  NSString *menuClassName;
  id realObject;
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver;
- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver;
@end

@implementation GModelMenuTemplate
- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  menuClassName = [unarchiver decodeObjectWithName:@"menuClassName"];
  realObject = [unarchiver decodeObjectWithName: @"realObject"];
  // RELEASE(self);
  return realObject;
}

+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return AUTORELEASE([[GModelMenuTemplate alloc] init]);
}
@end

@implementation GormObjectProxy (GModel)
+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return AUTORELEASE([[self alloc] init]);
}

- (id)initWithModelUnarchiver: (GMUnarchiver*)unarchiver
{
  id extension;
  id realObject;

  theClass = RETAIN([unarchiver decodeStringWithName: @"className"]);
  extension = [unarchiver decodeObjectWithName: @"extension"];
  realObject = [unarchiver decodeObjectWithName: @"realObject"];

  //real = [unarchiver representationForName: @"realObject" isLabeled: &label];
  if (!gormFileOwnerDecoded || 
      [realObject isKindOfClass: [GModelApplication class]]) 
    {
      gormFileOwnerDecoded = YES;
      gormNibOwner = self;
      gormRealObject = realObject;
    }  
  return self;
}
@end


@implementation GormCustomView (GModel)
+ (id)createObjectForModelUnarchiver:(GMUnarchiver*)unarchiver
{
  return AUTORELEASE([[self alloc] initWithFrame: NSMakeRect(0,0,10,10)]);
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  NSString *cn;
  id realObject;
  id extension;

  cn = [unarchiver decodeStringWithName: @"className"];
  extension = [unarchiver decodeObjectWithName: @"extension"];
  realObject = [unarchiver decodeObjectWithName: @"realObject"];
  [self setFrame: [unarchiver decodeRectWithName: @"frame"]];
  [self setClassName: cn];

  if (!gormFileOwnerDecoded) 
    {
      gormFileOwnerDecoded = YES;
      gormNibOwner = self;
      gormRealObject = realObject;
   }
  
  return self;
}
@end

@interface GormDocument (GModelLoaderAdditions)
- (void) defineClass: (id)className inFile: (NSString *)path;
- (id) connectionObjectForObject:(id) object;
- (NSDictionary *) processModel: (NSMutableDictionary *)model
						 inPath: (NSString *)path;
@end

@implementation GormDocument (GModelLoaderAdditions)
/* Try to define a possibly custom class that's in the gmodel
   file. This is not information that is contained in the file
   itself. For instance, we don't even know what the superclass
   is, and at best, we could search the connections to see what
   outlets and actions are used.
*/
- (void) defineClass: (id)className inFile: (NSString *)path
{
	NSInteger result;
	NSString *header;
	NSFileManager *mgr;
	NSRange notFound = NSMakeRange(NSNotFound, 0);
	
	if ([classManager isKnownClass: className])
		return;
	
	/* Can we parse a header in this directory? */
	mgr = [NSFileManager defaultManager];
	path = [path stringByDeletingLastPathComponent];
	header = [path stringByAppendingPathComponent: className];
	header = [header stringByAppendingPathExtension: @"h"];
	if ([mgr fileExistsAtPath: header]) {
		result =
		NSRunAlertPanel(_(@"GModel Loading"),
						_(@"Parse %@ to define unknown class %@?"),
						_(@"Yes"), _(@"No"), _(@"Choose File"),
						header, className, nil);
	} else {
		result =
		NSRunAlertPanel(_(@"GModel Loading"),
						_(@"Unknown class %@. Parse header file to define?"),
						_(@"Yes"), _(@"No, Choose Superclass"), nil,
						className, nil);
		if (result == NSAlertDefaultReturn)
			result = NSAlertOtherReturn;
	}
	if (result == NSAlertOtherReturn) {
		NSOpenPanel *opanel = [NSOpenPanel openPanel];
		NSArray	  *fileTypes = [NSArray arrayWithObjects: @"h", @"H", nil];
		opanel.directoryURL = [NSURL fileURLWithPath:path];
		opanel.allowedFileTypes = fileTypes;
		result = [opanel runModal];
		if (result == NSFileHandlingPanelOKButton) {
			header = [[opanel URL] path];
			result = NSAlertDefaultReturn;
		}
	}
	
	// make a guess and warn the user
	if (result != NSAlertDefaultReturn) {
		NSString *superClass = promptForClassName([NSString stringWithFormat: @"Superclass: %@",className],
												  [classManager allClassNames]);
		BOOL added = NO;
		
		// cheesy attempt to determine superclass..
		if(superClass == nil) {
			if ([className isEqual: @"GormCustomView"]) {
				superClass = @"NSView";
			} else if (NSEqualRanges(notFound,[className rangeOfString: @"Window"]) == NO) {
				superClass = @"NSWindow";
			} else if (NSEqualRanges(notFound,[className rangeOfString: @"Panel"]) == NO) {
				superClass = @"NSPanel";
			} else {
				superClass = @"NSObject";
			}
		}
		
		added = [classManager addClassNamed: className
						withSuperClassNamed: superClass
								withActions: [NSMutableArray array]
								withOutlets: [NSMutableArray array]];
		
		// inform the user...
		if(added) {
			NSLog(@"Added class %@ with superclass of %@.", className, superClass);
		} else {
			NSLog(@"Failed to add class %@ with superclass of %@.", className, superClass);
		}
	} else {
		@try {
			if(![classManager parseHeader: header]) {
				NSString *file = [header lastPathComponent];
				NSString *message = [NSString stringWithFormat:
									 _(@"Unable to parse class in %@"),file];
				NSAlert *alert = [[NSAlert alloc] init];
				alert.messageText = _(@"Problem parsing class");
				alert.informativeText = message;
				[alert runModal];
				DESTROY(alert);
			}
		} @catch (NSException *localException) {
			NSString *message = [localException reason];
			NSAlert *alert = [[NSAlert alloc] init];
			alert.messageText = _(@"Problem parsing class");
			alert.informativeText = message;
			[alert runModal];
			DESTROY(alert);
		}
	}
}

/* Replace the proxy with the real object if necessary and make sure there
   is a name for the connection object */
- (id) connectionObjectForObject:(id) object
{
	if (object == nil)
		return nil;
	if (object == gormNibOwner)
		object = filesOwner;
	else
		[self setName: nil forObject: object];
	return object;
}

- (NSDictionary *) processModel: (NSMutableDictionary *)model
						 inPath: (NSString *)path
{
	NSMutableDictionary *customMap = nil;
	NSMutableArray *deleted = [[NSMutableArray alloc] init];
	
	NSLog(@"Processing model...");
	for (id key in model) {
		NSDictionary *obj = [model objectForKey: key];
		if (obj != nil) {
			if ([obj isKindOfClass: [NSDictionary class]]) {
				NSString *objIsa = [(NSMutableDictionary *)obj objectForKey: @"isa"];
				Class cls = NSClassFromString(objIsa);
				
				if (cls == nil) {
					// Remove this class.  It's not defined on GNUstep and it's generally
					// useless.
					if ([objIsa isEqual: @"NSNextStepFrame"]) {
						NSString *subviewsKey = [obj objectForKey: @"subviews"];
						NSDictionary *subviews = [model objectForKey: subviewsKey];
						NSArray *elements = [subviews objectForKey: @"elements"];
						
						for (NSString *svkey in elements) {
							[deleted addObject: svkey];
						}
						
						[deleted addObject: key];
						[deleted addObject: subviewsKey];
						continue;
					}
					
					if([objIsa isEqual: @"NSImageCacheView"]) {
						// this is eliminated in the NSNextStepFrame section above.
						continue;
					}
					
					if([classManager isKnownClass: objIsa] == NO &&
					   [objIsa isEqual: @"IMControlConnector"] == NO &&
					   [objIsa isEqual: @"IMOutletConnector"] == NO &&
					   [objIsa isEqual: @"IMCustomObject"] == NO &&
					   [objIsa isEqual: @"IMCustomView"] == NO) {
						NSString *superClass;
						
						NSLog(@"%@ is not a known class",objIsa);
						[self defineClass: objIsa inFile: path];
						superClass = [classManager superClassNameForClassNamed: objIsa];
						[(NSMutableDictionary *)obj setObject: superClass forKey: @"isa"];
					}
				}
			}
		}
	}
	
	// remove objects marked for deletion the model.
	for (id key in deleted) {
		[model removeObjectForKey: key];
	}
	[deleted release];
	
	return customMap;
}
@end

@implementation GormGModelWrapperLoader
+ (NSString *) fileType
{
  return @"GSGModelFileType";
}

/* importing of legacy gmodel files.*/
- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper withDocument: (GormDocument *) doc
{
	id unarchiver;
	id decoded;
	NSArray *gmobjects;
	NSArray *gmconnections;
	Class u = gmodel_class(@"GMUnarchiver");
	NSString *delegateClass = nil;
	NSData *data = [wrapper regularFileContents];
	NSString *dictString = AUTORELEASE([[NSString alloc] initWithData: data
															 encoding: NSASCIIStringEncoding]);
	NSMutableDictionary *model = [NSMutableDictionary dictionaryWithDictionary:
								  [dictString propertyList]];
	NSString *path = [[wrapper filename] stringByDeletingLastPathComponent];
	
	gormNibOwner = nil;
	gormRealObject = nil;
	gormFileOwnerDecoded = NO;
	/* GModel classes */
	[u decodeClassName: @"NSApplication"     asClassName: @"GModelApplication"];
	[u decodeClassName: @"IMCustomView"      asClassName: @"GormCustomView"];
	[u decodeClassName: @"IMCustomObject"    asClassName: @"GormObjectProxy"];
	/* Gorm classes */
	[u decodeClassName: @"NSMenu"            asClassName: @"GormNSMenu"];
	[u decodeClassName: @"NSWindow"          asClassName: @"GormNSWindow"];
	[u decodeClassName: @"NSPanel"           asClassName: @"GormNSPanel"];
	[u decodeClassName: @"NSBrowser"         asClassName: @"GormNSBrowser"];
	[u decodeClassName: @"NSTableView"       asClassName: @"GormNSTableView"];
	[u decodeClassName: @"NSOutlineView"     asClassName: @"GormNSOutlineView"];
	[u decodeClassName: @"NSPopUpButton"     asClassName: @"GormNSPopUpButton"];
	[u decodeClassName: @"NSPopUpButtonCell" asClassName: @"GormNSPopUpButtonCell"];
	[u decodeClassName: @"NSOutlineView"     asClassName: @"GormNSOutlineView"];
	[u decodeClassName: @"NSMenuTemplate"    asClassName: @"GModelMenuTemplate"];
	[u decodeClassName: @"NSCStringText"     asClassName: @"NSText"];
	
	// process the model to take care of any custom classes...
	[doc processModel: model inPath: path];
	
	// initialize with the property list...
	unarchiver = [[u alloc] initForReadingWithPropertyList: [[model description] propertyList]];
	if (!unarchiver) {
		return NO;
	}
	
	@try {
		decoded = [unarchiver decodeObjectWithName:@"RootObject"];
	} @catch (NSException *localException) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = _(@"GModel Loading");
		alert.informativeText = localException.reason;
		[alert runModal];
		DESTROY(alert);
		return NO;
	}
	gmobjects = [decoded performSelector: @selector(objects)];
	gmconnections = [decoded performSelector: @selector(connections)];
	
	if (gormNibOwner) {
		[doc defineClass: [gormNibOwner className] inFile: path];
		[[document filesOwner] setClassName: [gormNibOwner className]];
	}
	
	/*
	 * Now we merge the objects from the gmodel into our own data
	 * structures.
	 */
	for (id obj in gmobjects) {
		if (obj != gormNibOwner) {
			[doc attachObject: obj toParent: nil];
		}
		
		if([obj isKindOfClass: [GormObjectProxy class]]) {
			if([[obj className] isEqual: @"NSFontManager"]) {
				// if it's the font manager, take care of it...
				[doc setName: @"NSFont" forObject: obj];
				[doc attachObject: obj toParent: nil];
			} else {
				NSLog(@"processing... %@",[obj className]);
				[doc defineClass: [obj className] inFile: path];
			}
		}
	}
	
	// build connections...
	for (id con in gmconnections) {
		NSNibConnector *newcon;
		id source, dest;
		
		source = [doc connectionObjectForObject: [con source]];
		dest   = [doc connectionObjectForObject: [con destination]];
		NSDebugLog(@"connector = %@",con);
		if ([[con className] isEqual: @"IMOutletConnector"]) { // We don't link the gmodel library at compile time...
			newcon = AUTORELEASE([[NSNibOutletConnector alloc] init]);
			if(![[doc classManager] isOutlet: [con label]
									 ofClass: [source className]]) {
				[[doc classManager] addOutlet: [con label]
								forClassNamed: [source className]];
			}
			
			if([[source className] isEqual: @"NSApplication"]) {
				delegateClass = [dest className];
			}
		} else {
			NSString *className = (dest == nil)?(NSString *)@"FirstResponder":(NSString *)[dest className];
			newcon = AUTORELEASE([[NSNibControlConnector alloc] init]);
			
			if(![[doc classManager] isAction: [con label]
									 ofClass: className]) {
				[[doc classManager] addAction: [con label]
								forClassNamed: className];
			}
		}
		
		NSDebugLog(@"conn = %@  source = %@ dest = %@ label = %@, src name = %@ dest name = %@", newcon, source, dest,
				   [con label], [source className], [dest className]);
		[newcon setSource: source];
		[newcon setDestination: (dest != nil)?dest:[doc firstResponder]];
		[newcon setLabel: [con label]];
		[[doc connections] addObject: newcon];
	}
	
	// make sure that all of the actions on the application's delegate object are also added to FirstResponder.
	for (id con in [doc connections]) {
		if ([con isKindOfClass: [NSNibControlConnector class]]) {
			id dest = [con destination];
			if ([[dest className] isEqual: delegateClass]) {
				if(![[doc classManager] isAction: [con label]
										 ofClass: @"FirstResponder"]) {
					[[doc classManager] addAction: [con label]
									forClassNamed: @"FirstResponder"];
				}
			}
		}
	}
	
	if ([gormRealObject isKindOfClass: [GModelApplication class]]) {
		if([gormRealObject respondsToSelector: @selector(windows)]) {
			for (id obj in [gormRealObject windows]) {
				if([obj isKindOfClass: [NSWindow class]]) {
					if([obj _styleMask] == 0) {
						// Skip borderless window.  Borderless windows are
						// sometimes used as temporary objects in nib files,
						// they will show up unless eliminated.
						continue;
					}
				}
				
				[doc attachObject: obj toParent: nil];
			}
			
			if([gormRealObject respondsToSelector: @selector(mainMenu)]) {
				if ([(GModelApplication *)gormRealObject mainMenu]) {
					[doc attachObject: [(GModelApplication *)gormRealObject mainMenu] toParent: nil];
				}
			}
		}
		
	} else if(gormRealObject != nil) {
		// Here we need to addClass:... (outlets, actions).  */
		[doc defineClass: [gormRealObject className] inFile: path];
	} else {
		NSLog(@"Don't understand real object %@", gormRealObject);
	}
	
	[doc rebuildObjToNameMapping];
	
	// clear the changes, since we just loaded the document.
	[document updateChangeCount: NSChangeCleared];
	
	return YES;
}
@end

static NSArray *NSStandardLibraryPaths()
{
	NSArray *libraryURLs = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSAllDomainsMask];
	NSMutableArray *libraryPaths = [NSMutableArray arrayWithCapacity:libraryURLs.count];
	for (NSURL *lib in libraryURLs) {
		[libraryPaths addObject:lib.path];
	}
	return libraryPaths;
}

static 
Class gmodel_class(NSString *className)
{
#if 0
	static Class gmclass = Nil;
	
	if (gmclass == Nil) {
		NSBundle	*theBundle;
		NSString	*path;
		
		/* Find the bundle */
		for (path in NSStandardLibraryPaths()) {
			path = [path stringByAppendingPathComponent: @"Bundles"];
			path = [path stringByAppendingPathComponent: @"libgmodel.bundle"];
			if ([[NSFileManager defaultManager] fileExistsAtPath: path]) {
				break;
			}
			path = nil;
		}
		NSCAssert(path != nil, @"Unable to load gmodel bundle");
		NSDebugLog(@"Loading gmodel from %@", path);
		
		theBundle = [NSBundle bundleWithPath: path];
		NSCAssert(theBundle != nil, @"Can't init gmodel bundle");
		gmclass = [theBundle classNamed: className];
		NSCAssert(gmclass, @"Can't load gmodel bundle");
	}
	return gmclass;
#else
	return NSClassFromString(@"GMUnarchiver");
#endif
}
