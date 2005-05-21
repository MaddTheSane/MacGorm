/* GormClassEditor.m
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GormClassEditor.h"
#include "GormClassManager.h"
#include "GormFunctions.h"
#include "GormDocument.h"
#include "GormProtocol.h"
#include "GormPrivate.h"

NSString *GormClassPboardType = @"GormClassPboardType";
NSString *GormSwitchViewPreferencesNotification = @"GormSwitchViewPreferencesNotification";

@interface GormOutlineView (PrivateMethods)
- (void) _addNewActionToObject: (id)item;
- (void) _addNewOutletToObject: (id)item;
@end

@interface GormClassEditor (PrivateMethods)
- (void) browserClick: (id)sender;
- (void) switchView;
- (void) handleNotification: (NSNotification *)notification;
@end

@implementation	GormClassEditor

- (GormClassEditor*) initWithDocument: (GormDocument*)doc
{
  self = [super init];
  if (self != nil)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSRect			scrollRect = {{0, 0}, {340, 188}};
      NSRect			mainRect = {{20, 0}, {320, 188}};
      NSColor *salmonColor = 
	[NSColor colorWithCalibratedRed: 0.850980 
		 green: 0.737255
		 blue: 0.576471
		 alpha: 1.0 ];
      NSTableColumn  *tableColumn;
      
      // eliminate the border and title.
      [self setBorderType: NSNoBorder];
      [self setTitlePosition: NSNoTitle];

      // set up the scroll view.
      scrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
      [scrollView setHasVerticalScroller: YES];
      [scrollView setHasHorizontalScroller: NO];
      [scrollView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
      [scrollView setBorderType: NSBezelBorder];
	  
      // allocate the outline view.
      outlineView = [[GormOutlineView alloc] init];
      [outlineView setFrame: mainRect];
      [outlineView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
      [scrollView setDocumentView: outlineView];
      RELEASE(outlineView);

      // RELEASE(scrollView);

      // weak connections...
      document = doc; 
      classManager = [doc classManager];

      // set up the outline view...
      [outlineView setDataSource: self];
      [outlineView setDelegate: self];
  
      [outlineView setAutoresizesAllColumnsToFit: YES];
      [outlineView setAllowsColumnResizing: NO];
      [outlineView setDrawsGrid: NO];
      [outlineView setIndentationMarkerFollowsCell: YES];
      [outlineView setAutoresizesOutlineColumn: YES];
      [outlineView setIndentationPerLevel: 10];
      [outlineView setAttributeOffset: 30];
      [outlineView setRowHeight: 18];
      [outlineView setMenu: [(id<Gorm>)NSApp classMenu]]; 
      [outlineView setBackgroundColor: salmonColor];

      // add the table columns...
      tableColumn = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: @"classes"];
      [[tableColumn headerCell] setStringValue: _(@"Classes")];
      [tableColumn setMinWidth: 190];
      [tableColumn setResizable: YES];
      [tableColumn setEditable: YES];
      [outlineView addTableColumn: tableColumn];     
      [outlineView setOutlineTableColumn: tableColumn];
      RELEASE(tableColumn);
      
      tableColumn = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: @"outlets"];
      [[tableColumn headerCell] setStringValue: _(@"Outlet")];
      [tableColumn setWidth: 50]; 
      [tableColumn setResizable: NO];
      [tableColumn setEditable: NO];
      [outlineView addTableColumn: tableColumn];
      [outlineView setOutletColumn: tableColumn];
      RELEASE(tableColumn);
      
      tableColumn = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier: @"actions"];
      [[tableColumn headerCell] setStringValue: _(@"Action")];
      [tableColumn setWidth: 50]; 
      [tableColumn setResizable: NO];
      [tableColumn setEditable: NO];
      [outlineView addTableColumn: tableColumn];
      [outlineView setActionColumn: tableColumn];
      RELEASE(tableColumn); 

      // expand all of the items in the classesView...
      [outlineView expandItem: @"NSObject"];

      // allocate the NSBrowser view.
      browserView = [[NSBrowser alloc] initWithFrame: mainRect];
      [browserView setRefusesFirstResponder:YES];
      [browserView setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
      [browserView setTitled:NO];
      [browserView setMaxVisibleColumns:3];
      [browserView setSeparatesColumns:NO];
      [browserView setAllowsMultipleSelection:YES];
      [browserView setDelegate:self];
      [browserView setTarget:self];
      [browserView setAction: @selector(browserClick:)];
      // [browserView setDoubleAction: nil]; // @selector(doubleClick:)];
      [browserView setRefusesFirstResponder:YES];
      [browserView loadColumnZero];

      
      // observe certain notifications...
      [nc addObserver: self
	  selector: @selector(handleNotification:)
	  name: GormSwitchViewPreferencesNotification
	  object: nil];
      
      // switch...
      [self switchView];

      // register for types...
      [IBResourceManager registerForAllPboardTypes: self
			 inDocument: document];

    }
  return self;
}

+ (GormClassEditor*) classEditorForDocument: (GormDocument*)doc
{
  return AUTORELEASE([(GormClassEditor *)[self alloc] initWithDocument: doc]);
}

- (void) switchView
{
  NSString *viewType = [[NSUserDefaults standardUserDefaults] stringForKey: @"ClassViewType"];

  [self setContentViewMargins: NSZeroSize];
  if([viewType isEqual: @"Outline"] || viewType == nil)
    {
      NSRect rect = [[self superview] frame];
      // NSRect old = rect;

      // reset the origin...
      // rect.origin.x = 0;
      // rect.origin.y = 0;

      [self setContentView: scrollView];
      // [scrollView setFrame: old];
      // [outlineView setFrame: rect];
      
      [self sizeToFit];
      [[self superview] setFrame: rect];
      // [scrollView setFrame: rect];

     }
  else if([viewType isEqual: @"Browser"])
    {
      [self setContentView: browserView];
      [self sizeToFit];
    }
}

- (void) handleNotification: (NSNotification *)notification
{
  [self switchView];
}

- (void) browserClick: (id)sender
{
  NSString *className = [[sender selectedCell] stringValue];
  ASSIGN(selectedClass, className);
  [document setSelectionFromEditor: (id)self];
}

- (void) dealloc
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver: self];
  RELEASE(scrollView);
  RELEASE(browserView);
  RELEASE(selectedClass);
  [super dealloc];
}

- (void) setSelectedClassName: (NSString*)cn
{
  [self selectClass: cn];
}

- (NSString *)selectedClassName
{
  id className = nil;

  if([self contentView] == scrollView)
    {
      int row = [outlineView selectedRow];
      className = [outlineView itemAtRow: row];
      
      if ([className isKindOfClass: [GormOutletActionHolder class]])
	{
	  className = [outlineView itemBeingEdited];
	}
    }
  else if([self contentView] == browserView)
    {
      className = [[browserView selectedCell] stringValue];
    }

  return className;
}

- (void) selectClass: (NSString *)className
{
  [self selectClass: className editClass: YES];
}

// class selection...
- (void) selectClass: (NSString *)className editClass: (BOOL)flag
{
  NSString	*currentClass = nil;
  NSArray	*classes, *subclasses;
  NSEnumerator	*en;
  int		row = 0;
  int           col = 0;

  // abort, if we're editing a class.
  if([outlineView isEditing])
    {
      return;
    }
  
  if(className != nil)
    {
      if([className isEqual: @"CustomView"] || 
	 [className isEqual: @"GormSound"] || 
	 [className isEqual: @"GormImage"])
	{
	  return; // return only if it is a special class name...
	}
    }
  else
    {
      return; // return if it is nil
    }
  
  classes = [classManager allSuperClassesOf: className]; 
  en = [classes objectEnumerator];
  // open the items...
  while ((currentClass = [en nextObject]) != nil)
    {
      [outlineView expandItem: currentClass];
    }
  
  // select the item in the outline view...
  row = [outlineView rowForItem: className];
  if (row != NSNotFound)
    {
      [outlineView selectRow: row byExtendingSelection: NO];
      [outlineView scrollRowToVisible: row];
    }

  // select class in browser...
  subclasses = [classManager subClassesOf: [classManager superClassNameForClassNamed: className]];
  row = [subclasses indexOfObject: className];
  col = [classes count];
  if(col > 0)
    {
      [browserView reloadColumn: col];
      if(col > 1)
	{
	  [browserView reloadColumn: col - 1]; 
	}
    }
  [browserView selectRow: row inColumn: col];

  if(flag)
    {
      // set the editor...
      ASSIGN(selectedClass, className);
      [document setSelectionFromEditor: (id)self];
    }
}

- (void) selectClassWithObject: (id)obj 
{
  [self selectClassWithObject: obj editClass: YES];
}

- (void) selectClassWithObject: (id)object editClass: (BOOL)flag
{
  id obj = object;
  NSString *customClass = nil;

  // if it's a scrollview focus on it's contents.
  if([obj isKindOfClass: [NSScrollView class]])
    {
      id newobj = nil;
      newobj = [obj documentView];
      if(newobj != nil)
	{
	  obj = newobj;
	}
    }
  
  // check for a custom class.
  customClass = [classManager customClassForObject: obj];
  if(customClass != nil)
    {
      [self selectClass: customClass editClass: flag];
    }
  else if ([obj respondsToSelector: @selector(className)])
    { 
      [self selectClass: [obj className] editClass: flag];
    }
}

- (BOOL) currentSelectionIsClass
{  
  BOOL result = NO;

  if([self contentView] == scrollView)
    {
      int i = [outlineView selectedRow];
      
      if (i >= 0 && i <= ([outlineView numberOfRows] - 1))
	{
	  id object = [outlineView itemAtRow: i];
	  if([object isKindOfClass: [NSString class]])
	    {
	      result = YES;
	    }
	}
    }
  else if([self contentView] == browserView)
    {
      result = YES;
    }

  return result;
}

- (void) editClass
{
  int	row = [outlineView selectedRow];

  if (row >= 0)
    {
      ASSIGN(selectedClass, [self selectedClassName]);
      [document setSelectionFromEditor: (id)self];
    }
}

- (void) createSubclass
{
  if (![outlineView isEditing])
    {
      NSString *itemSelected = [self selectedClassName];
      
      if(itemSelected != nil)
	{
	  NSString *newClassName;

	  newClassName = [classManager addClassWithSuperClassName:
					 itemSelected];
	  if(newClassName != nil)
	    {
	      int i = 0;
	      if([self contentView] == scrollView)
		{
		  [outlineView reloadData];
		  [outlineView expandItem: itemSelected];
		  i = [outlineView rowForItem: newClassName]; 
		  [outlineView selectRow: i byExtendingSelection: NO];
		  [outlineView scrollRowToVisible: i];
		}
	      else if([self contentView] == browserView)
		{
		  [self selectClass: newClassName editClass: NO];
		}
	    }
	  else
	    {
	      // inform the user of this error.
	      NSRunAlertPanel(_(@"Cannot instantiate"), 
			      _(@"FirstResponder cannot be instantiated."),
			      nil, nil, nil);
	    }
	}
    }
}

//--- IBSelectionOwners protocol ---
- (unsigned) selectionCount
{
  return ([outlineView selectedRow] == -1)?0:1;
}

- (NSArray*) selection
{
  // when asked for a selection, it returns a class proxy
  if (selectedClass != nil) 
    {
      NSArray		*array;
      GormClassProxy	*classProxy;

      classProxy = [[GormClassProxy alloc] initWithClassName:
	selectedClass];
      array = [NSArray arrayWithObject: classProxy];
      RELEASE(classProxy);
      return array;
    } 
  else
    {
      return [NSArray array];
    }
}

- (void) drawSelection
{
}

- (void) makeSelectionVisible: (BOOL)flag
{
}

- (void) selectObjects: (NSArray*)objects
{
  id obj = [objects objectAtIndex: 0];
  [self selectClassWithObject: obj];
}

- (void) deleteSelection
{
  id anitem;
  int i = [outlineView selectedRow];
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  
  // if no selection, then return.
  if (i == -1)
    {
      return;
    }

  anitem = [outlineView itemAtRow: i];
  if ([anitem isKindOfClass: [GormOutletActionHolder class]])
    {
      id itemBeingEdited = [outlineView itemBeingEdited];
      NSString *name = [anitem getName];

      // if the class being edited is a custom class or a category, 
      // then allow the deletion...
      if ([classManager isCustomClass: itemBeingEdited] ||
	  [classManager isAction: name onCategoryForClassNamed: itemBeingEdited])
	{
	  if ([outlineView editType] == Actions)
	    {
	      // if this action is an action on the class, not it's superclass
	      // allow the deletion...
	      if ([classManager isAction: name
			       ofClass: itemBeingEdited])
		{
		  BOOL removed = [document removeConnectionsWithLabel: name 
					   forClassNamed: itemBeingEdited
					   isAction: YES];
		  if (removed)
		    {
		      [classManager removeAction: name
				    fromClassNamed: itemBeingEdited];
		      [outlineView removeItemAtRow: i];
		      [nc postNotificationName: GormDidModifyClassNotification
			  object: classManager];
		    }
		}
	    }
	  else if ([outlineView editType] == Outlets)
	    {
	      // if this outlet is an outlet on the class, not it's superclass
	      // allow the deletion...
	      if ([classManager isOutlet: name
			       ofClass: itemBeingEdited])
		{
		  BOOL removed = [document removeConnectionsWithLabel: name 
					   forClassNamed: itemBeingEdited
					   isAction: NO];
		  if (removed)
		    {
		      [classManager removeOutlet: name
				    fromClassNamed: itemBeingEdited];
		      [outlineView removeItemAtRow: i];
		      [nc postNotificationName: GormDidModifyClassNotification
			  object: classManager];
		    }
		}
	    }
	}
    }
  else
    {
      NSArray *subclasses = [classManager subClassesOf: anitem];
      // if the class has no subclasses, then delete.
      if ([subclasses count] == 0)
	{
	  // if the class being edited is a custom class, then allow the deletion...
	  if ([classManager isCustomClass: anitem])
	    {
	      BOOL removed = [document removeConnectionsForClassNamed: anitem];
	      if (removed)
		{
		  [self copySelection];
		  [document removeAllInstancesOfClass: anitem];
		  [classManager removeClassNamed: anitem];
		  [outlineView reloadData];
		  [nc postNotificationName: GormDidModifyClassNotification
		      object: classManager];
		  ASSIGN(selectedClass, nil); // don't keep the class we're pointing to.
		}
	    }
	}
      else
	{
	  NSString *message = [NSString stringWithFormat: 
	    _(@"The class %@ has subclasses which must be removed"), anitem];
	  NSRunAlertPanel(_(@"Problem removing class"), 
			  message,
			  nil, nil, nil);
	}
    }    
}

- (void) copySelection
{
  if(selectedClass != nil)
    {
      if([selectedClass isEqual: @"FirstResponder"] == NO)
	{
	  NSPasteboard *pb = [NSPasteboard generalPasteboard];
	  NSMutableDictionary *dict = 
	    [NSMutableDictionary dictionaryWithObjectsAndKeys: [classManager dictionaryForClassNamed: selectedClass], 
				 selectedClass, nil];
	  id classPlist = [[dict description] propertyList];
	  
	  if(classPlist != nil)
	    {
	      [pb declareTypes: [NSArray arrayWithObject: GormClassPboardType] owner: self];
	      [pb setPropertyList: classPlist forType: GormClassPboardType];
	    }
	}
    }
}

- (void) pasteInSelection
{
  if(selectedClass != nil)
    {
      if([selectedClass isEqual: @"FirstResponder"] == NO)
	{
	  NSPasteboard *pb = [NSPasteboard generalPasteboard];
	  NSArray *types = [pb types];
	  
	  if([types containsObject: GormClassPboardType])
	    {
	      id classPlist = [pb propertyListForType: GormClassPboardType];
	      NSDictionary *classesDict = [NSDictionary dictionaryWithDictionary: classPlist];
	      id name = nil;
	      NSEnumerator *en = [classesDict keyEnumerator];
	      
	      while((name = [en nextObject]) != nil)
		{
		  NSDictionary *classDict = [classesDict objectForKey: name];
		  NSString *className = [classManager uniqueClassNameFrom: name];
		  BOOL added = [classManager addClassNamed: className
					     withSuperClassNamed: selectedClass
					     withActions: [classDict objectForKey: @"Actions"]
					     withOutlets: [classDict objectForKey: @"Outlets"]];
		  if(!added)
		    {
		      NSString *message = [NSString stringWithFormat: @"Addition of %@ with superclass %@ failed.", className,
						    selectedClass];
		      NSRunAlertPanel(_(@"Problem pasting class"),
				      message, nil, nil, nil);
		    }
		}
	    }
	}
      else
	{
	  NSRunAlertPanel(_(@"Problem pasting class"),
			  _(@"FirstResponder cannot have subclasses."), nil, nil, nil);
	}
    }
}


- (void) addAttributeToClass
{
  id edited = [outlineView itemBeingEdited];
  if ([outlineView isEditing] == YES)
    {
      if ([outlineView editType] == Actions)
	{
	  [outlineView _addNewActionToObject: edited];
	}
      if ([outlineView editType] == Outlets)
	{
	  if([classManager isCustomClass: edited])
	    {
	      [outlineView _addNewOutletToObject: edited];
	    }
	}
    }
}

- (void) reloadData
{
  [outlineView reloadData];
  // [browserView loadColumnZero];
}

- (BOOL) isEditing
{
  return [outlineView isEditing];
}

/*
 *	Dragging source protocol implementation
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f
{
  // no image.
}

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  NSArray *pbTypes = [pb types];
  unsigned int oper = NSDragOperationNone;
  NSString *ext = nil;

  // Get the resource manager first, if nil don't bother calling the rest...
  if([pbTypes containsObject: NSFilenamesPboardType] == YES)
    {
      NSArray *types = [self fileTypes];
      NSArray *data = [pb propertyListForType: NSFilenamesPboardType];
      NSString *fileName = nil;
      NSEnumerator *en = [data objectEnumerator];

      while((fileName = [en nextObject]) != nil)
	{
	  ext = [fileName pathExtension];
	  if([types containsObject: ext])
	    {
	      oper = NSDragOperationCopy;
	      break;
	    }
	  else
	    {
	      oper = NSDragOperationNone;
	      break;
	    }
	}
    }

  if(oper == NSDragOperationNone)
    {      
      [(GormDocument *)document changeToTopLevelEditorAcceptingTypes: pbTypes 
		       andFileType: ext];
    }

  return oper;
}

- (unsigned) draggingUpdate: (id<NSDraggingInfo>)sender
{
  return [self draggingEntered: sender]; 
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{ 
  NSPasteboard *pb = [sender draggingPasteboard];
  NSArray *types = [pb types];

  if ([types containsObject: NSFilenamesPboardType])
    {
      NSArray *data;
      NSEnumerator *en = nil;
      NSString *fileName = nil;

      data = [pb propertyListForType: NSFilenamesPboardType];
      if(data != nil)
	{
	  en = [data objectEnumerator];
	  while((fileName = [en nextObject]) != nil)
	    {
	      NS_DURING
		{
		  if(![classManager parseHeader: fileName])
		    {
		      NSString *file = [fileName lastPathComponent];
		      NSString *message = [NSString stringWithFormat: 
						      _(@"Unable to parse class in %@"),file];
		      NSRunAlertPanel(_(@"Problem parsing class"), 
				      message,
				      nil, nil, nil);
		    }
		}
	      NS_HANDLER
		{
		  NSString *message = [localException reason];
		  NSRunAlertPanel(_(@"Problem parsing class"), 
				  message,
				  nil, nil, nil);
		}
	      NS_ENDHANDLER;
	    }
	  return YES;
	}
      else
	{
	  return NO;
	}
    }

  return NO;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  return YES;
}

// IBEditor protocol

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  return [types containsObject: NSFilenamesPboardType];
}

- (BOOL) activate
{
  return YES;
}

- (id) initWithObject: (id)anObject inDocument: (id/*<IBDocuments>*/)aDocument
{
  return [self initWithDocument: aDocument];
}

