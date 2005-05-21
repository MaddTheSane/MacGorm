/* GormWindowEditor.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
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

#include <InterfaceBuilder/IBViewAdditions.h>
#include <InterfaceBuilder/IBObjectAdditions.h>

#include "GormPrivate.h"
#include "GormViewWithContentViewEditor.h"
#include "GormInternalViewEditor.h"
#include "GormViewKnobs.h"

#include <math.h>

#define _EO ((NSWindow *)_editedObject)

@implementation NSWindow (IBObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormWindowEditor";
}

/*
 * Method to return the image that should be used to display windows within
 * the matrix containing the objects in a document.
 */
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormWindow"];
      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}
@end

/*
 *	Default implementations of methods used for updating a view by
 *	direct action through an editor.
 */
@implementation NSView (IBViewAdditions)

- (BOOL) acceptsColor: (NSColor*)color atPoint: (NSPoint)point
{
  return NO;	/* Can the view accept a color drag-and-drop?	*/
}

- (BOOL) allowsAltDragging
{
  return NO;	/* Can the view be dragged into a matrix?	*/
}

- (void) depositColor: (NSColor*)color atPoint: (NSPoint)point
{
  					/* Handle color drop in view.	*/
}

- (NSSize) maximumSizeFromKnobPosition: (IBKnobPosition)knobPosition
{
  NSView	*s = [self superview];
  NSRect	r = (s != nil) ? [s bounds] : [self bounds];

  return r.size;			/* maximum resize permitted	*/
}

- (NSSize) minimumSizeFromKnobPosition: (IBKnobPosition)position
{
  return NSMakeSize(5, 5);		/* Minimum resize permitted	*/
}

- (void) placeView: (NSRect)newFrame
{
  [self setFrame: newFrame];		/* View changed by editor.	*/
}

@end

@interface NSWindow (GormWindowEditorAdditions)
- (void) unsetInitialFirstResponder;
@end

@implementation NSWindow (GormWindowEditorAdditions)
/*
 * The setFirstResponder method is used in this editor to allow it to
 * respond to messages forwarded to the window appropriately.
 * Unfortunately, once it's set to something, it cannot be set to nil.
 * This method allows us to set it to nil, thus preventing a memory leak.
 */
- (void) unsetInitialFirstResponder
{
  ASSIGN(_initialFirstResponder, nil);
}
@end



@interface GormWindowEditor : GormViewWithContentViewEditor
{
  NSView                *edit_view;
  NSMutableArray	*subeditors;
  BOOL			isLinkSource;
  NSPasteboard		*dragPb;
  NSString		*dragType;
}
- (BOOL) acceptsTypeFromArray: (NSArray*)types;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id<IBDocuments>)aDocument;
- (void) changeFont: (id) sender;
- (void) close;
- (void) closeSubeditors;
- (void) deactivate;
- (void) deleteSelection;
- (id<IBDocuments>) document;
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (void) makeSelectionVisible: (BOOL)flag;
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
- (void) orderFront;
- (void) pasteInSelection;
- (void) resetObject: (id)anObject;
@end

@implementation	GormWindowEditor

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  NSDebugLog(@"acceptsFirstMouse");
  return YES;
}

- (BOOL) acceptsFirstResponder
{
  NSDebugLog(@"acceptsFirstResponder");
  return YES;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Argh - encoding window editor"];
}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  /*
   * A window editor can accept views pasted in to the window.
   */
  return [types containsObject: IBViewPboardType];
}

- (BOOL) activate
{
  if (activated == NO)
    {
      NSView *contentView = [_EO contentView];
      contentViewEditor = (GormInternalViewEditor *)[document editorForObject: contentView
							      inEditor: self 
							      create: YES];
      [_EO setInitialFirstResponder: self];
      [self setOpened: YES];
      activated = YES;
      return YES;
    }

  return NO;
}

- (void) changeFont: (id)sender
{
  NSDebugLog(@"changeFont");
}

- (void) close
{
  NSAssert(closed == NO, NSInternalInconsistencyException);
  closed = YES;
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [self makeSelectionVisible: NO];
  if ([(id<IB>)NSApp selectionOwner] == self)
    {
      [document resignSelectionForEditor: self];
    }

  [self closeSubeditors];
  [self deactivate];
  [document editor: self didCloseForObject: _EO];
}

