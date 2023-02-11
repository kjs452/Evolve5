//
//  UniverseDialog.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/22/22.
//

import Cocoa
import Foundation
import SwiftUI

class UniverseDialog: NSWindowController, NSWindowDelegate {
	
	override func windowDidLoad() {
		super.windowDidLoad()

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		let s = u!.pointee.seed
		seed.stringValue = String(s)
		print("Window Did Load For Universe Dialog \(window == nil)")

		populate_dialog()
	}

	func populateL(_ c: NSTextField, _ val: Int64) {
		var str: String

		str = format_comma("\(val)")
		c.stringValue = str
	}

	func populate(_ c: NSTextField, _ val: Int32) {
		populateL(c, Int64(val))
	}

	func populateU(_ c: NSTextField, _ val: UInt32) {
		populateL(c, Int64(val))
	}

	func populate_dialog() {
		var total: Int32
		var uinfo = UNIVERSE_INFORMATION()
		
		Universe_Information(u, &uinfo);
		
		fileName.stringValue = the_file_name

		populateU(seed, u!.pointee.seed)
		populate(width, u!.pointee.width)
		populate(height, u!.pointee.height)
		populate(energy, uinfo.energy)
		populateL(age, u!.pointee.age)
		populateL(steps, u!.pointee.step)
		populate(organisms, u!.pointee.norganism)
		populate(nsexual, uinfo.num_sexual)
		populate(cells, uinfo.num_cells)
		populateL(births, u!.pointee.nborn)
		populateL(deaths, u!.pointee.ndie)
		populate(instructions, uinfo.num_instructions)
		populate(call_stack, uinfo.call_stack_nodes)
		populate(data_stack, uinfo.data_stack_nodes)

		total = uinfo.call_stack_nodes
				+ uinfo.data_stack_nodes ;

		populate(totStack, total)
		populate(organic, uinfo.num_organic)
		populate(organic_energy, uinfo.organic_energy)
		populate(spore, uinfo.num_spores)
		populate(spore_energy, uinfo.spore_energy)

		populate(grid_mem, uinfo.grid_memory)
		populate(cs_mem, uinfo.cstack_memory)
		populate(ds_mem, uinfo.dstack_memory)
		populate(prog_mem, uinfo.program_memory)
		populate(org_mem, uinfo.organism_memory)
		populate(spore_mem, uinfo.spore_memory)

		total = uinfo.grid_memory
				+ uinfo.cstack_memory
				+ uinfo.dstack_memory
				+ uinfo.program_memory
				+ uinfo.organism_memory
				+ uinfo.spore_memory ;

		populate(tot_mem, total)
	}
	
	override var windowNibName: NSNib.Name? {
		return NSNib.Name("UniverseDialog")
	}
	
	@IBAction func okBut(_ sender: Any) {
		close()
	}
	
	@IBAction func helpBut(_ sender: Any) {
		ShowHelp("universe_dialog")
	}
	
	func windowWillClose(_ notification: Notification) {
		NSApplication.shared.stopModal()
	}
	
	func doit(_ sender: Any?,
			_ u: UnsafeMutablePointer<UNIVERSE>,
			_ fn: String) {
		self.u = u
		self.the_file_name = fn
		showWindow(sender)
		NSApplication.shared.runModal(for: self.window!)
	}

	@IBOutlet var fileName: NSTextField!
	// universe information
	@IBOutlet var seed: NSTextField!
	@IBOutlet var width: NSTextField!
	@IBOutlet var height: NSTextField!
	@IBOutlet var energy: NSTextField!
	@IBOutlet var age: NSTextField!
	@IBOutlet var steps: NSTextField!
	@IBOutlet var organisms: NSTextField!
	@IBOutlet var nsexual: NSTextField!
	@IBOutlet var cells: NSTextField!
	@IBOutlet var births: NSTextField!
	@IBOutlet var deaths: NSTextField!
	@IBOutlet var instructions: NSTextField!
	@IBOutlet var call_stack: NSTextField!
	@IBOutlet var data_stack: NSTextField!
	@IBOutlet var totStack: NSTextField!
	@IBOutlet var organic: NSTextField!
	@IBOutlet var organic_energy: NSTextField!
	@IBOutlet var spore: NSTextField!
	@IBOutlet var spore_energy: NSTextField!

	// memory usage
	@IBOutlet var grid_mem: NSTextField!
	@IBOutlet var cs_mem: NSTextField!
	@IBOutlet var ds_mem: NSTextField!
	@IBOutlet var prog_mem: NSTextField!
	@IBOutlet var org_mem: NSTextField!
	@IBOutlet var spore_mem: NSTextField!
	@IBOutlet var tot_mem: NSTextField!
	
	var u = UnsafeMutablePointer<UNIVERSE>(nil)
	var the_file_name: String = ""
}
