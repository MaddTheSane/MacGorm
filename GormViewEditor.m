/* GormViewEditor.m
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

#import "GormViewEditor.h"
#import "GormViewWithSubviewsEditor.h"
#import "GormPlacementInfo.h"

#include <math.h>
#include <stdlib.h>




@implementation GormPlacementInfo
@end



@implementation GormPlacementHint
- (float) position { return _position; }
- (float) start { return _start; }
- (float) end { return _end; }
- (NSRect) frame { return _frame; }
- (GormHintBorder) border { return _border; }
- (NSString *) description
{
  switch (_border)
    {
    case Left:
      return [NSString stringWithFormat: @"Left   %f (%f-%f)", 
		       _position, _start, _end];
    case Right:
      return [NSString stringWithFormat: @"Right  %f (%f-%f)", 
		       _position, _start, _end];
    case Top:
      return [NSString stringWithFormat: @"Top    %f (%f-%f)", 
		       _position, _start, _end];
    default:
      return [NSString stringWithFormat: @"Bottom %f (%f-%f)", 
		       _position, _start, _end];
    }
}
- (id) initWithBorder: (GormHintBorder) border
	     position: (float) position
	validityStart: (float) start
	  validityEnd: (float) end
		frame: (NSRect) frame
{
  _border = border;
  _start = start;
  _end = end;
  _position = position;
  _frame = frame;
  return self;
}

- (NSRect) rectWithHalfDistance: (int) halfHeight
{
  switch (_border)
    {
    case Top:
    case Bottom:
      return NSMakeRect(_start, _position - halfHeight, 
			_end - _start, 2 * halfHeight);
    case Left:
    case Right:
      return NSMakeRect(_position - halfHeight, _start, 
			2 * halfHeight, _end - _start);
    default:
      return NSZeroRect;
    }
}

- (int) distanceToFrame: (NSRect) frame
{
  NSRect rect = [self rectWithHalfDistance: 6];
  if (NSIntersectsRect(frame, rect) == NO)
    return 10;
  switch (_border)
    {
    case Top:
      return abs (_position - NSMaxY(frame));
    case Bottom:
      return abs (_position - NSMinY(frame));
    case Left:
      return abs (_position - NSMinX(frame));
    case Right:
      return abs (_position - NSMaxX(frame));
    default:
      return 10;
    }
}
@end




static BOOL currently_displaying = NO;



@implementation	GormViewEditor

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"Argh - encoding view editor"];
}

- (id<IBDocuments>) document
{
  return document;
}


- (id) editedObject
{
  return _editedObject;
}


- (BOOL) activate
{
  if (activated == NO)
    {
      NSView *superview = [_editedObject superview];

//        NSLog(@"ac %@ %@ %@", self, _editedObject, superview);

      
      [self setFrame: [_editedObject frame]];
      [self setBounds: [self frame]];

      [superview replaceSubview: _editedObject
		 with: self];
      [self setAutoresizingMask: NSViewMaxXMargin | NSViewMinYMargin];

      [self setAutoresizesSubviews: NO];

      [self addSubview: _editedObject];
      
      [_editedObject setPostsFrameChangedNotifications: YES];
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(editedObjectFrameDidChange:)
	name: NSViewFrameDidChangeNotification
	object: _editedObject];
      
      [self setPostsFrameChangedNotifications: YES];
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(frameDidChange:)
	name: NSViewFrameDidChangeNotification
	object: self];

      parent = [document parentEditorForEditor: self];

//        NSLog(@"ac parent %@", parent);

      if ([parent isKindOfClass: [GormViewEditor class]])
	[parent setNeedsDisplay: YES];
      else
	[self setNeedsDisplay: YES];
      activated = YES;
      return YES;
    }
  
  return NO;
}

- (id) parent
{
  return parent;
}

- (void) detachSubviews
{
//    NSLog(@"nothing to do");
}


- (void) close
{

  if (closed == NO)
    {
//        NSLog(@"%@ close", self);
      [self deactivate];
      
      [document editor: self didCloseForObject: _editedObject];
      closed = YES;
    }
  else
    {
      NSLog(@"%@ close but already closed", self);
    }
}

- (void) deactivate
{
//    NSLog(@"%@ deactivate", self);

  if (activated == YES)
    {
      NSView *superview = [self superview];

      [self removeSubview: _editedObject];
//        NSLog(@"superview %@ %@", [superview subviews]);
      [superview replaceSubview: self
		 with: _editedObject];
//        NSLog(@"superview %@ %@", [superview subviews]);

      [[NSNotificationCenter defaultCenter] removeObserver: self];

      activated = NO;
    }
}

- (void) dealloc
{
//    NSLog(@"%@ dealloc", self);
  if (closed == NO)
    [self close];

  RELEASE(_editedObject);
  [super dealloc];
}

- (id) initWithObject: (id)anObject 
	   inDocument: (id<IBDocuments>)aDocument
{
  _editedObject = (NSView*)anObject;

  if ((self = [super initWithFrame: [_editedObject frame]]) == nil)
    return nil;
  
  RETAIN(_editedObject);

  document = aDocument;

  [self registerForDraggedTypes: [NSArray arrayWithObjects:
    GormLinkPboardType, nil]];

  activated = NO;
  closed = NO;

  return self;
}


- (void) editedObjectFrameDidChange: (id) sender
{
  [self setFrame: [_editedObject frame]];
  [self setBounds: [_editedObject frame]];
}


- (void) frameDidChange: (id) sender
{
  [self setBounds: [self frame]];
  [_editedObject setFrame: [self frame]];
}


- (GormPlacementInfo *) initializeResizingInFrame: (NSView *)view
						    withKnob: (IBKnobPosition) knob
{
  GormPlacementInfo *gip;
  gip = [[GormPlacementInfo alloc] init];

    
  gip->resizingIn = view;
  gip->firstPass = YES;
  gip->hintInitialized = NO;
  gip->leftHints = nil;
  gip->rightHints = nil;
  gip->topHints = nil;
  gip->bottomHints = nil;
  gip->knob = knob;

  return gip;
}

- (void) _displayFrame: (NSRect) frame
     withPlacementInfo: (GormPlacementInfo*) gpi
{
  if (gpi->firstPass == NO)
    [gpi->resizingIn displayRect: gpi->oldRect];
  else
    gpi->firstPass = NO;
  
  GormShowFrameWithKnob(frame, gpi->knob);
  
  gpi->oldRect = GormExtBoundsForRect(frame);
  gpi->oldRect.origin.x--;
  gpi->oldRect.origin.y--;
  gpi->oldRect.size.width += 2;
  gpi->oldRect.size.height += 2;
}

- (void) _initializeHintWithInfo: (GormPlacementInfo*) gpi
{
  int i;
  NSArray *subviews = [[self superview] subviews];
  int count = [subviews count];
  NSView *v;
//    NSLog(@"initializing hints");
  gpi->lastLeftRect = NSZeroRect;
  gpi->lastRightRect = NSZeroRect;
  gpi->lastTopRect = NSZeroRect;
  gpi->lastBottomRect = NSZeroRect;
  gpi->hintInitialized = YES;
  gpi->leftHints = [[NSMutableArray alloc] initWithCapacity: 2 * count];
  gpi->rightHints = [[NSMutableArray alloc] initWithCapacity: 2 * count];
  gpi->topHints = [[NSMutableArray alloc] initWithCapacity: 2 * count];
  gpi->bottomHints = [[NSMutableArray alloc] initWithCapacity: 2 * count];

  [gpi->leftHints addObject: 
	       [[GormPlacementHint alloc]
		 initWithBorder: Left
		 position: NSMinX([[self superview] bounds])
		 validityStart: NSMinY([[self superview] bounds])
		 validityEnd: NSMaxY([[self superview] bounds])
		 frame: [[self superview] bounds]]];
  [gpi->leftHints addObject: 
	       [[GormPlacementHint alloc]
		 initWithBorder: Left
		 position: NSMinX([[self superview] bounds]) + 10
		 validityStart: NSMinY([[self superview] bounds])
		 validityEnd: NSMaxY([[self superview] bounds])
		 frame: [[self superview] bounds]]];

  [gpi->rightHints addObject: 
	       [[GormPlacementHint alloc]
		 initWithBorder: Right
		 position: NSMaxX([[self superview] bounds])
		 validityStart: NSMinY([[self superview] bounds])
		 validityEnd: NSMaxY([[self superview] bounds])
		 frame: [[self superview] bounds]]];
  [gpi->rightHints addObject: 
	       [[GormPlacementHint alloc]
		 initWithBorder: Right
		 position: NSMaxX([[self superview] bounds]) - 10
		 validityStart: NSMinY([[self superview] bounds])
		 validityEnd: NSMaxY([[self superview] bounds])
		 frame: [[self superview] bounds]]];

  [gpi->topHints addObject: 
	       [[GormPlacementHint alloc]
		 initWithBorder: Top
		 position: NSMaxY([[self superview] bounds])
		 validityStart: NSMinX([[self superview] bounds])
		 validityEnd: NSMaxX([[self superview] bounds])
		 frame: [[self superview] bounds]]];
  [gpi->topHints addObject: 
	       [[GormPlacementHint alloc]
		 initWithBorder: Top
		 position: NSMaxY([[self superview] bounds]) - 10
		 validityStart: NSMinX([[self superview] bounds])
		 validityEnd: NSMaxX([[self superview] bounds])
		 frame: [[self superview] bounds]]];

  [gpi->bottomHints addObject: 
	       [[GormPlacementHint alloc]
		 initWithBorder: Bottom
		 position: NSMinY([[self superview] bounds])
		 validityStart: NSMinX([[self superview] bounds])
		 validityEnd: NSMaxX([[self superview] bounds])
		 frame: [[self superview] bounds]]];
  [gpi->bottomHints addObject: 
	       [[GormPlacementHint alloc]
		 initWithBorder: Bottom
		 position: NSMinY([[self superview] bounds]) + 10
		 validityStart: NSMinX([[self superview] bounds])
		 validityEnd: NSMaxX([[self superview] bounds])
		 frame: [[self superview] bounds]]];

  for ( i = 0; i < count; i++ )
    {
      v = [subviews objectAtIndex: i];
      if (v == self)
	continue;
     
      [gpi->leftHints addObject: 
		   [[GormPlacementHint alloc]
		     initWithBorder: Left
		     position: NSMinX([v frame])
		     validityStart: NSMinY([[self superview] bounds])
		     validityEnd: NSMaxY([[self superview] bounds])
		     frame: [v frame]]];
      [gpi->leftHints addObject: 
		   [[GormPlacementHint alloc]
		     initWithBorder: Left
		     position: NSMaxX([v frame])
		     validityStart: NSMinY([v frame])
		     validityEnd: NSMaxY([v frame])
		     frame: [v frame]]];
      [gpi->leftHints addObject: 
		   [[GormPlacementHint alloc]
		     initWithBorder: Left
		     position: NSMaxX([v frame]) + 5
		     validityStart: NSMinY([v frame]) - 10
		     validityEnd: NSMaxY([v frame]) + 10
		     frame: [v frame]]];

      [gpi->rightHints addObject: 
		    [[GormPlacementHint alloc]
		      initWithBorder: Right
		      position: NSMaxX([v frame])
		      validityStart: NSMinY([[self superview] bounds])
		      validityEnd: NSMaxY([[self superview] bounds])
		 frame: [v frame]]];
      [gpi->rightHints addObject: 
		    [[GormPlacementHint alloc]
		      initWithBorder: Right
		      position: NSMinX([v frame])
		      validityStart: NSMinY([v frame])
		      validityEnd: NSMaxY([v frame])
		      frame: [v frame]]];
      [gpi->rightHints addObject: 
		    [[GormPlacementHint alloc]
		      initWithBorder: Right
		      position: NSMinX([v frame]) - 5
		      validityStart: NSMinY([v frame]) - 10
		      validityEnd: NSMaxY([v frame]) + 10
		      frame: [v frame]]];

      [gpi->topHints addObject: 
		    [[GormPlacementHint alloc]
		      initWithBorder: Top
		      position: NSMaxY([v frame])
		      validityStart: NSMinX([[self superview] bounds])
		      validityEnd: NSMaxX([[self superview] bounds])
		 frame: [v frame]]];
      [gpi->topHints addObject: 
		    [[GormPlacementHint alloc]
		      initWithBorder: Top
		      position: NSMinY([v frame])
		      validityStart: NSMinX([v frame])
		      validityEnd: NSMaxX([v frame])
		      frame: [v frame]]];
      [gpi->topHints addObject: 
		    [[GormPlacementHint alloc]
		      initWithBorder: Top
		      position: NSMinY([v frame]) - 5
		      validityStart: NSMinX([v frame]) - 10
		      validityEnd: NSMaxX([v frame]) + 10
		      frame: [v frame]]];

      [gpi->bottomHints addObject: 
		    [[GormPlacementHint alloc]
		      initWithBorder: Bottom
		      position: NSMinY([v frame])
		      validityStart: NSMinX([[self superview] bounds])
		      validityEnd: NSMaxX([[self superview] bounds])
		 frame: [v frame]]];
      [gpi->bottomHints addObject: 
		    [[GormPlacementHint alloc]
		      initWithBorder: Bottom
		      position: NSMaxY([v frame])
		      validityStart: NSMinX([v frame])
		      validityEnd: NSMaxX([v frame])
		      frame: [v frame]]];
      [gpi->bottomHints addObject: 
		    [[GormPlacementHint alloc]
		      initWithBorder: Bottom
		      position: NSMaxY([v frame]) + 5
		      validityStart: NSMinX([v frame]) - 10
		      validityEnd: NSMaxX([v frame]) + 10
		      frame: [v frame]]];
    }
}


#undef MIN
#undef MAX

#define MIN(a,b) (a>b?b:a)
#define MAX(a,b) (a>b?a:b)


- (void) _displayFrameWithHint: (NSRect) frame
	     withPlacementInfo: (GormPlacementInfo*)gpi
{
  float leftOfFrame = NSMinX(frame);
  float rightOfFrame = NSMaxX(frame);
  float topOfFrame = NSMaxY(frame);
  float bottomOfFrame = NSMinY(frame);
  int i;
  int count;
  int lastDistance;
  int minimum = 10;
  BOOL leftEmpty = YES;
  BOOL rightEmpty = YES;
  BOOL topEmpty = YES;
  BOOL bottomEmpty = YES;
  float bestLeftPosition;
  float bestRightPosition;
  float bestTopPosition;
  float bestBottomPosition;
  float leftStart;
  float rightStart;
  float topStart;
  float bottomStart;
  float leftEnd;
  float rightEnd;
  float topEnd;
  float bottomEnd;

  NSMutableArray *bests;
  if (gpi->hintInitialized == NO)
    {
      [self _initializeHintWithInfo: gpi];
    }

  {
    if (gpi->firstPass == NO)
      [gpi->resizingIn displayRect: gpi->oldRect];
    else
      gpi->firstPass = NO;
  }
  {
    [gpi->resizingIn setNeedsDisplayInRect: gpi->lastLeftRect];
    [[self window] displayIfNeeded];
    gpi->lastLeftRect = NSZeroRect;
  }
  {
    [gpi->resizingIn setNeedsDisplayInRect: gpi->lastRightRect];
    [[self window] displayIfNeeded];
    gpi->lastRightRect = NSZeroRect;
  }
  {
    [gpi->resizingIn setNeedsDisplayInRect: gpi->lastTopRect];
    [[self window] displayIfNeeded];
    gpi->lastTopRect = NSZeroRect;
  }
  {
    [gpi->resizingIn setNeedsDisplayInRect: gpi->lastBottomRect];
    [[self window] displayIfNeeded];
    gpi->lastBottomRect = NSZeroRect;
  }


  if (gpi->knob == IBTopLeftKnobPosition
      || gpi->knob == IBMiddleLeftKnobPosition
      || gpi->knob == IBBottomLeftKnobPosition)
  {
    bests = [NSMutableArray arrayWithCapacity: 4];
    minimum = 6;
    count = [gpi->leftHints count];
    for ( i = 0; i < count; i++ )
      {
	lastDistance = [[gpi->leftHints objectAtIndex: i] 
			 distanceToFrame: frame];
	if (lastDistance < minimum)
	  {
	    bests = [NSMutableArray arrayWithCapacity: 4];
	    [bests addObject: [gpi->leftHints objectAtIndex: i]];
	    minimum = lastDistance;
	    bestLeftPosition = [[gpi->leftHints objectAtIndex: i] position];
	    leftEmpty = NO;
	  }
	else if ((lastDistance == minimum) && (leftEmpty == NO)
		 && ([[gpi->leftHints objectAtIndex: i] position] == bestLeftPosition))
	  [bests addObject: [gpi->leftHints objectAtIndex: i]];
      }
    
    count = [bests count];
    if (count >= 1)
      {
	leftStart = NSMinY([[bests objectAtIndex: 0] frame]);
	leftEnd = NSMaxY([[bests objectAtIndex: 0] frame]);

	for ( i = 1; i < count; i++ )
	  {
	    leftStart = MIN(NSMinY([[bests objectAtIndex: i] frame]), leftStart);
	    leftEnd = MAX(NSMaxY([[bests objectAtIndex: i] frame]), leftEnd);
	  }
	leftOfFrame = bestLeftPosition;
      }
  }

  if (gpi->knob == IBTopRightKnobPosition
      || gpi->knob == IBMiddleRightKnobPosition
      || gpi->knob == IBBottomRightKnobPosition)
  {
    bests = [NSMutableArray arrayWithCapacity: 4];
    minimum = 6;
    count = [gpi->rightHints count];
    for ( i = 0; i < count; i++ )
      {
	lastDistance = [[gpi->rightHints objectAtIndex: i] 
			 distanceToFrame: frame];
	if (lastDistance < minimum)
	  {
	    bests = [NSMutableArray arrayWithCapacity: 4];
	    [bests addObject: [gpi->rightHints objectAtIndex: i]];
	    minimum = lastDistance;
	    bestRightPosition = [[gpi->rightHints objectAtIndex: i] position];
	    rightEmpty = NO;
	  }
	else if ((lastDistance == minimum) && (rightEmpty == NO)
		 && ([[gpi->rightHints objectAtIndex: i] position] == bestRightPosition))
	  [bests addObject: [gpi->rightHints objectAtIndex: i]];
      }
    
    count = [bests count];
    if (count >= 1)
      {
	rightStart = NSMinY([[bests objectAtIndex: 0] frame]);
	rightEnd = NSMaxY([[bests objectAtIndex: 0] frame]);

	for ( i = 1; i < count; i++ )
	  {
	    rightStart = MIN(NSMinY([[bests objectAtIndex: i] frame]), rightStart);
	    rightEnd = MAX(NSMaxY([[bests objectAtIndex: i] frame]), rightEnd);
	  }
	rightOfFrame = bestRightPosition;
      }
  }

  if (gpi->knob == IBTopRightKnobPosition
      || gpi->knob == IBTopLeftKnobPosition
      || gpi->knob == IBTopMiddleKnobPosition)
  {
    bests = [NSMutableArray arrayWithCapacity: 4];
    minimum = 6;
    count = [gpi->topHints count];
    for ( i = 0; i < count; i++ )
      {
	lastDistance = [[gpi->topHints objectAtIndex: i] 
			 distanceToFrame: frame];
	if (lastDistance < minimum)
	  {
	    bests = [NSMutableArray arrayWithCapacity: 4];
	    [bests addObject: [gpi->topHints objectAtIndex: i]];
	    minimum = lastDistance;
	    bestTopPosition = [[gpi->topHints objectAtIndex: i] position];
	    topEmpty = NO;
	  }
	else if ((lastDistance == minimum) && (topEmpty == NO)
		 && ([[gpi->topHints objectAtIndex: i] position] == bestTopPosition))
	  [bests addObject: [gpi->topHints objectAtIndex: i]];
      }
    
    count = [bests count];
    if (count >= 1)
      {
	topStart = NSMinX([[bests objectAtIndex: 0] frame]);
	topEnd = NSMaxX([[bests objectAtIndex: 0] frame]);
	for ( i = 1; i < count; i++ )
	  {
	    topStart = MIN(NSMinX([[bests objectAtIndex: i] frame]), topStart);
	    topEnd = MAX(NSMaxX([[bests objectAtIndex: i] frame]), topEnd);
	  }
	topOfFrame = bestTopPosition;
      }
  }

  if (gpi->knob == IBBottomRightKnobPosition
      || gpi->knob == IBBottomLeftKnobPosition
      || gpi->knob == IBBottomMiddleKnobPosition)
  {
    bests = [NSMutableArray arrayWithCapacity: 4];
    minimum = 6;
    count = [gpi->bottomHints count];
    for ( i = 0; i < count; i++ )
      {
	lastDistance = [[gpi->bottomHints objectAtIndex: i] 
			 distanceToFrame: frame];
	if (lastDistance < minimum)
	  {
	    bests = [NSMutableArray arrayWithCapacity: 4];
	    [bests addObject: [gpi->bottomHints objectAtIndex: i]];
	    minimum = lastDistance;
	    bestBottomPosition = [[gpi->bottomHints objectAtIndex: i] position];
	    bottomEmpty = NO;
	  }
	else if ((lastDistance == minimum) && (bottomEmpty == NO)
		 && ([[gpi->bottomHints objectAtIndex: i] position] == bestBottomPosition))
	  [bests addObject: [gpi->bottomHints objectAtIndex: i]];
      }
    
    count = [bests count];
    if (count >= 1)
      {
	bottomStart = NSMinX([[bests objectAtIndex: 0] frame]);
	bottomEnd = NSMaxX([[bests objectAtIndex: 0] frame]);
	for ( i = 1; i < count; i++ )
	  {
	    bottomStart = MIN(NSMinX([[bests objectAtIndex: i] frame]), bottomStart);
	    bottomEnd = MAX(NSMaxX([[bests objectAtIndex: i] frame]), bottomEnd);
	  }
	bottomOfFrame = bestBottomPosition;
      }
  }

  gpi->hintFrame = NSMakeRect (leftOfFrame, bottomOfFrame,
			  rightOfFrame - leftOfFrame,
			  topOfFrame - bottomOfFrame);
  {
    [[NSColor redColor] set];
    if (!leftEmpty)
      {
	leftStart = MIN(NSMinY(gpi->hintFrame), leftStart);
	leftEnd = MAX(NSMaxY(gpi->hintFrame), leftEnd);
	gpi->lastLeftRect = NSMakeRect(bestLeftPosition - 1, leftStart, 
				       2, leftEnd - leftStart);
	NSRectFill(gpi->lastLeftRect);
      }
    if (!rightEmpty)
      {
	rightStart = MIN(NSMinY(gpi->hintFrame), rightStart);
	rightEnd = MAX(NSMaxY(gpi->hintFrame), rightEnd);
	gpi->lastRightRect = NSMakeRect(bestRightPosition - 1, rightStart, 
					2, rightEnd - rightStart);
	NSRectFill(gpi->lastRightRect);
      }
    if (!topEmpty)
      {
	topStart = MIN(NSMinX(gpi->hintFrame), topStart);
	topEnd = MAX(NSMaxX(gpi->hintFrame), topEnd);
	gpi->lastTopRect = NSMakeRect(topStart, bestTopPosition - 1,
				      topEnd - topStart, 2);
	NSRectFill(gpi->lastTopRect);
      }
    if (!bottomEmpty)
      {
	bottomStart = MIN(NSMinX(gpi->hintFrame), bottomStart);
	bottomEnd = MAX(NSMaxX(gpi->hintFrame), bottomEnd);
	gpi->lastBottomRect = NSMakeRect(bottomStart, bestBottomPosition - 1, 
					 bottomEnd - bottomStart, 2);
	NSRectFill(gpi->lastBottomRect);
      }

  }



  GormShowFrameWithKnob(gpi->hintFrame, gpi->knob);
  gpi->oldRect = GormExtBoundsForRect(gpi->hintFrame);
  gpi->oldRect.origin.x--;
  gpi->oldRect.origin.y--;
  gpi->oldRect.size.width += 2;
  gpi->oldRect.size.height += 2;

}

- (void) updateResizingWithFrame: (NSRect) frame
			andEvent: (NSEvent *)theEvent
		andPlacementInfo: (GormPlacementInfo*) gpi
{
  if ([theEvent modifierFlags] & NSShiftKeyMask)
    {
      [self _displayFrame: frame
	    withPlacementInfo: gpi];
    }
  else
    [self _displayFrameWithHint: frame
	  withPlacementInfo: gpi];
}

- (void) validateFrame: (NSRect) frame
	     withEvent: (NSEvent *) theEvent
      andPlacementInfo: (GormPlacementInfo*)gpi
{
  if (gpi->leftHints)
    {
      RELEASE(gpi->leftHints);
      RELEASE(gpi->rightHints);
      [self setFrame: gpi->hintFrame];
    }
  else
    {
//        NSLog(@"seting frame %@", NSStringFromRect(frame));
      [self setFrame: frame];
    }
}




- (NSRect) _displayMovingFrameWithHint: (NSRect) frame
		      andPlacementInfo: (GormPlacementInfo*)gpi
{
  float leftOfFrame = NSMinX(frame);
  float rightOfFrame = NSMaxX(frame);
  float topOfFrame = NSMaxY(frame);
  float bottomOfFrame = NSMinY(frame);
  float widthOfFrame = frame.size.width;
  float heightOfFrame = frame.size.height;
  int i;
  int count;
  int lastDistance;
  int minimum = 10;
  BOOL leftEmpty = YES;
  BOOL rightEmpty = YES;
  BOOL topEmpty = YES;
  BOOL bottomEmpty = YES;
  float bestLeftPosition;
  float bestRightPosition;
  float bestTopPosition;
  float bestBottomPosition;
  float leftStart;
  float rightStart;
  float topStart;
  float bottomStart;
  float leftEnd;
  float rightEnd;
  float topEnd;
  float bottomEnd;

  if (gpi->hintInitialized == NO)
    {
      [self _initializeHintWithInfo: gpi];
    }

  {
    [gpi->resizingIn setNeedsDisplayInRect: gpi->lastLeftRect];
    [[self window] displayIfNeeded];
    gpi->lastLeftRect = NSZeroRect;
  }
  {
    [gpi->resizingIn setNeedsDisplayInRect: gpi->lastRightRect];
    [[self window] displayIfNeeded];
    gpi->lastRightRect = NSZeroRect;
  }
  {
    [gpi->resizingIn setNeedsDisplayInRect: gpi->lastTopRect];
    [[self window] displayIfNeeded];
    gpi->lastTopRect = NSZeroRect;
  }
  {
    [gpi->resizingIn setNeedsDisplayInRect: gpi->lastBottomRect];
    [[self window] displayIfNeeded];
    gpi->lastBottomRect = NSZeroRect;
  }


  {
    BOOL empty = YES;
    float bestPosition;
    NSMutableArray *leftBests;
    NSMutableArray *rightBests;
    minimum = 6;
    count = [gpi->leftHints count];

    leftBests = [NSMutableArray arrayWithCapacity: 4];
    for ( i = 0; i < count; i++ )
      {
	lastDistance = [[gpi->leftHints objectAtIndex: i] 
			 distanceToFrame: frame];
	if (lastDistance < minimum)
	  {
	    leftBests = [NSMutableArray arrayWithCapacity: 4];
	    [leftBests addObject: [gpi->leftHints objectAtIndex: i]];
	    minimum = lastDistance;
	    bestPosition = [[gpi->leftHints objectAtIndex: i] position];
	    empty = NO;
	  }
	else if ((lastDistance == minimum) && (empty == NO)
		 && ([[gpi->leftHints objectAtIndex: i] position] == bestPosition))
	  [leftBests addObject: [gpi->leftHints objectAtIndex: i]];
      }

    count = [gpi->rightHints count];
    rightBests = [NSMutableArray arrayWithCapacity: 4];
    for ( i = 0; i < count; i++ )
      {
	lastDistance = [[gpi->rightHints objectAtIndex: i] 
			 distanceToFrame: frame];
	if (lastDistance < minimum)
	  {
	    rightBests = [NSMutableArray arrayWithCapacity: 4];
	    leftBests = [NSMutableArray arrayWithCapacity: 4];
	    [rightBests addObject: [gpi->rightHints objectAtIndex: i]];
	    minimum = lastDistance;
	    bestPosition = [[gpi->rightHints objectAtIndex: i] position] 
	      - widthOfFrame;
	    empty = NO;
	  }
	else if ((lastDistance == minimum) && (empty == NO)
		 && ([[gpi->rightHints objectAtIndex: i] position] - bestPosition
		     == widthOfFrame))
	  [rightBests addObject: [gpi->rightHints objectAtIndex: i]];
      }
    
    count = [leftBests count];
    if (count >= 1)
      {
	float position;
	leftEmpty = NO;
	position = [[leftBests objectAtIndex: 0] position];
	
	leftStart = NSMinY([[leftBests objectAtIndex: 0] frame]);
	leftEnd = NSMaxY([[leftBests objectAtIndex: 0] frame]);
	for ( i = 1; i < count; i++ )
	  {
	    leftStart = MIN(NSMinY([[leftBests objectAtIndex: i] frame]), leftStart);
	    leftEnd = MAX(NSMaxY([[leftBests objectAtIndex: i] frame]), leftEnd);
	  }
	
	leftOfFrame = position;
	rightOfFrame = position + widthOfFrame;
      }

    count = [rightBests count];
    if (count >= 1)
      {
	float position;
	rightEmpty = NO;
	position = [[rightBests objectAtIndex: 0] position];
	
	rightStart = NSMinY([[rightBests objectAtIndex: 0] frame]);
	rightEnd = NSMaxY([[rightBests objectAtIndex: 0] frame]);
	for ( i = 1; i < count; i++ )
	  {
	    rightStart = MIN(NSMinY([[rightBests objectAtIndex: i] frame]), rightStart);
	    rightEnd = MAX(NSMaxY([[rightBests objectAtIndex: i] frame]), rightEnd);
	  }
	
	rightOfFrame = position;
	leftOfFrame = position - widthOfFrame;
      }
  }

  {
    BOOL empty = YES;
    float bestPosition;
    NSMutableArray *bottomBests;
    NSMutableArray *topBests;
    minimum = 6;
    count = [gpi->bottomHints count];

    bottomBests = [NSMutableArray arrayWithCapacity: 4];
    for ( i = 0; i < count; i++ )
      {
	lastDistance = [[gpi->bottomHints objectAtIndex: i] 
			 distanceToFrame: frame];
	if (lastDistance < minimum)
	  {
	    bottomBests = [NSMutableArray arrayWithCapacity: 4];
	    [bottomBests addObject: [gpi->bottomHints objectAtIndex: i]];
	    minimum = lastDistance;
	    bestPosition = [[gpi->bottomHints objectAtIndex: i] position];
	    empty = NO;
	  }
	else if ((lastDistance == minimum) && (empty == NO)
		 && ([[gpi->bottomHints objectAtIndex: i] position] == bestPosition))
	  [bottomBests addObject: [gpi->bottomHints objectAtIndex: i]];
      }

    count = [gpi->topHints count];
    topBests = [NSMutableArray arrayWithCapacity: 4];
    for ( i = 0; i < count; i++ )
      {
	lastDistance = [[gpi->topHints objectAtIndex: i] 
			 distanceToFrame: frame];
	if (lastDistance < minimum)
	  {
	    topBests = [NSMutableArray arrayWithCapacity: 4];
	    bottomBests = [NSMutableArray arrayWithCapacity: 4];
	    [topBests addObject: [gpi->topHints objectAtIndex: i]];
	    minimum = lastDistance;
	    bestPosition = [[gpi->topHints objectAtIndex: i] position] 
	      - heightOfFrame;
	    empty = NO;
	  }
	else if (lastDistance == minimum && (empty == NO)
		 && ([[gpi->topHints objectAtIndex: i] position] - bestPosition
		     == heightOfFrame))
	  [topBests addObject: [gpi->topHints objectAtIndex: i]];
      }
    
    count = [bottomBests count];
    if (count >= 1)
      {
	float position;
	bottomEmpty = NO;
	position = [[bottomBests objectAtIndex: 0] position];
	
	bottomStart = NSMinX([[bottomBests objectAtIndex: 0] frame]);
	bottomEnd = NSMaxX([[bottomBests objectAtIndex: 0] frame]);
	for ( i = 1; i < count; i++ )
	  {
	    bottomStart = MIN(NSMinX([[bottomBests objectAtIndex: i] frame]), bottomStart);
	    bottomEnd = MAX(NSMaxX([[bottomBests objectAtIndex: i] frame]), bottomEnd);
	  }
	
	bottomOfFrame = position;
	topOfFrame = position + heightOfFrame;
      }

    count = [topBests count];
    if (count >= 1)
      {
	float position;
	topEmpty = NO;
	position = [[topBests objectAtIndex: 0] position];
	
	topStart = NSMinX([[topBests objectAtIndex: 0] frame]);
	topEnd = NSMaxX([[topBests objectAtIndex: 0] frame]);
	for ( i = 1; i < count; i++ )
	  {
	    topStart = MIN(NSMinX([[topBests objectAtIndex: i] frame]), topStart);
	    topEnd = MAX(NSMaxX([[topBests objectAtIndex: i] frame]), topEnd);
	  }
	
	topOfFrame = position;
	bottomOfFrame = position - heightOfFrame;
      }
  }

  gpi->hintFrame = NSMakeRect (leftOfFrame, bottomOfFrame,
		     rightOfFrame - leftOfFrame,
		     topOfFrame - bottomOfFrame);

  {
    [[NSColor redColor] set];
    if (!leftEmpty)
      {
	leftStart = MIN(NSMinY(gpi->hintFrame), leftStart);
	leftEnd = MAX(NSMaxY(gpi->hintFrame), leftEnd);
	gpi->lastLeftRect = NSMakeRect(leftOfFrame - 1, leftStart, 
				       2, leftEnd - leftStart);
	NSRectFill(gpi->lastLeftRect);
      }
    
    if (!rightEmpty)
      {
	rightStart = MIN(NSMinY(gpi->hintFrame), rightStart);
	rightEnd = MAX(NSMaxY(gpi->hintFrame), rightEnd);
	gpi->lastRightRect = NSMakeRect(rightOfFrame - 1, rightStart, 
					2, rightEnd - rightStart);
	NSRectFill(gpi->lastRightRect);
      }
    
    if (!topEmpty)
      {
	topStart = MIN(NSMinX(gpi->hintFrame), topStart);
	topEnd = MAX(NSMaxX(gpi->hintFrame), topEnd);
	gpi->lastTopRect = NSMakeRect(topStart, topOfFrame - 1, 
					 topEnd - topStart, 2);
	NSRectFill(gpi->lastTopRect);
      }

    if (!bottomEmpty)
      {
	bottomStart = MIN(NSMinX(gpi->hintFrame), bottomStart);
	bottomEnd = MAX(NSMaxX(gpi->hintFrame), bottomEnd);
	gpi->lastBottomRect = NSMakeRect(bottomStart, bottomOfFrame - 1, 
				      bottomEnd - bottomStart, 2);
	NSRectFill(gpi->lastBottomRect);
      }
  }

  return gpi->hintFrame;
}


//  - (void) displayHintForFrame: (NSRect) frame
//    		   withEvent: (NSEvent *)theEvent
//    		     andKnob: (IBKnobPosition) knob
//  {
//    static NSView *superview;
//    static NSArray *subviews;
//    static int count;
//    static NSRect bounds;
//    NSMutableArray *oldMagnetizedTo;
//    NSMutableArray *attractness0 = [[NSMutableArray alloc] initWithCapacity: 4];
//    NSMutableArray *attractness1 = [[NSMutableArray alloc] initWithCapacity: 4];
//    NSMutableArray *attractness2 = [[NSMutableArray alloc] initWithCapacity: 4];

//    int i;
//    NSRect svFrame;
//    if (displayingHints == NO)
//      {
//        superview = [self superview];
//        subviews = [superview subviews];
//        count = [subviews count];
//        displayingHints = NO;
//        bounds = [superview bounds];
//        displayingHints = YES;
//        magnetizedTo = [[NSMutableArray alloc] initWithCapacity: 4];
//      }

//  //    for (i = 0; i < count; i ++ )
//  //      {
//  //        svFrame = [[subviews objectAtIndex: i] frame];
//  //      }

//    oldMagnetizedTo = magnetizedTo;

//    if (knob == IBTopMiddleKnobPosition)
//      {
//        for ( i = 0; i < count; i++ )
//  	{
//  	  NSView *v = [subviews objectAtIndex: i];
//  	  NSRect vframe = [v frame];
//  	  switch(ATTRACTNESS12(NSMaxY(frame), NSMinY(vframe), NSMaxY(vframe)))
//  	    {
//  	    case 0:
//  	      [attractness0 addObject: v];
//  	      break;
//  	    case 1:
//  	      [attractness1 addObject: v];
//  	      break;
//  	    case 2:
//  	      [attractness2 addObject: v];
//  	      break;
//  	    }
//  	}
//      }
  
//    if ([attractness0 count] != 0)
//      magnetizedTo = RETAIN(attractness0);
//    else if ([attractness1 count] != 0)
//      magnetizedTo = RETAIN(attractness1);
//    else if ([attractness2 count] != 0)
//      magnetizedTo = RETAIN(attractness2);
//    else
//      magnetizedTo = [[NSMutableArray alloc] initWithCapacity: 4];
    
//    RELEASE(attractness0);
//    RELEASE(attractness1);
//    RELEASE(attractness2);

//    //  NSLog(@"attractedTo (%@)", magnetizedTo);

//    return;

//    for (i = 0; i < [oldMagnetizedTo count]; i++)
//      {
//        if ([magnetizedTo containsObject: 
//  			  [oldMagnetizedTo objectAtIndex: i]] == NO)
//  	{
//  	  [superview setNeedsDisplayInRect: 
//  		       NSMakeRect(bounds.origin.x, NSMaxY(bounds) - 6,
//  				  bounds.size.width, 3)];
//  	}
//      }

//    for (i = 0; i < [magnetizedTo count]; i++)
//      {
      
//        [[NSColor blueColor] set];
//        NSRectFill(NSMakeRect(bounds.origin.x, NSMaxY(bounds) - 6,
//  			    bounds.size.width, 3));
//      }

//  }

//  - (void) stopDisplayingHints
//  {
//    if (displayingHints)
//      {
//        RELEASE(magnetizedTo);
//        [[self superview] setNeedsDisplay: YES];
//      }
//    displayingHints = NO;
//  }


- (NSView *)hitTest: (NSPoint)loc
{
  id result;
  result = [super hitTest: loc];
  
  if ((result != nil)
      && [result isKindOfClass: [GormViewEditor class]])
    {
      return result;
    }
  else if (result != nil)
    {
      return self;
    }
  return nil;
}




- (NSWindow*) windowAndRect: (NSRect *)rect forObject: (id) anObject
{
  if (anObject != _editedObject)
    {
      NSLog(@"%@ windowAndRect: object unknown", self);
      return nil;
    }
  else
    {
      *rect = [_editedObject convertRect:[_editedObject visibleRect]
			     toView: nil];
      return _window;
    }
}



- (void) startConnectingObject: (id) anObject
		     withEvent: (NSEvent *)theEvent
{
  NSPasteboard	*pb;
  NSString	*name = [document nameForObject: anObject];
  NSPoint	dragPoint = [theEvent locationInWindow];
  

  pb = [NSPasteboard pasteboardWithName: NSDragPboard];
  [pb declareTypes: [NSArray arrayWithObject: GormLinkPboardType]
      owner: self];
  [pb setString: name forType: GormLinkPboardType];
  [NSApp displayConnectionBetween: anObject and: nil];
  
  //  isLinkSource = YES;
  [self dragImage: [NSApp linkImage]
	at: dragPoint
	offset: NSZeroSize
	event: theEvent
	pasteboard: pb
	source: self
	slideBack: YES];
  //  isLinkSource = NO;

  return;  
}

- (BOOL) acceptsTypeFromArray: (NSArray*)types
{
//    NSLog(@"I said why not !");
  return [types containsObject: GormLinkPboardType];
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
	     and: _editedObject];
      return NSDragOperationLink;
    }
  else
    {
//        NSLog(@"I said None !");
      return NSDragOperationNone;
    }
}


- (void) mouseDown: (NSEvent*)theEvent
{
  // the followinfg commented code was useless

//    BOOL onKnob = NO;

//    {
//      GormViewEditor *parent = [document parentEditorForEditor: self];
    
//      if ([parent respondsToSelector: @selector(selection)] &&
//  	[[parent selection] containsObject: _editedObject])
//        {
//  	IBKnobPosition	knob = IBNoneKnobPosition;
//  	NSPoint mouseDownPoint = 
//  	  [self convertPoint: [theEvent locationInWindow]
//  		fromView: nil];
//  	knob = GormKnobHitInRect([self bounds], 
//  				 mouseDownPoint);
//  	if (knob != IBNoneKnobPosition)
//  	  onKnob = YES;
//        }
//    }

  if ([theEvent modifierFlags] & NSControlKeyMask)
    // start a action/outlet connection
    {
      [self startConnectingObject: _editedObject
	    withEvent: theEvent];
    }
  else
    // just send the event to our parent
    {
//        NSLog(@"md %@ parent is %@ (%@)", self, parent, document);
//        NSLog(@"md %@ super %@, super's super %@,", 
//  	    self, [self superview],
//  	    [[self superview] superview]);

      if (parent)
	{
	  [parent mouseDown: theEvent];
	}
      else
	return [self noResponderFor: @selector(mouseDown:)];
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
  else
    {
      return NO;
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
	     and: _editedObject];
      [NSApp startConnecting];
    }
  return YES;
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL) flag
{
  return NSDragOperationLink;
}


- (BOOL) wantsSelection
{
  return YES;
}

- (void) resetObject: (id)anObject
{
  NSLog(@"resetObject should not be called on GormViewEditor !");
}

- (void) orderFront
{
  [[self window] orderFront: self];
}

- (NSWindow *) window
{
  return [super window];
}
/*
 *  Drawing additions
 */

