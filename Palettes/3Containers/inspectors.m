/* inspectors - Various inspectors for control elements

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Laurent Julliard <laurent@julliard-online.org>
   Date: Aug 2001
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "../../GormPrivate.h"

/* This macro makes sure that the string contains a value, even if @"" */
#define VSTR(str) ({id _str = str; (_str) ? _str : @"";})

/*----------------------------------------------------------------------------
 * NSBrowser
 */
@implementation	NSBrowser (IBInspectorClassNames)

- (NSString*) inspectorClassName
{
  return @"GormBrowserAttributesInspector";
}

@end

@interface GormBrowserAttributesInspector : IBInspector
{
  id optionMatrix;
  id tagField;
}

- (void) _getValuesFromObject: (id)anObject;
@end

@implementation GormBrowserAttributesInspector


- (void) _setValuesFromControl: (id)control
{
  if (control == optionMatrix)
    {
      BOOL flag;

      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsMultipleSelection: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsEmptySelection: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setAllowsBranchSelection: flag];

      flag = ([[control cellAtRow: 3 column: 0] state] == NSOnState) ? YES : NO;
      [object setSeparatesColumns: flag];
      
      flag = ([[control cellAtRow: 4 column: 0] state] == NSOnState) ? YES : NO;
      [object setTitled: flag];

      flag = ([[control cellAtRow: 5 column: 0] state] == NSOnState) ? YES : NO;
      [object setHasHorizontalScroller: flag];
    }
  else if( control == tagField )
    {
      [object setTag:[[tagField cellAtIndex:0] intValue]];
    }
}

- (void) _getValuesFromObject: anObject
{
  
  if (anObject != object)
    {
      return;
    }
  
  [optionMatrix deselectAllCells];
  if ([anObject allowsMultipleSelection])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject allowsEmptySelection])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject allowsBranchSelection])
    [optionMatrix selectCellAtRow: 2 column: 0];
  if ([anObject separatesColumns])
    [optionMatrix selectCellAtRow: 3 column: 0];
  if ([anObject isTitled])
    [optionMatrix selectCellAtRow: 4 column: 0];
  if ([anObject hasHorizontalScroller])
    [optionMatrix selectCellAtRow: 5 column: 0];
  
  [[tagField cellAtIndex:0] setIntValue:[anObject tag]];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormBrowserInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormBrowserInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

@interface GormViewSizeInspector : IBInspector
{
  NSButton	*top;
  NSButton	*bottom;
  NSButton	*left;
  NSButton	*right;
  NSButton	*width;
  NSButton	*height;
  NSForm        *sizeForm;
}
@end

@interface GormTableViewSizeInspector : GormViewSizeInspector
@end
@implementation GormTableViewSizeInspector
- (void) setObject: (id)anObject
{
  id scrollView;
  scrollView = [anObject enclosingScrollView];

  [super setObject: scrollView];
}
@end

/*----------------------------------------------------------------------------
 * NSTableColumn
 */
@implementation NSTableColumn (IBInspectorClassNames)
- (NSString *) inspectorClassName
{
  return @"GormTableColumnAttributesInspector";
}

- (NSString*) sizeInspectorClassName
{
  return @"GormTableColumnSizeInspector";
}

@end

@interface GormTableColumnAttributesInspector : IBInspector
{
  id titleAlignmentMatrix;
  id contentsAlignmentMatrix;
  id identifierTextField;
  id resizableSwitch;
  id editableSwitch;
}
@end

