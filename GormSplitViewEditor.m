/* GormSplitViewEditor.m
 *
 * Copyright (C) 2002 Free Software Foundation, Inc.
 *
 * Author:	Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
 * Date:	2002
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

#import <AppKit/AppKit.h>

#include "GormPrivate.h"

#import "GormSplitViewEditor.h"
#import "GormInternalViewEditor.h"
#import "GormBoxEditor.h"

#define _EO ((NSSplitView *)_editedObject)

@implementation NSSplitView (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormSplitViewEditor";
}
@end


@implementation GormSplitViewEditor

- (id) initWithObject: (id) anObject
	   inDocument: (id<IBDocuments>) aDocument
{

  opened = NO;
  _displaySelection = YES;

  self = [super initWithObject: anObject
		inDocument: aDocument];

  [self registerForDraggedTypes: [NSArray arrayWithObjects:
    IBViewPboardType, GormLinkPboardType, IBFormatterPboardType, nil]];

  return self;
}

- (BOOL) activate
{
  if ([super activate])
    {
      NSEnumerator	*enumerator;
      NSView		*sub;

      NSLog(@"activating %@ GormSplitViewEditor %@", self, _EO);
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(splitViewDidResizeSubviews:)
	name: NSSplitViewDidResizeSubviewsNotification
	object: _EO];

      enumerator = [[NSArray arrayWithArray: [_EO subviews]]
		     objectEnumerator];

      while ((sub = [enumerator nextObject]) != nil)
	{
	  NSLog(@"ac %@ editorForObject: %@", self, sub);
	  if ([sub isKindOfClass: [GormViewEditor class]] == NO)
	    {
	      NSLog(@"ac %@ yes", self);
	      [document editorForObject: sub 
			inEditor: self 
			create: YES];
	    }
	}
      
      return YES;
    }

  return NO;
}

- (void) deactivate
{
  if (activated == YES)
    {
      [self deactivateSubeditors];
      openedSubeditor = nil;
      [[NSNotificationCenter defaultCenter] removeObserver: self];
      [super deactivate];
    }
}

- (void) validateFrame: (NSRect) frame
	     withEvent: (NSEvent *) theEvent
      andPlacementInfo: (GormPlacementInfo *) gpi
{
  [super validateFrame: frame
	 withEvent: theEvent
	 andPlacementInfo: gpi];
  [_EO adjustSubviews];
}



- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
  if ([super acceptsTypeFromArray: types])
    {
      return YES;
    }
  else
    {
      return [types containsObject: IBViewPboardType];
    }
}

- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
{
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      [NSApp displayConnectionBetween: [NSApp connectSource] 
	     and: _EO];
      return NSDragOperationLink;
    }
  else if ([types containsObject: IBViewPboardType] == YES)
    {
      return NSDragOperationCopy;
    }
  else
    {
      return NSDragOperationNone;
    }
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      return YES;
    }
  else if ([types containsObject: IBViewPboardType] == YES)
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

- (unsigned) draggingUpdated: (id<NSDraggingInfo>)sender
{
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  if ([types containsObject: GormLinkPboardType] == YES)
    {
      [NSApp displayConnectionBetween: [NSApp connectSource] 
	     and: _EO];
      return NSDragOperationLink;
    }
  else if ([types containsObject: IBViewPboardType] == YES)
    {
      /*
      NSArray *sub = [_EO subviews];
      int count = [sub count];
      NSPoint loc = [sender draggingLocation];
      loc = [_EO 
	      convertPoint: loc fromView: nil];
      
      if ([_EO isVertical])
	{
	  for ( i = 0; i < count - 1; i++ )
	    {
	      if (i < 
	    }
	}
      */
      return NSDragOperationCopy;
    }
  else
    {
      return NSDragOperationNone;
    }
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSPasteboard	*dragPb;
  NSArray	*types;
  
  dragPb = [sender draggingPasteboard];
  types = [dragPb types];
  
  if ([types containsObject: GormLinkPboardType])
    {
      [NSApp displayConnectionBetween: [NSApp connectSource] 
	     and: _EO];
      [NSApp startConnecting];
    }
  else if ([types containsObject: IBViewPboardType] == YES)
    {
      NSArray		*views;
      NSEnumerator	*enumerator;
      NSView            *sub;

      views = [document pasteType: IBViewPboardType
		   fromPasteboard: dragPb
			   parent: _EO];
      
      enumerator = [views objectEnumerator];
      while ((sub = [enumerator nextObject]) != nil)
	{
	  [_EO addSubview: sub];
	  
	  [document editorForObject: sub 
		    inEditor: self 
		    create: YES];
	}
      [_EO adjustSubviews];
      [_EO setNeedsDisplay: YES];
    }
  return YES;
}


