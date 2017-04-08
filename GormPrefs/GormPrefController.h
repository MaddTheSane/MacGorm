/* GormShelfPref.m
 *  
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author: Gregory Casamento <greg_casamento@yahoo.com>
 * Date: February 2004
 *
 * This class is heavily based on work done by Enrico Sersale
 * on ShelfPref.m for GWorkspace.
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#ifndef INCLUDED_GormPrefController_h
#define INCLUDED_GormPrefController_h

#import <Foundation/NSObject.h>
#import <AppKit/NSWindowController.h>

@class NSBox;
@class NSPopUpButton;
@class NSWindow;

@class GormGeneralPref;
@class GormHeadersPref;
@class GormShelfPref;
@class GormPalettesPref;
@class GormPluginsPref;
@class GormGuidelinePref;

@interface GormPrefController : NSObject
{
  IBOutlet NSWindow *panel;
  IBOutlet NSPopUpButton *popup;
  IBOutlet NSBox *prefBox;

  GormGeneralPref *_generalView;
  GormHeadersPref *_headersView;
  GormShelfPref *_shelfView;
  id _colorsView;
  GormPalettesPref *_palettesView;
  GormPluginsPref *_pluginsView;
  GormGuidelinePref *_guidelineView;
}

/**
 * Called when the popup is used to select a pref panel.
 */
- (IBAction) popupAction: (id)sender;

/**
 * Return the preferences panel.
 */
- (NSWindow*) panel;
@end

#endif