@implementation GormTableColumnAttributesInspector
- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormTableColumnInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTableColumnInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  NSLog(@"ok");
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}
- (void) _getValuesFromObject: anObject
{
  switch ([[anObject headerCell] alignment])
    {
    case NSLeftTextAlignment:
      [titleAlignmentMatrix selectCellAtRow: 0 column: 0];
      break;
    case NSCenterTextAlignment:
      [titleAlignmentMatrix selectCellAtRow: 0 column: 1];
      break;
    case NSRightTextAlignment:
      [titleAlignmentMatrix selectCellAtRow: 0 column: 2];
      break;
      
    }

  switch ([[anObject dataCell] alignment])
    {
    case NSLeftTextAlignment:
      [contentsAlignmentMatrix selectCellAtRow: 0 column: 0];
      break;
    case NSCenterTextAlignment:
      [contentsAlignmentMatrix selectCellAtRow: 0 column: 1];
      break;
    case NSRightTextAlignment:
      [contentsAlignmentMatrix selectCellAtRow: 0 column: 2];
      break;
      
    }

  [identifierTextField setStringValue: [anObject identifier]];

  if ([anObject isResizable])
    [resizableSwitch setState: NSOnState];
  else
    [resizableSwitch setState: NSOffState];

  if ([anObject isEditable])
    [editableSwitch setState: NSOnState];
  else
    [editableSwitch setState: NSOffState];
}

- (void) _setValuesFromControl: (id) control
{
  if (control == titleAlignmentMatrix)
    {
      if ([[control cellAtRow: 0 column: 0] state] == NSOnState)
	{
	  [[object headerCell] setAlignment: NSLeftTextAlignment];
	}
      else if ([[control cellAtRow: 0 column: 1] state] == NSOnState)
	{
	  [[object headerCell] setAlignment: NSCenterTextAlignment];
	}
      else if ([[control cellAtRow: 0 column: 2] state] == NSOnState)
	{
	  [[object headerCell] setAlignment: NSRightTextAlignment];
	}

      if ([[object tableView] headerView] != nil)
	{
	  [[[object tableView] headerView] setNeedsDisplay: YES];
	}
    }
  else if (control == contentsAlignmentMatrix)
    {
      if ([[control cellAtRow: 0 column: 0] state] == NSOnState)
	{
	  [[object dataCell] setAlignment: NSLeftTextAlignment];
	}
      else if ([[control cellAtRow: 0 column: 1] state] == NSOnState)
	{
	  [[object dataCell] setAlignment: NSCenterTextAlignment];
	}
      else if ([[control cellAtRow: 0 column: 2] state] == NSOnState)
	{
	  [[object dataCell] setAlignment: NSRightTextAlignment];
	}
      [[object tableView] setNeedsDisplay: YES];
    }
  else if (control == identifierTextField)
    {
      [object setIdentifier:
		[identifierTextField stringValue]];
    }
  else if (control == editableSwitch)
    {
      [object setEditable:
		([editableSwitch state] == NSOnState)];
    }
  else if (control == resizableSwitch)
    {
      [object setResizable:
		([resizableSwitch state] == NSOnState)];
    }
}
@end

@interface GormTableColumnSizeInspector : IBInspector
{
  id widthForm;
}
@end

@implementation GormTableColumnSizeInspector
- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormTableColumnSizeInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTableColumnSizeInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}
- (void) _getValuesFromObject: anObject
{
  [[widthForm cellAtRow: 0 column: 0] setFloatValue:
					[anObject minWidth]];
  [[widthForm cellAtRow: 1 column: 0] setFloatValue:
					[anObject width]];
  [[widthForm cellAtRow: 2 column: 0] setFloatValue:
					[anObject maxWidth]];
}

- (void) _setValuesFromControl: (id) control
{
  [object setMinWidth:
	    [[widthForm cellAtRow: 0 column: 0] floatValue]];
  [object setWidth:
	    [[widthForm cellAtRow: 1 column: 0] floatValue]];
  [object setMaxWidth:
	    [[widthForm cellAtRow: 2 column: 0] floatValue]];

  [self _getValuesFromObject: object];
}
@end

/*----------------------------------------------------------------------------
 * NSTableView (possibly embedded in a Scroll view)
 */
@implementation	NSTableView (IBInspectorClassNames)

- (NSString*) inspectorClassName
{
  return @"GormTableViewAttributesInspector";
}

- (NSString*) sizeInspectorClassName
{
  return @"GormTableViewSizeInspector";
}

@end

@interface GormTableViewAttributesInspector : IBInspector
{
  id selectionMatrix;
  id verticalScrollerSwitch;
  id horizontalScrollerSwitch;
  id borderMatrix;
  id rowsHeightForm;
  id optionMatrix;
  id tagField;
}

