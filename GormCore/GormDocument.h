/* GormDocument.h
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#ifndef INCLUDED_GormDocument_h
#define INCLUDED_GormDocument_h

#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#include <GNUstepGUI/GSNibTemplates.h>
#include <InterfaceBuilder/InterfaceBuilder.h>

@class GormClassManager, GormClassEditor, GormObjectProxy, GormFilesOwner, GormFilePrefsManager;

/*
 * Each document has a GormFirstResponder object that is used as a placeholder
 * for the first responder at any instant.
 */
@interface GormFirstResponder : NSObject
{
}
@end

@interface GormDocument : NSDocument <IBDocuments, GSNibContainer, NSCoding>
{
  GormClassManager      *classManager;
  GormFilesOwner	*filesOwner;
  GormFirstResponder	*firstResponder;
  GormObjectProxy       *fontManager;
  NSMapTable		*objToName;
  NSWindow		*window;
  NSBox                 *selectionBox;
  NSScrollView		*scrollView;
  NSScrollView          *classesScrollView;
  NSScrollView          *soundsScrollView;
  NSScrollView          *imagesScrollView;
  id                    classesView;
  id			objectsView;
  id			soundsView;
  id			imagesView;
  BOOL			isActive;
  BOOL                  isDocumentOpen;
  NSMenu		*savedMenu;
  NSMenuItem		*quitItem;		/* Replaced during test-mode */
  NSMutableArray	*savedEditors;
  NSMutableArray	*hidden;
  NSMutableArray        *openEditors;
  NSToolbar             *toolbar;
  id                    lastEditor;
  BOOL                  isOlderArchive;
  id                    filePrefsView;
  GormFilePrefsManager  *filePrefsManager;
  NSWindow              *filePrefsWindow;
  NSMutableArray        *resourceManagers;
  NSData                *infoData;   /* data.info contents */
  NSMutableArray        *images;     /* temporary storage for images. */             
  NSMutableArray        *sounds;     /* temporary storage for sounds. */
  NSFileWrapper         *scmWrapper;

  // container data structures
  NSMutableDictionary   *nameTable;
  NSMutableArray        *connections;
  NSMutableSet          *topLevelObjects;
  NSMutableSet          *visibleWindows;
  NSMutableSet          *deferredWindows;
}

/* Archiving objects */

/**
 * Start the archiving process.
 */
- (void) beginArchiving;

/**
 * Stop the archiving process.
 */
- (void) endArchiving;

/* Handle notifications */

/**
 * Handle all notifications.   Checks the value of [aNotification name]
 * against the set of notifications this class responds to and takes
 * appropriate action.
 */
- (void) handleNotification: (NSNotification*)aNotification;

/* Document management */

/**
 * Returns YES, if document is active.
 */
- (BOOL) isActive;

/**
 * Return YES, if anObject is visible at launch time.
 */
- (BOOL) objectIsVisibleAtLaunch: (id)anObject;


/**
 * Return YES, if anObject is deferred.
 */
- (BOOL) objectIsDeferred: (id)anObject;

/**
 * Retrieve all objects which have parent as thier parent.  If flag is YES,
 * then retrieve the entire graph of objects starting with the parent.
 */
- (NSArray *) retrieveObjectsForParent: (id)parent recursively: (BOOL)flag;

/**
 * Marks this document as the currently active document.  The active document is
 * the one being edited by the user.
 */
- (void) setDocumentActive: (BOOL)flag;

/**
 * Add object to the visible at launch list.
 */
- (void) setObject: (id)anObject isVisibleAtLaunch: (BOOL)flag;

/**
 * Add object to the defferred list.
 */
- (void) setObject: (id)anObject isDeferred: (BOOL)flag;

/**
 * The document window.
 */
- (NSWindow*) window;

/**
 * Returns YES, if obj is a top level object.
 */
- (BOOL) isTopLevelObject: (id)obj;

/**
 * Forces the closing of all editors in the document.
 */
- (void) closeAllEditors;

/**
 * Create resource manager instances for all registered classes.
 */
- (void) createResourceManagers;

/**
 * The list of all resource managers.
 */
- (NSArray *) resourceManagers;

/**
 * Get the resource manager which handles the content on pboard.
 */
- (IBResourceManager *) resourceManagerForPasteboard: (NSPasteboard *)pboard;

/**
 * Switch to the top level editor responsible for a given type.  This allows the
 * document in the view to switch to the view which is appropriate for the resource
 * being dragged in.
 */
- (void) changeToTopLevelEditorAcceptingTypes: (NSArray *)types 
                                  andFileType: (NSString *)fileType;

/**
 * Switches to the view using the specified tag.  
 * They are 0=objects, 1=images, 2=sounds, 3=classes, 4=file prefs.
 */
