/*
  GormProgressIndicatorAttributesInspector.m

   Copyright (C) 2001-2005 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
              Laurent Julliard <laurent@julliard-online.org>
   Date: Aug 2001
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/

/*
  July 2005 : Split inspector classes into separate files.
  Always use ok: revert: methods
  Clean up
  Author : Fabien Vallon <fabien@sonappart.net>
*/

#include "GormProgressIndicatorAttributesInspector.h"

#import <Foundation/NSNotification.h>

#import <AppKit/NSButton.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSProgressIndicator.h>
#import <AppKit/NSTextField.h>


/*
  IBObjectAdditions category
*/
@implementation NSProgressIndicator (IBObjectAdditions)
- (NSString *) inspectorClassName
{
  return @"GormProgressIndicatorAttributesInspector";
}
@end



@implementation GormProgressIndicatorAttributesInspector

-(id) init
{
  if ( (   self = [super init] ) == nil)
    return nil;

  if ( [NSBundle loadNibNamed: @"GormNSProgressIndicatorInspector"  
		 owner: self] == NO )
    {
      NSLog(@"Could not open gorm GormNSProgressIndicatorInspector");
      return nil;
    }
  
  return self;
}

/* Commit changes that the user makes in the Attributes Inspector */
-(void) ok: (id) sender 
{
  if ( sender == indeterminate ) 
    {
      [object setIndeterminate: ([indeterminate state] == NSOnState)];
    }
  else if (sender == vertical ) 
    {
      [object setVertical: ([vertical state] == NSOnState)];
    } 
  else if ( sender == minValue ) 
    {
      [object setMinValue: [minValue doubleValue]];
    }
  else if ( sender == maxValue ) 
    {
      [object setMaxValue: [maxValue doubleValue]];
    }
  
  [super ok: sender];
}

/* Sync from object (ProgressIndicator ) changes to the inspector   */
- (void) revert:(id) sender
{
  if ( object == nil ) 
    return;
  [indeterminate setState: [object isIndeterminate]?NSOnState:NSOffState];
  [vertical setState: [object isVertical] ? NSOnState:NSOffState];
  [minValue setIntValue: [object minValue]];
  [maxValue setIntValue: [object maxValue]];

  [super revert:sender];
}


/* delegate method for titleForm */
- (void)controlTextDidChange:(NSNotification *)aNotification
{
  [self ok: [aNotification object]];
}

@end