- (void) postDraw: (NSRect) rect
{
  if ([parent respondsToSelector: @selector(postDrawForView:)])
    [parent performSelector: @selector(postDrawForView:)
	    withObject: self];
}

- (void) displayIfNeededInRectIgnoringOpacity: (NSRect) rect
{
  if (currently_displaying == NO)
    {
      [[self window] disableFlushWindow];
      currently_displaying = YES;
      [super displayIfNeededInRectIgnoringOpacity: rect];
      [self lockFocus];
      [self postDraw: rect];
      [self unlockFocus];
      [[self window] enableFlushWindow];
      [[self window] flushWindow];
      currently_displaying = NO;
    }
  else
    {
      [super displayIfNeededInRectIgnoringOpacity: rect];
      [self lockFocus];
      [self postDraw: rect];
      [self unlockFocus];
    }


    
}

- (void) displayRectIgnoringOpacity: (NSRect) rect
{
  if (currently_displaying == NO)
    {
      [[self window] disableFlushWindow];
      currently_displaying = YES;
      [super displayIfNeededInRectIgnoringOpacity: rect];
      [self lockFocus];
      [self postDraw: rect];
      [self unlockFocus];
      [[self window] enableFlushWindow];
      [[self window] flushWindow];
      currently_displaying = NO;
    }
  else
    {
      [super displayIfNeededInRectIgnoringOpacity: rect];
      [self lockFocus];
      [self postDraw: rect];
      [self unlockFocus];
    }
}
@end





