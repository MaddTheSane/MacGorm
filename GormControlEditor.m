/* GormControlEditor.m
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

#import "GormViewWithSubviewsEditor.h"
#import "GormControlEditor.h"

#import "GormPlacementInfo.h"

#define _EO ((NSControl *)_editedObject)

@class GormWindowEditor;

@implementation NSControl (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormControlEditor";
}
@end


@interface GormViewEditor (Private)
- (void) _displayFrameWithHint: (NSRect) frame
	     withPlacementInfo: (GormPlacementInfo*)gpi;
- (void) _initializeHintWithInfo: (GormPlacementInfo*) gpi;
@end

@interface GormControlEditor (IntelligentPlacement)
- (void) _altDisplayFrame: (NSRect) frame
	 withPlacementInfo: (GormPlacementInfo*)gpi;
- (void) _displayFrame: (NSRect) frame
     withPlacementInfo: (GormPlacementInfo*) gpi;
@end

@implementation GormControlEditor


//  - (GormPlacementInfo *) initializeResizingInFrame: (NSView *)view
//  						    withKnob: (IBKnobPosition) knob
//  {
//    GormPlacementInfo *gip;
//    gip = [super initializeResizingInFrame: view withKnob: knob];
//  }


- (void) _altDisplayFrame: (NSRect) frame
	 withPlacementInfo: (GormPlacementInfo*)gpi
{
  NSSize size = [self frame].size;
  NSSize constrainedSize;
  int col;
  int row;
  
  if (gpi->firstPass == NO)
    [gpi->resizingIn displayRect: gpi->oldRect];
  else
    gpi->firstPass = NO;

  col = frame.size.width / size.width;
  row = frame.size.height / size.height;
  
  if (col < 1) col = 1;
  if (row < 1) row = 1;
  
  constrainedSize.width = col * size.width;
  constrainedSize.height = row * size.height;
  
  switch (gpi->knob)
    {
    case IBBottomLeftKnobPosition:
    case IBMiddleLeftKnobPosition:
    case IBTopLeftKnobPosition:
      frame.origin.x = NSMaxX(frame) - constrainedSize.width;
      frame.size.width = constrainedSize.width;
      break;
    case IBTopRightKnobPosition:
    case IBMiddleRightKnobPosition:
    case IBBottomRightKnobPosition:
      frame.size.width = constrainedSize.width;
      break;
    case IBTopMiddleKnobPosition:
    case IBBottomMiddleKnobPosition:
    case IBNoneKnobPosition:
      break;
    }
  
  switch (gpi->knob)
    {
    case IBBottomLeftKnobPosition:
    case IBBottomRightKnobPosition:
    case IBBottomMiddleKnobPosition:
      frame.origin.y = NSMaxY(frame) - constrainedSize.height;
      frame.size.height = constrainedSize.height;
      break;
    case IBTopMiddleKnobPosition:
    case IBTopRightKnobPosition:
    case IBTopLeftKnobPosition:
      frame.size.height = constrainedSize.height;
      break;
    case IBMiddleLeftKnobPosition:
    case IBMiddleRightKnobPosition:
    case IBNoneKnobPosition:
      break;
    }

  GormShowFrameWithKnob(frame, gpi->knob);
  gpi->lastFrame = frame;

  gpi->oldRect = GormExtBoundsForRect(frame);
  gpi->oldRect.origin.x--;
  gpi->oldRect.origin.y--;
  gpi->oldRect.size.width += 2;
  gpi->oldRect.size.height += 2;
}

- (void) _displayFrame: (NSRect) frame
     withPlacementInfo: (GormPlacementInfo*) gpi
{
  NSSize minSize;
  
  if (gpi->firstPass == NO)
    [gpi->resizingIn displayRect: gpi->oldRect];
  else
    gpi->firstPass = NO;

  minSize = [[_EO cell] cellSize];
  
  if (frame.size.width < minSize.width)
    {
      switch (gpi->knob)
	{
	case IBBottomLeftKnobPosition:
	case IBMiddleLeftKnobPosition:
	case IBTopLeftKnobPosition:
	  frame.origin.x = NSMaxX([self frame]) - minSize.width;
	  frame.size.width = minSize.width;
	  break;
	case IBTopRightKnobPosition:
	case IBMiddleRightKnobPosition:
	case IBBottomRightKnobPosition:
	  frame.size.width = minSize.width;
	  break;
	case IBTopMiddleKnobPosition:
	case IBBottomMiddleKnobPosition:
	case IBNoneKnobPosition:
	  break;
	}
    }
  
  if (frame.size.height < minSize.height)
    {
      switch (gpi->knob)
	{
	case IBBottomLeftKnobPosition:
	case IBBottomRightKnobPosition:
	case IBBottomMiddleKnobPosition:
	  frame.origin.y = NSMaxY([self frame]) - minSize.height;
	  frame.size.height = minSize.height;
	  break;
	case IBTopMiddleKnobPosition:
	case IBTopRightKnobPosition:
	case IBTopLeftKnobPosition:
	  frame.size.height = minSize.height;
	  break;
	case IBMiddleLeftKnobPosition:
	case IBMiddleRightKnobPosition:
	case IBNoneKnobPosition:
	  break;
	}
    }
  
  GormShowFrameWithKnob(frame, gpi->knob);
  gpi->lastFrame = frame;
  
  gpi->oldRect = GormExtBoundsForRect(frame);
  gpi->oldRect.origin.x--;
  gpi->oldRect.origin.y--;
  gpi->oldRect.size.width += 2;
  gpi->oldRect.size.height += 2;
}

//  - (void) _displayFrameWithHint: (NSRect) frame
//  	     withPlacementInfo: (GormPlacementInfo*)gpi
//  {
//    float leftOfFrame = NSMinX(frame);
//    float rightOfFrame = NSMaxX(frame);
//    float topOfFrame = NSMaxY(frame);
//    float bottomOfFrame = NSMinY(frame);
//    int i;
//    int count;
//    int lastDistance;
//    int minimum = 10;
//    NSMutableArray *bests;
//    if (gpi->hintInitialized == NO)
//      {
//        [self _initializeHintWithInfo: gpi];
//      }

//    {
//      if (gpi->firstPass == NO)
//        [gpi->resizingIn displayRect: gpi->oldRect];
//      else
//        gpi->firstPass = NO;
//    }
//    {
//      [gpi->resizingIn setNeedsDisplayInRect: gpi->lastLeftRect];
//      [[self window] displayIfNeeded];
//      gpi->lastLeftRect = NSZeroRect;
//    }
//    {
//      [gpi->resizingIn setNeedsDisplayInRect: gpi->lastRightRect];
//      [[self window] displayIfNeeded];
//      gpi->lastRightRect = NSZeroRect;
//    }
//    {
//      [gpi->resizingIn setNeedsDisplayInRect: gpi->lastTopRect];
//      [[self window] displayIfNeeded];
//      gpi->lastTopRect = NSZeroRect;
//    }
//    {
//      [gpi->resizingIn setNeedsDisplayInRect: gpi->lastBottomRect];
//      [[self window] displayIfNeeded];
//      gpi->lastBottomRect = NSZeroRect;
//    }


//    if (gpi->knob == IBTopLeftKnobPosition
//        || gpi->knob == IBMiddleLeftKnobPosition
//        || gpi->knob == IBBottomLeftKnobPosition)
//    {
//      bests = [NSMutableArray arrayWithCapacity: 4];
//      minimum = 6;
//      count = [gpi->leftHints count];
//      for ( i = 0; i < count; i++ )
//        {
//  	lastDistance = [[gpi->leftHints objectAtIndex: i] 
//  			 distanceToFrame: frame];
//  	if (lastDistance < minimum)
//  	  {
//  	    bests = [NSMutableArray arrayWithCapacity: 4];
//  	    [bests addObject: [gpi->leftHints objectAtIndex: i]];
//  	    minimum = lastDistance;
//  	  }
//  	else if (lastDistance == minimum)
//  	  [bests addObject: [gpi->leftHints objectAtIndex: i]];
//        }
    
//      count = [bests count];
    
    
//      if (count >= 1)
//        {
//  	float start, end, position;
//  	position = [[bests objectAtIndex: 0] position];
	
//  	start = NSMinY(frame);
//  	end = NSMaxY(frame);
//  	for ( i = 0; i < count; i++ )
//  	  {
//  	    start = MIN(NSMinY([[bests objectAtIndex: i] frame]), start);
//  	    end = MAX(NSMaxY([[bests objectAtIndex: i] frame]), end);
//  	  }
	
//  	[[NSColor redColor] set];
//  	NSRectFill(NSMakeRect(position - 1, start, 2, end - start));
//  	gpi->lastLeftRect = NSMakeRect(position - 1, start, 2, end - start);
//  	leftOfFrame = position;
//        }
//    }

//    if (gpi->knob == IBTopRightKnobPosition
//        || gpi->knob == IBMiddleRightKnobPosition
//        || gpi->knob == IBBottomRightKnobPosition)
//    {
//      bests = [NSMutableArray arrayWithCapacity: 4];
//      minimum = 6;
//      count = [gpi->rightHints count];
//      for ( i = 0; i < count; i++ )
//        {
//  	lastDistance = [[gpi->rightHints objectAtIndex: i] 
//  			 distanceToFrame: frame];
//  	if (lastDistance < minimum)
//  	  {
//  	    bests = [NSMutableArray arrayWithCapacity: 4];
//  	    [bests addObject: [gpi->rightHints objectAtIndex: i]];
//  	    minimum = lastDistance;
//  	  }
//  	else if (lastDistance == minimum)
//  	  [bests addObject: [gpi->rightHints objectAtIndex: i]];
//        }
    
//      count = [bests count];
    
    
//      if (count >= 1)
//        {
//  	float start, end, position;
//  	position = [[bests objectAtIndex: 0] position];
	
//  	start = NSMinY(frame);
//  	end = NSMaxY(frame);
//  	for ( i = 0; i < count; i++ )
//  	  {
//  	    start = MIN(NSMinY([[bests objectAtIndex: i] frame]), start);
//  	    end = MAX(NSMaxY([[bests objectAtIndex: i] frame]), end);
//  	  }
	
//  	[[NSColor redColor] set];
//  	NSRectFill(NSMakeRect(position - 1, start, 2, end - start));
//  	gpi->lastRightRect = NSMakeRect(position - 1, start, 2, end - start);
//  	rightOfFrame = position;
//        }
//    }

//    if (gpi->knob == IBTopRightKnobPosition
//        || gpi->knob == IBTopLeftKnobPosition
//        || gpi->knob == IBTopMiddleKnobPosition)
//    {
//      bests = [NSMutableArray arrayWithCapacity: 4];
//      minimum = 6;
//      count = [gpi->topHints count];
//      for ( i = 0; i < count; i++ )
//        {
//  	lastDistance = [[gpi->topHints objectAtIndex: i] 
//  			 distanceToFrame: frame];
//  	if (lastDistance < minimum)
//  	  {
//  	    bests = [NSMutableArray arrayWithCapacity: 4];
//  	    [bests addObject: [gpi->topHints objectAtIndex: i]];
//  	    minimum = lastDistance;
//  	  }
//  	else if (lastDistance == minimum)
//  	  [bests addObject: [gpi->topHints objectAtIndex: i]];
//        }
    
//      count = [bests count];
    
    
//      if (count >= 1)
//        {
//  	float start, end, position;
//  	position = [[bests objectAtIndex: 0] position];
	
//  	start = NSMinX(frame);
//  	end = NSMaxX(frame);
//  	for ( i = 0; i < count; i++ )
//  	  {
//  	    start = MIN(NSMinX([[bests objectAtIndex: i] frame]), start);
//  	    end = MAX(NSMaxX([[bests objectAtIndex: i] frame]), end);
//  	  }
	
//  	[[NSColor redColor] set];
//  	NSRectFill(NSMakeRect(start, position - 1, end - start, 2));
//  	gpi->lastTopRect = NSMakeRect(start, position - 1, end - start, 2);
//  	topOfFrame = position;
//        }
//    }

//    if (gpi->knob == IBBottomRightKnobPosition
//        || gpi->knob == IBBottomLeftKnobPosition
//        || gpi->knob == IBBottomMiddleKnobPosition)
//    {
//      bests = [NSMutableArray arrayWithCapacity: 4];
//      minimum = 6;
//      count = [gpi->bottomHints count];
//      for ( i = 0; i < count; i++ )
//        {
//  	lastDistance = [[gpi->bottomHints objectAtIndex: i] 
//  			 distanceToFrame: frame];
//  	if (lastDistance < minimum)
//  	  {
//  	    bests = [NSMutableArray arrayWithCapacity: 4];
//  	    [bests addObject: [gpi->bottomHints objectAtIndex: i]];
//  	    minimum = lastDistance;
//  	  }
//  	else if (lastDistance == minimum)
//  	  [bests addObject: [gpi->bottomHints objectAtIndex: i]];
//        }
    
//      count = [bests count];
    
    
//      if (count >= 1)
//        {
//  	float start, end, position;
//  	position = [[bests objectAtIndex: 0] position];
	
//  	start = NSMinX(frame);
//  	end = NSMaxX(frame);
//  	for ( i = 0; i < count; i++ )
//  	  {
//  	    start = MIN(NSMinX([[bests objectAtIndex: i] frame]), start);
//  	    end = MAX(NSMaxX([[bests objectAtIndex: i] frame]), end);
//  	  }
	
//  	[[NSColor redColor] set];
//  	NSRectFill(NSMakeRect(start, position - 1, end - start, 2));
//  	gpi->lastBottomRect = NSMakeRect(start, position - 1, end - start, 2);
//  	bottomOfFrame = position;
//        }
//    }

//    gpi->hintFrame = NSMakeRect (leftOfFrame, bottomOfFrame,
//  			  rightOfFrame - leftOfFrame,
//  			  topOfFrame - bottomOfFrame);

//    GormShowFrameWithKnob(gpi->hintFrame, gpi->knob);
//    gpi->oldRect = GormExtBoundsForRect(gpi->hintFrame);
//    gpi->oldRect.origin.x--;
//    gpi->oldRect.origin.y--;
//    gpi->oldRect.size.width += 2;
//    gpi->oldRect.size.height += 2;

//  }

#undef MIN
#undef MAX

#define MIN(a,b) (a>b?b:a)
#define MAX(a,b) (a>b?a:b)


- (void) _displayFrameWithHint: (NSRect) frame
	     withPlacementInfo: (GormPlacementInfo*)gpi
{
  float leftOfFrame;
  float rightOfFrame;
  float topOfFrame;
  float bottomOfFrame;
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
  NSSize minSize;

  minSize = [[_EO cell] cellSize];

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


  if (frame.size.width < minSize.width)
    {
      switch (gpi->knob)
	{
	case IBBottomLeftKnobPosition:
	case IBMiddleLeftKnobPosition:
	case IBTopLeftKnobPosition:
	  frame.origin.x = NSMaxX([self frame]) - minSize.width;
	  frame.size.width = minSize.width;
	  break;
	case IBTopRightKnobPosition:
	case IBMiddleRightKnobPosition:
	case IBBottomRightKnobPosition:
	  frame.size.width = minSize.width;
	  break;
	case IBTopMiddleKnobPosition:
	case IBBottomMiddleKnobPosition:
	case IBNoneKnobPosition:
	  break;
	}
    }
  
  if (frame.size.height < minSize.height)
    {
      switch (gpi->knob)
	{
	case IBBottomLeftKnobPosition:
	case IBBottomRightKnobPosition:
	case IBBottomMiddleKnobPosition:
	  frame.origin.y = NSMaxY([self frame]) - minSize.height;
	  frame.size.height = minSize.height;
	  break;
	case IBTopMiddleKnobPosition:
	case IBTopRightKnobPosition:
	case IBTopLeftKnobPosition:
	  frame.size.height = minSize.height;
	  break;
	case IBMiddleLeftKnobPosition:
	case IBMiddleRightKnobPosition:
	case IBNoneKnobPosition:
	  break;
	}
    }

  leftOfFrame = NSMinX(frame);
  rightOfFrame = NSMaxX(frame);
  topOfFrame = NSMaxY(frame);
  bottomOfFrame = NSMinY(frame);


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
	if ((lastDistance < minimum) 
	    && (rightOfFrame - [[gpi->leftHints objectAtIndex: i] position]
		>= minSize.width))
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
	if (lastDistance < minimum
	    && ([[gpi->rightHints objectAtIndex: i] position] - leftOfFrame
		>= minSize.width))
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
	if (lastDistance < minimum
	    && ([[gpi->topHints objectAtIndex: i] position] - bottomOfFrame
		>= minSize.height))

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
	if (lastDistance < minimum
	    && (topOfFrame - [[gpi->bottomHints objectAtIndex: i] position]
		>= minSize.height))
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
  if ([theEvent modifierFlags] & NSAlternateKeyMask)
    [self _altDisplayFrame: frame
	  withPlacementInfo: gpi];
  else if ([theEvent modifierFlags] & NSShiftKeyMask)
    [self _displayFrame: frame
	  withPlacementInfo: gpi];
  else
    [self _displayFrameWithHint: frame
	  withPlacementInfo: gpi];
}

- (void) validateFrame: (NSRect) frame
	     withEvent: (NSEvent *) theEvent
      andPlacementInfo: (GormPlacementInfo*)gpi
{
  frame = gpi->lastFrame;
  if ([theEvent modifierFlags] & NSAlternateKeyMask)
    {
      NSSize cellSize = [self frame].size;
      id editor;
      int col;
      int row;
      NSMatrix *matrix;

      col = gpi->lastFrame.size.width / cellSize.width;
      row = gpi->lastFrame.size.height / cellSize.height;

//        NSLog(@"parentEditor %@", we);

      // let's morph into a matrix
      matrix = [[NSMatrix alloc] initWithFrame: gpi->lastFrame
				 mode: NSRadioModeMatrix
				 prototype: [_EO cell]
				 numberOfRows: row
				 numberOfColumns: col];
      
      [matrix setIntercellSpacing: NSMakeSize(0, 0)];
      [matrix setFrame: gpi->lastFrame];


      RETAIN(self);

      [[self superview] addSubview: matrix];

      [parent selectObjects: [NSArray arrayWithObject: self]];
      [parent deleteSelection];

      [document attachObject: matrix toParent: _EO];

//        NSLog(@"gonna open editor");
      editor = [document editorForObject: matrix 
			 inEditor: parent
			 create: YES];

//        NSLog(@"editor %@", editor);
      
      [parent selectObjects: [NSArray arrayWithObject: editor]];
      

      RELEASE(self);
    }
  else if ([theEvent modifierFlags] & NSShiftKeyMask)
    {
      [self setFrame: frame];
    }
  else
    {
      [super validateFrame: frame
	     withEvent: theEvent
	     andPlacementInfo: gpi];
    }

}

@end

@implementation NSTextField (GormObjectAdditions)
- (NSString*) editorClassName
{
  return @"GormTextFieldEditor";
}
@end



@interface GormTextFieldEditor : GormControlEditor

@end

@implementation GormTextFieldEditor
- (void) mouseDown:  (NSEvent*)theEvent
{
  if (([theEvent clickCount] == 2) && [parent isOpened])
    // double-clicked -> let's edit
    {
      [self editTextField: _editedObject
	    withEvent: theEvent];
      [[NSNotificationCenter defaultCenter]
	postNotificationName: IBSelectionChangedNotification
	object: parent];
    }
  else
    {
      [super mouseDown: theEvent];
    }
}
@end


