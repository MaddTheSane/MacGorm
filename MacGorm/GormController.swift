//
//  GormController.swift
//  MacGorm
//
//  Created by C.W. Betts on 4/6/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Cocoa


import GormCore.GormGenericEditor
import GormCore.GormPrivate
import GormCore.GormFontViewController
import GormCore.GormSetNameController
import GormCore.GormFunctions
import GormCore.GormPluginManager
import GormCore.GormDocumentController
import GormCore.GormServer

import GNUstepBase.GSObjCRuntime
import GNUstepBase.GNUstep
import GNUstepBase.NSDebug_GNUstepBase
import GNUstepBase.NSString_GNUstepBase
import GormPrefs.GormPrefController


import GNUstepBase
import GNUstepGUI
import GormCore
import GormPrefs

#if false
extension IB {
	func selectedObject() -> Any! {
		return self.selectionOwner?.selection()?.last
	}
}
#endif

class GormSwiftController: NSObject, NSApplicationDelegate, IB, Gorm {
	private(set) var isTestingInterface: Bool = false
	private(set) var isConnecting: Bool = false
	private(set) var selectionOwner: IBSelectionOwners! = nil
	@IBOutlet var classMenu: NSMenu!

	
	func activeDocument() -> IBDocuments! {
		return nil
	}
	
	func selectedObject() -> Any! {
		return self.selectionOwner?.selection()?.last
	}
	
	func document(for object: Any!) -> IBDocuments! {
		return nil
	}
	
	func connectSource() -> Any! {
		return nil
	}
	
	func connectDestination() -> Any! {
		return nil
	}
	
	func displayConnectionBetween(source: Any!, destination: Any!) {
		
	}
	
	func stopConnecting() {
		
	}
	
	@IBAction func preferencesPanel(_ sender: Any!) {
		
	}
	
	@IBAction func copy(_ sender: Any!) {
		
	}
	
	@IBAction func cut(_ sender: Any!) {
		
	}
	
	@IBAction func paste(_ sender: Any!) {
		
	}
	
	@IBAction func delete(_ sender: Any!) {
		
	}
	
	@IBAction func selectAllItems(_ sender: Any!) {
		
	}
	
	@IBAction func setName(_ sender: Any!) {
		
	}
	
	@IBAction func inspector(_ sender: Any!) {
		
	}
	
	@IBAction func palettes(_ sender: Any!) {
		
	}
	
	@IBAction func loadPalette(_ sender: Any!) {
		
	}
	
	lazy var palettesManager: GormPalettesManager! = {
		return GormPalettesManager()
	}()
	
	lazy var inspectorsManager: GormInspectorsManager! = {
		
		return GormInspectorsManager()
	}()
	
	lazy var pluginManager: GormPluginManager = {
		return GormPluginManager()
	}()
	
	@IBAction func testInterface(_ sender: Any!) {
		
	}
	
	func endTesting(_ sender: Any!) -> Any! {
		return nil
	}
	
	@IBAction func loadSound(_ sender: Any!) {
		
	}
	
	@IBAction func loadImage(_ sender: Any!) {
		
	}
	
	@IBAction func groupSelectionInSplitView(_ sender: Any!) {
		
	}
	
	@IBAction func groupSelectionInBox(_ sender: Any!) {
		
	}
	
	@IBAction func groupSelectionInScrollView(_ sender: Any!) {
		
	}
	
	@IBAction func ungroup(_ sender: Any!) {
		
	}
	
	private lazy var privClassManager: GormClassManager = {
		return GormClassManager()
	}()
	
	func classManager() -> GormClassManager! {
		if let activeDoc = activeDocument() as? GormDocument {
			return activeDoc.classManager()
		}
		return privClassManager
	}
	
	func documentNameIsUnique(_ filename: String!) -> Bool {
		return true
	}

}