@implementation GormViewEditor (ResponderAdditions)

- (void) keyDown: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder keyDown: theEvent];
  else
    return [self noResponderFor: @selector(keyDown:)];
}

- (void) keyUp: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder keyUp: theEvent];
  else
    return [self noResponderFor: @selector(keyUp:)];
}

- (void) otherMouseDown: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder otherMouseDown: theEvent];
  else
    return [self noResponderFor: @selector(otherMouseDown:)];
}

- (void) otherMouseDragged: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder otherMouseDragged: theEvent];
  else
    return [self noResponderFor: @selector(otherMouseDragged:)];
}

- (void) otherMouseUp: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder otherMouseUp: theEvent];
  else
    return [self noResponderFor: @selector(otherMouseUp:)];
}


- (void) mouseDragged: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseDragged: theEvent];
  else
    return [self noResponderFor: @selector(mouseDragged:)];
}

- (void) mouseEntered: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseEntered: theEvent];
  else
    return [self noResponderFor: @selector(mouseEntered:)];
}

- (void) mouseExited: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseExited: theEvent];
  else
    return [self noResponderFor: @selector(mouseExited:)];
}

- (void) mouseMoved: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseMoved: theEvent];
  else
    return [self noResponderFor: @selector(mouseMoved:)];
}

- (void) mouseUp: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder mouseUp: theEvent];
  else
    return [self noResponderFor: @selector(mouseUp:)];
}