- (void) close
{
  // does nothing.
}

- (void) closeSubeditors
{
  // does nothing.
}

- (void) deactivate
{
  // does nothing.
}

- (id /*<IBDocuments>*/) document
{
  return document;
}

- (id) editedObject
{
  return selectedClass;
}

- (void) orderFront
{
  [[self window] orderFront: self];
}

- (id<IBEditors>) openSubeditorForObject: (id)object
{
  return nil;
}

- (void) resetObject: (id)anObject
{
  [outlineView reset];
  [outlineView expandItem: anObject];
  [outlineView collapseItem: anObject collapseChildren: YES];
}

- (BOOL) wantsSelection
{
  return NO;
}

- (void) validateEditing
{
  // does nothing.
}

- (NSWindow *) window
{
  return [super window];
}

- (NSArray *) fileTypes
{
  return [NSArray arrayWithObject: @"h"];
}
@end

@implementation GormClassEditor (NSOutlineViewDataSource)

// --- NSOutlineView dataSource ---
- (id)        outlineView: (NSOutlineView *)anOutlineView 
objectValueForTableColumn: (NSTableColumn *)aTableColumn 
	           byItem: item
{
  id identifier = [aTableColumn identifier];
  id className = item;
  
  if([item isKindOfClass: [GormOutletActionHolder class]])
    return item;

  if ([identifier isEqualToString: @"classes"])
    {
      return className;
    } 
  else if ([identifier isEqualToString: @"outlets"])
    {
      return [NSString stringWithFormat: @"%d",
		       [[classManager allOutletsForClassNamed: className] count]];
    }
  else if ([identifier isEqualToString: @"actions"])
    {
      return [NSString stringWithFormat: @"%d",
		       [[classManager allActionsForClassNamed: className] count]];
    }

  return @"";
}

