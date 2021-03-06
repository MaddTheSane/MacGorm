/* NSColor+GormExtensions.m
 *
 * Copyright (C) 2005 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2005
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

#import <AppKit/NSView.h>
#import <AppKit/NSColorPanel.h>
#import <GNUstepBase/GNUstep.h>
#include "NSColorWell+GormExtensions.h"

@implementation NSColorWell (GormExtensions)
#ifdef __APPLE__
#define _the_color _color
#endif

/**
 * Changes the color without sending the action associated with it.
 */
- (void) setColorWithoutAction: (NSColor *)color
{
  ASSIGN(_the_color, color);
  if ([self isActive])
    {
      NSColorPanel	*colorPanel = [NSColorPanel sharedColorPanel];

      [colorPanel setColor: _the_color];
    }
  [self setNeedsDisplay: YES];
}

@end