- (void) rightMouseDown: (NSEvent*)theEvent
{
  if (_next_responder != nil)
    return [_next_responder rightMouseDown: theEvent];
  else
    return [self noResponderFor: @selector(rightMouseDown:)];
}

- (void) rightMouseDragged: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder rightMouseDragged: theEvent];
  else
    return [self noResponderFor: @selector(rightMouseDragged:)];
}

- (void) rightMouseUp: (NSEvent*)theEvent
{
  if (_next_responder)
    return [_next_responder rightMouseUp: theEvent];
  else
    return [self noResponderFor: @selector(rightMouseUp:)];
}

- (void) scrollWheel: (NSEvent *)theEvent
{
  if (_next_responder)
    return [_next_responder scrollWheel: theEvent];
  else
    return [self noResponderFor: @selector(scrollWheel:)];
}


- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;
}

- (BOOL) acceptsFirstResponder
{
  return NO;
}
@end


static BOOL done_editing;

@implementation GormViewEditor (EditingAdditions)
- (void) handleNotification: (NSNotification*)aNotification
{
  NSString	*name = [aNotification name];
  if ([name isEqual: NSControlTextDidEndEditingNotification] == YES)
    {
      done_editing = YES;
    }
}

/* Edit a textfield. If it's not already editable, make it so, then
   edit it */