- (void) outlineView: (NSOutlineView *)anOutlineView 
      setObjectValue: (id)anObject 
      forTableColumn: (NSTableColumn *)aTableColumn
	      byItem: (id)item
{
  GormOutlineView *gov = (GormOutlineView *)anOutlineView;

  // ignore object values which come in as nil...
  if(anObject == nil)
    return;

  if ([item isKindOfClass: [GormOutletActionHolder class]])
    {
      if (![anObject isEqualToString: @""])
	{
	  NSString *name = [item getName];

	  // retain the name and add the action/outlet...
	  if ([gov editType] == Actions)
	    {
	      NSString *formattedAction = formatAction( (NSString *)anObject );
	      if (![classManager isAction: formattedAction 
				ofClass: [gov itemBeingEdited]])
		{
		  BOOL removed;

		  removed = [document removeConnectionsWithLabel: name
		    forClassNamed: [gov itemBeingEdited] isAction: YES];
		  if (removed)
		    {
		      [classManager replaceAction: name 
				    withAction: formattedAction 
				    forClassNamed: [gov itemBeingEdited]];
		      [(GormOutletActionHolder *)item setName: formattedAction];
		    }
		}
	      else
		{
		  NSString *message;

		  message = [NSString stringWithFormat: 
		    _(@"The class %@ already has an action named %@"),
		    [gov itemBeingEdited], formattedAction];

		  NSRunAlertPanel(_(@"Problem Adding Action"),
				  message, nil, nil, nil);
				  
		}
	    }
	  else if ([gov editType] == Outlets)
	    {
	      NSString *formattedOutlet = formatOutlet( (NSString *)anObject );
	      
	      if (![classManager isOutlet: formattedOutlet 
				  ofClass: [gov itemBeingEdited]])
		{
		  BOOL removed;

		  removed = [document removeConnectionsWithLabel: name
				      forClassNamed: [gov itemBeingEdited] 
				      isAction: NO];
		  if (removed)
		    {
		      [classManager replaceOutlet: name 
				    withOutlet: formattedOutlet 
				    forClassNamed: [gov itemBeingEdited]];
		      [(GormOutletActionHolder *)item setName: formattedOutlet];
		    }
		}
	      else
		{
		  NSString *message;

		  message = [NSString stringWithFormat: 
		    _(@"The class %@ already has an outlet named %@"),
		    [gov itemBeingEdited], formattedOutlet];
		  NSRunAlertPanel(_(@"Problem Adding Outlet"),
				  message, nil, nil, nil);
				  
		}
	    }
	}
    }
  else
    {
      if  ( ( ![anObject isEqualToString: @""] ) && ( ! [anObject isEqualToString:item]  ) )
	{
	  BOOL rename;

	  rename = [document renameConnectionsForClassNamed: item toName: anObject];
	  if (rename)
	    {
	      int row = 0;

	      [classManager renameClassNamed: item newName: anObject];
	      [gov reloadData];
	      row = [gov rowForItem: anObject];

	      // make sure that item is collapsed...
	      [gov expandItem: anObject];
	      [gov collapseItem: anObject];
	      
	      // scroll to the item..
	      [gov scrollRowToVisible: row];
	    }
	}
    }

  [gov setNeedsDisplay: YES];
}