- (void) mouseDown: (NSEvent *) theEvent
{
  BOOL onKnob = NO;
  NSView *clickedSubview;

//    NSLog(@"in GormSplitViewEditor -mouseDown");
  {
    if ([parent respondsToSelector: @selector(selection)] &&
	[[parent selection] containsObject: _EO])
      {
	IBKnobPosition	knob = IBNoneKnobPosition;
	NSPoint mouseDownPoint = 
	  [self convertPoint: [theEvent locationInWindow]
		fromView: nil];
	knob = GormKnobHitInRect([self bounds], 
				 mouseDownPoint);
	if (knob != IBNoneKnobPosition)
	  onKnob = YES;
      }
    if (onKnob == YES)
      {
	if (parent)
	  return [parent mouseDown: theEvent];
	else
	  return [self noResponderFor: @selector(mouseDown:)];
      }
  }

  if (opened == NO)
    {
//        NSLog(@"not opened");
      [super mouseDown: theEvent];
      return;
    }
  
  {
    int i;
    NSArray *subs = [_EO subviews];
    int count = [subs count];
    NSPoint mouseDownPoint = 
      [self convertPoint: [theEvent locationInWindow]
	    fromView: nil];
    clickedSubview = [_EO hitTest: mouseDownPoint];
    
    for ( i = 0; i < count; i++ )
      {
	if ([clickedSubview isDescendantOf: [subs objectAtIndex: i]])
	  {
	    break;
	  }
      }
    
    if (i < count)
      clickedSubview = [subs objectAtIndex: i];
    else
      {
	clickedSubview = nil;
//  	NSLog(@"subs %@", subs);
      }
  }  

  if (clickedSubview == nil)
    {
//        NSLog(@"clickedSubview == nil");
      if (openedSubeditor)
	[openedSubeditor deactivate];
      [_EO mouseDown: theEvent];
    }
  else
    {
//        NSLog(@"clickedSubview == %@", clickedSubview);
//        if ([theEvent clickCount] == 2
//  	  && [clickedSubview respondsToSelector: @selector(canBeOpened)]
//  	  && ([clickedSubview canBeOpened] == YES)
//  	  && (clickedSubview != self))
      [self selectObjects: [NSArray arrayWithObject: clickedSubview]];
      [self setNeedsDisplay: YES];

      if ([theEvent clickCount] == 2
	  && [clickedSubview isKindOfClass: [GormViewWithSubviewsEditor class]]
	  && ([(GormViewWithSubviewsEditor *) clickedSubview canBeOpened] == YES)
	  && (clickedSubview != self))
	{
	  if ((openedSubeditor != (GormViewWithSubviewsEditor *)clickedSubview)
	      && openedSubeditor)
	    [openedSubeditor deactivate];

	  [self setOpenedSubeditor: (GormViewWithSubviewsEditor *)clickedSubview];
	  if ([(GormViewWithSubviewsEditor *) clickedSubview isOpened] == NO)
	    [(GormViewWithSubviewsEditor *)clickedSubview setOpened: YES];
//  	  NSLog(@"md %@ sendind to clickView %@", self, clickedSubview);
	  [clickedSubview mouseDown: theEvent];
	}
    }
}

- (void) splitViewDidResizeSubviews: (NSNotification *)aNotification
{
  [self setNeedsDisplay: YES];
}


- (void) ungroup
{
  NSView *toUngroup;


  if ([selection count] != 1)
    return;
  

  toUngroup = [selection objectAtIndex: 0];


  if ([toUngroup isKindOfClass: [GormBoxEditor class]]
      || [toUngroup isKindOfClass: [GormSplitViewEditor class]])
    {
      id contentView = toUngroup;

      NSMutableArray *newSelection = [NSMutableArray array];
      NSArray *views;
      int i;
      views = [contentView destroyAndListSubviews];
      for (i = 0; i < [views count]; i++)
	{
	  [_editedObject addSubview: [views objectAtIndex: i]];
	  [newSelection addObject:
			  [document editorForObject: [views objectAtIndex: i]
					inEditor: self
				    create: YES]];
	}
      [_EO adjustSubviews];
      [self setNeedsDisplay: YES];
    }

}


- (NSArray *)destroyAndListSubviews
{
  NSEnumerator *enumerator = [[_EO subviews] objectEnumerator];
  GormViewEditor *subview;
  NSMutableArray *newSelection = [NSMutableArray array];
  
  [parent makeSubeditorResign];
  
  while ((subview = [enumerator nextObject]) != nil)
    {
      id v;
      NSRect frame;
      v = [subview editedObject];
      frame = [v frame];
      frame = [parent convertRect: frame
		      fromView: _EO];
      [subview deactivate];
      
      [v setFrame: frame];
//        [[[parent parent] editedObject] addSubview: v];
      [newSelection addObject: v];
    }
  
  {
    id thisView = [self editedObject];
    [self close];
    [thisView removeFromSuperview];
    
  }
  return newSelection;
}



/*
- (void) postDraw: (NSRect) rect
{
  [super postDraw: rect];

  if (openedSubeditor != nil)
    {
      GormDrawOpenKnobsForRect(
			       [self convertRect: [openedSubeditor bounds]
				     fromView: openedSubeditor]);
      GormShowFastKnobFills();
    }
  else if (_displaySelection)
    {
      // FIXME
    }
}

- (void) postDrawForView: (GormViewEditor *) viewEditor
{
  if (_displaySelection == NO)
    {
      return;
    }
  if ((openedSubeditor == viewEditor) && (openedSubeditor != nil))
    {
      GormDrawOpenKnobsForRect([viewEditor bounds]);
      GormShowFastKnobFills();
    }
  else 
    {
      // FIXME
    }
}
*/
@end