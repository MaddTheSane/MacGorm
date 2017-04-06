/* GormPlacementInfo.h
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
#ifndef	INCLUDED_GormPlacementInfo_h
#define	INCLUDED_GormPlacementInfo_h

#import <Foundation/NSObject.h>
#import <GormLib/InterfaceBuilder.h>

@class NSView, NSMutableArray;
@class GormPlacementHint;

@interface GormPlacementInfo : NSObject
{
@public
  NSView *resizingIn;
  NSRect oldRect;
  BOOL firstPass;
  BOOL hintInitialized;
  NSMutableArray<GormPlacementHint*> *leftHints;
  NSMutableArray<GormPlacementHint*> *rightHints;
  NSMutableArray<GormPlacementHint*> *topHints;
  NSMutableArray<GormPlacementHint*> *bottomHints;
  NSRect lastLeftRect;
  NSRect lastRightRect;
  NSRect lastTopRect;
  NSRect lastBottomRect;
  NSRect hintFrame;
  NSRect lastFrame;
  IBKnobPosition knob;
}
@end

typedef enum _GormHintBorder
{
  Top, Bottom, Left, Right
} GormHintBorder;

@interface GormPlacementHint : NSObject
{
  GormHintBorder _border;
  CGFloat _position;
  CGFloat _start;
  CGFloat _end;
  NSRect _frame;
}
- (id) initWithBorder: (GormHintBorder) border
             position: (CGFloat) position
        validityStart: (CGFloat) start
          validityEnd: (CGFloat) end
                frame: (NSRect) frame;
- (NSRect) rectWithHalfDistance: (NSInteger) halfDistance;
- (NSInteger) distanceToFrame: (NSRect) frame;
@property (readonly) CGFloat position;
@property (readonly) CGFloat start;
@property (readonly) CGFloat end;
@property (readonly) NSRect frame;
@property (readonly) GormHintBorder border;
@end

#endif