- (int) outlineView: (NSOutlineView *)anOutlineView 
numberOfChildrenOfItem: (id)item
{
  NSArray *subclasses = [classManager subClassesOf: item];
  return [subclasses count];
}

- (BOOL) outlineView: (NSOutlineView *)anOutlineView 
    isItemExpandable: (id)item
{
  NSArray *subclasses = nil;
  if (item == nil)
    return YES;

  subclasses = [classManager subClassesOf: item];
  if ([subclasses count] > 0)
    return YES;

  return NO;
}

- (id) outlineView: (NSOutlineView *)anOutlineView 
	     child: (int)index
	    ofItem: (id)item
{
  NSArray *subclasses = [classManager subClassesOf: item];
  return [subclasses objectAtIndex: index];
}

// GormOutlineView data source methods...
- (NSArray *)outlineView: (NSOutlineView *)anOutlineView
	  actionsForItem: (id)item
{
  NSArray *actions = [classManager allActionsForClassNamed: item];
  return actions;
}

- (NSArray *)outlineView: (NSOutlineView *)anOutlineView
	  outletsForItem: (id)item
{
  NSArray *outlets = [classManager allOutletsForClassNamed: item];
  return outlets;
}

- (NSString *)outlineView: (NSOutlineView *)anOutlineView
     addNewActionForClass: (id)item
{
  // removed the restriction, since it's now possible to add
  // actions for kit classes.
  return [classManager addNewActionToClassNamed: item];
}