- (void) changeToViewWithTag: (int)tag;

/**
 * Returns all pasteboard types registered for with the IBResourceManager.
 */
- (NSArray *) allManagedPboardTypes;

/* Language translation */
- (void) translate: (id)sender;
- (void) exportStrings: (id)sender;

/* Managing classes */
- (GormClassManager*) classManager;
- (id) createSubclass: (id)sender;
- (id) instantiateClass: (id)sender;
- (id) createClassFiles: (id)sender;
- (id) addAttributeToClass: (id)sender;
- (id) remove: (id)sender;
- (id) createClassFiles: (id)sender;
- (id) instantiateClass: (id)sender;
- (void) selectClass: (NSString *)className;
- (void) selectClass: (NSString *)className editClass: (BOOL)flag;
- (BOOL) classIsSelected;
- (void) removeAllInstancesOfClass: (NSString *)classNamed;

/* Sound & Image support */

/**
 * Open a sound and load it into the document.
 */
- (id) openSound: (id)sender;

/**
 * Open an image and copy it into the document.
 */
- (id) openImage: (id)sender;

/* Connections */

/**
 * Build our reverse mapping information and other initialisation
 */
- (void) rebuildObjToNameMapping;

/**
 * Removes all connections given action or outlet with the specified label 
 * (paramter name) class name (parameter className). 
 */
- (BOOL) removeConnectionsWithLabel: (NSString *)name
                      forClassNamed: (NSString *)className
                           isAction: (BOOL)action;
/**
 * Remove all connections to any and all instances of className.
 */
- (BOOL) removeConnectionsForClassNamed: (NSString *)name;

/**
 * Rename connections connected to an instance of on class to another.
 */
- (BOOL) renameConnectionsForClassNamed: (NSString *)name 
                                 toName: (NSString *)newName;

/* class loading */

/**
 * Load a class into the document.
 */
- (id) loadClass: (id)sender;

/*** services/windows menus... ***/

/**
 * Set the services menu.
 */
- (void) setServicesMenu: (NSMenu *)menu;

/**
 * Returns the services menu for the document.
 */
- (NSMenu *) servicesMenu;

/**
 * Sets the windows menu.
 */
- (void) setWindowsMenu: (NSMenu *)menu;

/**
 * Returns the menu which will be the windows menu for the document.
 */
- (NSMenu *) windowsMenu;

/*** first responder/font manager ***/

/**
 * Returns stand-in object for fontManager.
 */
- (id) fontManager;

/**
 * Returns stand-in object for firstResponder
 */
- (id) firstResponder;

/* Layout */

/**
 * Arrages selected objects based on the either in front of or in
 * back of the view stack.
 */ 
- (void) arrangeSelectedObjects: (id)sender;

/**
 * Aligns selected objects on a given axis.
 */
- (void) alignSelectedObjects: (id)sender;

/** 
 * WindowAndRect:forObject: is called by Gorm to determine where it should
 * draw selection markup
 */
- (NSWindow*) windowAndRect: (NSRect*)r forObject: (id)object;

/**
 * Save the SCM directory.
 */
- (void) setSCMWrapper: (NSFileWrapper *) wrapper;

/**
 * Save the SCM directory.
 */
- (NSFileWrapper *) scmWrapper;

/**
 * Images
 */
- (NSArray *) images;

/**
 * Sounds
 */
- (NSArray *) sounds;

/**
 * Images
 */
- (void) setImages: (NSArray *) imgs;

/**
 * Sounds
 */
- (void) setSounds: (NSArray *) snds;

/**
 * File's Owner
 */
- (GormFilesOwner *) filesOwner;

/**
 * File preferences.
 */
- (GormFilePrefsManager *) filePrefsManager;

/**
 * Windows visible at launch...
 */ 
- (NSSet *) visibleWindows;

/**
 * Windows deferred.
 */ 
- (NSSet *) deferredWindows;

- (void) setDocumentOpen: (BOOL) flag;

- (BOOL) isDocumentOpen;

- (void) setInfoData: (NSData *)data;

- (NSData *) infoData;

- (void) setOlderArchive: (BOOL)flag;

- (BOOL) isOlderArchive;
@end

@interface GormDocument (MenuValidation)
/**
 * Returns YES if the document is editing instance/objects.
 */
- (BOOL) isEditingObjects;

/**
 * Returns YES if the document is editing images.
 */
- (BOOL) isEditingImages;

/**
 * Returns YES if the document is editing sounds.
 */
- (BOOL) isEditingSounds;

/**
 * Returns YES if the document is editing classes.
 */
- (BOOL) isEditingClasses;
@end

#endif