- (NSEvent *) editTextField: view withEvent: (NSEvent *)theEvent
{
  unsigned eventMask;
  BOOL wasEditable;
  BOOL didDrawBackground;
  NSTextField *editField;
  NSRect                 frame;
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  NSDate		*future = [NSDate distantFuture];
  NSEvent *e;
      
  editField = view;
  frame = [editField frame];

  wasEditable = [editField isEditable];
  [editField setEditable: YES];
  didDrawBackground = [editField drawsBackground];
  [editField setDrawsBackground: YES];

//    [editField display];

  [nc addObserver: self
         selector: @selector(handleNotification:)
             name: NSControlTextDidEndEditingNotification
           object: nil];

  /* Do some modal editing */
  [editField selectText: self];
  eventMask = NSLeftMouseDownMask |  NSLeftMouseUpMask  |
  NSKeyDownMask  |  NSKeyUpMask  | NSFlagsChangedMask;

  done_editing = NO;
  while (!done_editing)
    {
      NSEventType eType;
      e = [NSApp nextEventMatchingMask: eventMask
		 untilDate: future
		 inMode: NSEventTrackingRunLoopMode
		 dequeue: YES];
      eType = [e type];
      switch (eType)
	{
	case NSLeftMouseDown:
	  {
	    NSPoint dp =  [self convertPoint: [e locationInWindow]
				fromView: nil];
	    if (NSMouseInRect(dp, frame, NO) == NO)
	      {
		done_editing = YES;
		break;
	      }
	  }
	  [[editField currentEditor] mouseDown: e];
	  break;
	case NSLeftMouseUp:
	  [[editField currentEditor] mouseUp: e];
	  break;
	case NSLeftMouseDragged:
	  [[editField currentEditor] mouseDragged: e];
	  break;
	case NSKeyDown:
	  [[editField currentEditor] keyDown: e];
	  break;
	case NSKeyUp:
	  [[editField currentEditor] keyUp: e];
	  break;
	case NSFlagsChanged:
	  [[editField currentEditor] flagsChanged: e];
	  break;
	default:
	  NSLog(@"Internal Error: Unhandled event during editing: %@", e);
	  break;
	}
    }

  [editField setEditable: wasEditable];
  [editField setDrawsBackground: didDrawBackground];
  [nc removeObserver: self
                name: NSControlTextDidEndEditingNotification
              object: nil];

  [[editField currentEditor] resignFirstResponder];
  [self setNeedsDisplay: YES];

  return e;
}
@end