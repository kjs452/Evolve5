//
//  AboutDialog.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/23/22.
//

import Cocoa
import Foundation
import SwiftUI

class AboutDialog: NSWindowController, NSWindowDelegate {
	
	override func windowDidLoad() {
		super.windowDidLoad()

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		verLbl.stringValue = "https://www.etcutmp.com/evolve5"
		verLbl.isSelectable = true

		var aboutStr: String
		aboutStr  = "Evolve5 is an Artificial Life simulator.\n\n"
		aboutStr += String(cString: Evolve_Version()) + "\n"
		aboutLbl.stringValue = aboutStr
	}
	
	override var windowNibName: NSNib.Name? {
		return NSNib.Name("AboutDialog")
	}
	
	func windowWillClose(_ notification: Notification) {
		print("window will Close")
		NSApplication.shared.stopModal()
	}
	
	func doit(_ sender: Any?) {
		showWindow(sender)
		NSApplication.shared.runModal(for: self.window!)
	}
	
	@IBAction func okBut(_ sender: Any) {
		close()
	}
	
	@IBAction func homeBut(_ sender: Any) {
		print("Home But")
		ShowUrl("www.etcutmp.com/evolve5")
	}
	
	@IBOutlet var verLbl: NSTextField!
	@IBOutlet var aboutLbl: NSTextField!
}