- (void) closeSubeditors
{
  while ([subeditors count] > 0)
    {
      id<IBEditors>	sub = [subeditors lastObject];

      [sub close];
      [subeditors removeObjectIdenticalTo: sub];
    }
}

- (void) copySelection
{
  NSLog(@"copySelection");
}

- (void) deactivate
{
  if (activated == YES)
    {
      [contentViewEditor deactivate];
      [_EO unsetInitialFirstResponder];
      activated = NO;
    }
  return;
}

- (void) dealloc
{
  if (closed == NO)
      [self close];

  RELEASE(selection);
  RELEASE(subeditors);

  [super dealloc];
}

- (void) deleteSelection
{
}

/*
- (id) retain
{
  NSLog(@"Being retained... %d: %@", [self retainCount], self);
  return [super retain];
}

- (oneway void) release
{
  NSLog(@"Being released... %d: %@", [self retainCount], self);
  [super release];
}
*/

/*
 *	Dragging source protocol implementation
 */
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f
{
  /*
   * Notification that a drag failed/succeeded.
   */

  NSDebugLog(@"draggedImage");

  if(f == NO)
    {
      NSRunAlertPanel(nil, _(@"Window drag failed."),
		      _(@"OK"), nil, nil);
    }
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
  NSDebugLog(@"draggingSourceOperationMaskForLocal");
  return NSDragOperationNone;
}

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  return NSDragOperationNone;
}

- (unsigned) draggingUpdated: (id<NSDraggingInfo>)sender
{
  return NSDragOperationNone;
}

- (void) drawSelection
{
  NSDebugLog(@"drawSelection");
}

- (id<IBDocuments>) document
{
  return document;
}

- (id) initWithObject: (id)anObject 
	   inDocument: (id<IBDocuments>)aDocument
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  if ((self = [super initWithFrame: NSZeroRect]) == nil)
    return nil;

  [nc addObserver: self
      selector: @selector(handleNotification:)
      name: IBWillCloseDocumentNotification
      object: aDocument];
      
  _displaySelection = YES;
  ASSIGN(_editedObject, anObject);

  // we don't retain the document...
  document = aDocument;

  [self registerForDraggedTypes: [NSArray arrayWithObjects:
    GormLinkPboardType, IBViewPboardType, nil]];

  selection = [NSMutableArray new];
  subeditors = [NSMutableArray new];

  activated = NO;
  closed = NO;

  [self activate];
  
  return self;
}

- (void) makeSelectionVisible: (BOOL)flag
{
  if (flag == NO)
    {
      if ([selection count] > 0)
	{
	  NSEnumerator	*enumerator = [selection objectEnumerator];
	  NSView	*view;

	  [[self window] disableFlushWindow];
	  while ((view = [enumerator nextObject]) != nil)
	    {
	      NSRect	rect = GormExtBoundsForRect([view frame]);

	      [edit_view displayRect: rect];
	    }
	  [[self window] enableFlushWindow];
	  [[self window] flushWindowIfNeeded];
	}
    }
  else
    {
      [self drawSelection];
      [[self window] flushWindow];
    }
}

- (id<IBEditors>) openSubeditorForObject: (id)anObject
{
  NSDebugLog(@"openSubeditorForObject");
  return nil;
}

- (void) orderFront
{
  [_EO orderFront: self];
}

- (void) pasteInSelection
{
  NSLog(@"pasteInSelection");
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSDebugLog(@"performDragOperation");
  return NO;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  return NO;
}

- (void) resetObject: (id)anObject
{
  [[self window] makeKeyAndOrderFront: self];
}

- (id) selectAllItems: (id)sender
{
  NSDebugLog(@"selectAllItems");
  return nil;
}

- (unsigned) selectionCount
{
  NSDebugLog(@"selectionCount");
  return  0;
}

- (void) validateEditing
{
  NSDebugLog(@"validateEditing");
}

- (void)windowDidBecomeMain: (id) aNotification
{
  NSDebugLog(@"windowDidBecomeMain %@", selection);
  if ([NSApp isConnecting] == NO)
    {
      [document setSelectionFromEditor: self];
      NSDebugLog(@"windowDidBecomeMain %@", selection);
      [self makeSelectionVisible: YES];
    }
}

- (void)windowDidResignMain: (id) aNotification
{
  NSDebugLog(@"windowDidResignMain");
  // [document setSelectionFromEditor: self];
  [self makeSelectionVisible: NO];
}
@end