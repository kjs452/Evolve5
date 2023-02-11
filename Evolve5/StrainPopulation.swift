//
//  StrainPopulation.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/23/22.
//

import Cocoa
import Foundation
import SwiftUI

class StrainPopulation: NSWindowController, NSWindowDelegate {
	
	override func windowDidLoad() {
		super.windowDidLoad()

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		var uinfo = UNIVERSE_INFORMATION()
		
		Universe_Information(u, &uinfo);
		populate(0, strain0, strain0r, b0, uinfo.strain_population.0, uinfo.radioactive_population.0)
		populate(1, strain1, strain1r, b1, uinfo.strain_population.1, uinfo.radioactive_population.1)
		populate(2, strain2, strain2r, b2, uinfo.strain_population.2, uinfo.radioactive_population.2)
		populate(3, strain3, strain3r, b3, uinfo.strain_population.3, uinfo.radioactive_population.3)
		populate(4, strain4, strain4r, b4, uinfo.strain_population.4, uinfo.radioactive_population.4)
		populate(5, strain5, strain5r, b5, uinfo.strain_population.5, uinfo.radioactive_population.5)
		populate(6, strain6, strain6r, b6, uinfo.strain_population.6, uinfo.radioactive_population.6)
		populate(7, strain7, strain7r, b7, uinfo.strain_population.7, uinfo.radioactive_population.7)
	}
	
	func populate(_ strain: Int32,
				_ pop: NSTextField,
				_ rad: NSTextField,
				_ but: NSButton,
				_ valp: Int32,
				_ valr: Int32 ) {

		var str: String

		var strop = UnsafeMutablePointer<STRAIN_OPTIONS>(nil)
		strop = Universe_get_ith_strop(u, strain)

		if strop!.pointee.enabled != 0 {
			but.isEnabled = true
			pop.isEnabled = true
			rad.isEnabled = true

			str = format_comma("\(valp)")
			pop.stringValue = str

			if valr != 0 {
				str = format_comma("\(valr)")
			} else {
				str = ""
			}
			rad.stringValue = str

		} else {
			but.isEnabled = false
			pop.isEnabled = false
			rad.isEnabled = false
			pop.stringValue = ""
			rad.stringValue = ""
		}
	}
	
	override var windowNibName: NSNib.Name? {
		return NSNib.Name("StrainPopulation")
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
	
	@IBAction func closeBut(_ sender: Any) {
		close()
	}
	
	@IBAction func helpBut(_ sender: Any) {
		ShowHelp("strain_population_dialog")
	}
	
	@IBOutlet var strain0: NSTextField!
	@IBOutlet var strain1: NSTextField!
	@IBOutlet var strain2: NSTextField!
	@IBOutlet var strain3: NSTextField!
	@IBOutlet var strain4: NSTextField!
	@IBOutlet var strain5: NSTextField!
	@IBOutlet var strain6: NSTextField!
	@IBOutlet var strain7: NSTextField!

	@IBOutlet var strain0r: NSTextField!
	@IBOutlet var strain1r: NSTextField!
	@IBOutlet var strain2r: NSTextField!
	@IBOutlet var strain3r: NSTextField!
	@IBOutlet var strain4r: NSTextField!
	@IBOutlet var strain5r: NSTextField!
	@IBOutlet var strain6r: NSTextField!
	@IBOutlet var strain7r: NSTextField!
	
	@IBOutlet var b0: NSButton!
	@IBOutlet var b1: NSButton!
	@IBOutlet var b2: NSButton!
	@IBOutlet var b3: NSButton!
	@IBOutlet var b4: NSButton!
	@IBOutlet var b5: NSButton!
	@IBOutlet var b6: NSButton!
	@IBOutlet var b7: NSButton!

	var u = UnsafeMutablePointer<UNIVERSE>(nil)
}