- (void) _getValuesFromObject: (id)anObject;
@end

@implementation GormTableViewAttributesInspector


- (void) _setValuesFromControl: (id)control
{
  BOOL flag;
  BOOL isScrollView;
  id scrollView;

  scrollView = [[object superview] superview];
  isScrollView = [ scrollView isKindOfClass: [NSScrollView class]];

  if (control == selectionMatrix)
    {
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsMultipleSelection: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsEmptySelection: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsColumnSelection: flag];
    }

  else if ( (control == verticalScrollerSwitch) && isScrollView)
    {
      flag = ([control state] == NSOnState) ? YES : NO;
      [scrollView setHasVerticalScroller: flag];
    }
 
  else if ( (control == horizontalScrollerSwitch) && isScrollView)
    {
      flag = ([control state] == NSOnState) ? YES : NO;
      [scrollView setHasHorizontalScroller: flag];
    } 

  else if ( (control == borderMatrix) && isScrollView)
    {
      [scrollView setBorderType: [[control selectedCell] tag]];
    }
  
  else if (control == rowsHeightForm)
    {
      [object setRowHeight: [[control cellAtIndex: 0] intValue] ];
    } 

  else if (control == optionMatrix)
    {
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setDrawsGrid: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsColumnResizing: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setGormAllowsColumnReordering: flag];
    }
  else if( control == tagField )
    {
      [object setTag:[[tagField cellAtIndex:0] intValue]];
    }
  
  [scrollView setNeedsDisplay: YES];

}

- (void) _getValuesFromObject: anObject
{
  BOOL isScrollView;
  id scrollView;

  scrollView = //[[object superview] superview];
    [object enclosingScrollView];

  isScrollView = [ scrollView isKindOfClass: [NSScrollView class]];

  if (anObject != object)
    {
      return;
    }

  [selectionMatrix deselectAllCells];
  if ([anObject gormAllowsMultipleSelection])
    [selectionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject gormAllowsEmptySelection])
    [selectionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject gormAllowsColumnSelection])
    [selectionMatrix selectCellAtRow: 2 column: 0];

  if (isScrollView)
    {
      [verticalScrollerSwitch setEnabled: YES];
      [verticalScrollerSwitch setState: 
         ([scrollView hasVerticalScroller]) ? NSOnState : NSOffState];

      [horizontalScrollerSwitch setEnabled: YES];   
      [horizontalScrollerSwitch setState: 
         ([scrollView hasHorizontalScroller]) ? NSOnState : NSOffState];

      [borderMatrix setEnabled: YES];
      [borderMatrix selectCellWithTag: [scrollView borderType]];
    }
  else
    {
      [verticalScrollerSwitch setEnabled: NO];
      [horizontalScrollerSwitch setEnabled: NO];   
      [borderMatrix setEnabled: NO];   
    }

  [[rowsHeightForm cellAtIndex: 0] setIntValue: [anObject rowHeight] ];

  [optionMatrix deselectAllCells];
  if ([anObject drawsGrid])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject gormAllowsColumnResizing])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject gormAllowsColumnReordering])
    [optionMatrix selectCellAtRow: 2 column: 0];
  [[tagField cellAtIndex:0] setIntValue:[anObject tag]];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }

  if ([NSBundle loadNibNamed: @"GormTableViewInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTableViewInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end


/*----------------------------------------------------------------------------
 * NSScrollView
 */

/*
 * For now NSScrollView has no inspector in itself. It is only used as a 
 * convenience in the NSTableView and NSTextView controls and there
 * are minimal NSScrollView settings in the inspector of these 2 controls
 * (like horizontal and vertical scrollbar)
*/

@implementation	NSScrollView (IBInspectorClassNames)

- (NSString*) inspectorClassName
{
  return @"GormEmptyInspector";
}

@end

@interface GormScrollViewAttributesInspector : IBInspector
{
}
@end

@implementation GormScrollViewAttributesInspector
@end