- (NSString *)outlineView: (NSOutlineView *)anOutlineView
     addNewOutletForClass: (id)item		 
{
  GormOutlineView *gov = (GormOutlineView *)anOutlineView;
  if (![classManager isCustomClass: [gov itemBeingEdited]])
    {
      return nil;
    }

  if([item isEqualToString: @"FirstResponder"])
	    return nil;

  return [classManager addNewOutletToClassNamed: item];
}

// Delegate methods
- (BOOL)  outlineView: (NSOutlineView *)outline
shouldEditTableColumn: (NSTableColumn *)tableColumn
		 item: (id)item
{
  BOOL result = NO;
  GormOutlineView *gov = (GormOutlineView *)outline;

  NSDebugLog(@"in the delegate %@", [tableColumn identifier]);
  if (tableColumn == [gov outlineTableColumn])
    {
      NSDebugLog(@"outline table col");
      if (![item isKindOfClass: [GormOutletActionHolder class]] &&
	  ![item isEqualToString: @"FirstResponder"])
	{
	  result = [classManager isCustomClass: item];
	  [self editClass];
	}
      else
	{
	  id itemBeingEdited = [gov itemBeingEdited];
	  if ([classManager isCustomClass: itemBeingEdited])
	    {
	      if ([gov editType] == Actions)
		{
		  result = [classManager isAction: [item getName]
					 ofClass: itemBeingEdited];
		}
	      else if ([gov editType] == Outlets)
		{
		  result = [classManager isOutlet: [item getName]
					 ofClass: itemBeingEdited];
		}	       
	    }
	  else if ([classManager isCategoryForClass: itemBeingEdited])
	    {
	      if ([gov editType] == Actions)
		{
		  result = [classManager isAction: [item getName]
					 ofClass: itemBeingEdited];
		}
	    }	    
	}
    }

  return result;
}

