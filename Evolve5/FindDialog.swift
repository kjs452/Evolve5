//
//  FindDialog.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/23/22.
//

import Cocoa
import Foundation
import SwiftUI

class FindDialog: NSWindowController,
				  NSWindowDelegate,
				  NSTextFieldDelegate {
	
	override func windowDidLoad() {
		super.windowDidLoad()

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		print("window did load")
		
		search.recentSearches = g_FindExpressions
		
		populate_dialog()
	}
	
	func populate_dialog() {
		clear_error()
	}
	
	override func awakeFromNib() {
		print("awake from nib")
		
	}
	
	func error(_ str: String) {
		errorLabel.stringValue = str
	}

	func clear_error() {
		errorLabel.stringValue = ""
	}
	
	override var windowNibName: NSNib.Name? {
		return NSNib.Name("FindDialog")
	}
	
	func windowWillClose(_ notification: Notification) {
		print("window will Close")
		NSApplication.shared.stopModal()
	}
	
	func doit(_ sender: Any?, _ u: UnsafeMutablePointer<UNIVERSE>) {
		self.u = u
		showWindow(sender)
		NSApplication.shared.runModal(for: self.window!)
	}
		
	@IBAction func HelpBut(_ sender: Any) {
		ShowHelp("find_dialog")
	}
	
	@IBAction func InstructionsBut(_ sender: Any) {
		print("Instructions")
		clear_error()
		let kid = KforthInstructionDialog()
		kid.doit(sender, "ID", 5)
		if kid.insertInstruction != "" {
			search.stringValue = search.stringValue + " " + kid.insertInstruction
		}
	}
	
	func find() -> Bool {
		let expr = search.stringValue
		var ofc = UnsafeMutablePointer<ORGANISM_FINDER>(nil)
		ofc = OrganismFinder_make(expr, 1)
		if ofc!.pointee.error != 0 {
			let s = String(cString: OrganismFinder_get_error(ofc))
			error(s)
			return false
		}
		OrganismFinder_execute(ofc, u!)
		OrganismFinder_delete(ofc)
		
		return true
	}
	
	func controlTextDidChange(_ obj: Notification) {
		clear_error()
	}
	
	@IBAction func okBut(_ sender: Any) {
		success = find()
		if success {
			if !is_blank(search.stringValue) {
				g_FindExpressions.insert(search.stringValue, at: 0)
			}
		} else {
			return
		}
		print("Search \(search.recentSearches)")
		close()
	}
	
	@IBAction func cancelBut(_ sender: Any) {
		close()
	}
	
	@IBOutlet var edit: NSTextField!
	@IBOutlet var errorLabel: NSTextField!

	var u = UnsafeMutablePointer<UNIVERSE>(nil)
	
	public var success: Bool = false
	
	@IBOutlet var search: NSSearchField!

}