- (void) outlineViewSelectionDidChange: (NSNotification *)notification
{
  id object = [notification object];
  int row = [object selectedRow];

  if(row != -1)
    {
      id item = [object itemAtRow: [object selectedRow]];
      if (![item isKindOfClass: [GormOutletActionHolder class]])
	{
	  [self editClass];
	}
    }
}

@end // end of data source

@implementation GormClassEditor (NSBrowserDelegate)

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
{
  NSArray      *classes = nil;
  NSEnumerator *en = nil;
  NSString     *className = nil;
  int          i = 0;

  if (sender != browserView || !matrix || ![matrix isKindOfClass:[NSMatrix class]])
    {
      return;
    }

  if(column == 0)
    {
      classes = [classManager subClassesOf: nil];
    }
  else
    {
      className = [[sender selectedCellInColumn: column - 1] stringValue];
      classes = [classManager subClassesOf: className];
    }

  en = [classes objectEnumerator];
  for(i = 0; ((className = [en nextObject]) != nil); i++) 
    {
      id              cell;
      NSArray         *sub = [classManager subClassesOf: className];
      
      [matrix insertRow:i];
      cell = [matrix cellAtRow:i column:0];
      [cell setStringValue: className];
      [cell setLeaf: ([sub count] == 0)];
    }
}

@end
