//
//  NewUniverseDialog.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/26/22.
//
import Cocoa
import Foundation
import SwiftUI

class NewUniverseDialog: NSWindowController, NSWindowDelegate,
			NSTextFieldDelegate, NSComboBoxDataSource,
						 NSComboBoxDelegate {
	
	override func windowDidLoad() {
		super.windowDidLoad()

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		popTxt.controlView!.toolTip = "Population"
		populate_dialog()
	}
	
	override var windowNibName: NSNib.Name? {
		return NSNib.Name("NewUniverseDialog")
	}
	
	func windowWillClose(_ notification: Notification) {
		print("window will Close")
		NSApplication.shared.stopModal()
	}
	
	func doit(_ sender: Any?, _ ep: UnsafeMutablePointer<EVOLVE_PREFERENCES>) {
		self.ep = ep
		showWindow(sender)
		NSApplication.shared.runModal(for: self.window!)
	}
	
	@IBAction func okBut(_ sender: Any) {
		success = read_dialog()
		if success {
			close()
		}
	}
	
	@IBAction func cancelBut(_ sender: Any) {
		close()
	}
	
	@IBAction func helpBut(_ sender: Any) {
		print("Home But")
		ShowHelp("new_universe_dialog")
	}
	
	func C(_ x: Int, _ y: Int) -> NSView? {
		return grid.cell(atColumnIndex: x, rowIndex: y).contentView
	}
	
	func C2(_ x: Int, _ y: Int) -> NSControl? {
		return grid.cell(atColumnIndex: x, rowIndex: y).contentView as? NSControl
	}

	//
	// Scan the grid and look for 'v' in it. Return its coordinates.
	//	
	func FIND(_ v: NSView) -> (Int, Int)  {
		for x in 0..<grid.numberOfColumns {
			for y in 0..<grid.numberOfRows {
				if( v == C(x,y) ) {
					return (x,y)
				}
			}
		}
		return (-1,-1)
	}

	func error(_ str: String) {
		errorLabel.stringValue = str
	}

	func clear_error() {
		errorLabel.stringValue = ""
	}

	func validate_seed(_ control: NSControl) -> Bool {
		if is_blank(control.stringValue) {
			error("Nothing entered. Enter a number.")
			return false
		}
		
		if !is_comma_int(control.stringValue) {
			error("Invalid format. Digits and comma's only.")
			return false
		}
		clear_error()
		return true
	}

	func validate_size(_ control: NSControl) -> Bool {
		if is_blank(control.stringValue) {
			error("Nothing entered. Enter number between 100...3000")
			return false
		}
		
		if !is_comma_int(control.stringValue) {
			error("Invalid format. Digits and comma's only.")
			return false
		}

		let v = get_comma_int(control.stringValue)
		if( v < 100 )
		{
			error("\(v) too small. Must be between 100 and 3000.")
			return false
		}
		else if( v > 3000 )
		{
			error("\(v) too big. Must be between 100 and 3000.")
			return false
		}

		clear_error()
		return true
	}

	func validate_energy(_ control: NSControl) -> Bool {
		if is_blank(control.stringValue) {
			error("Nothing entered. Enter a number >= 1.")
			return false
		}
		
		if !is_comma_int(control.stringValue) {
			error("Invalid format. Digits and comma's only.")
			return false
		}

		let v = get_comma_int(control.stringValue)

		if v < 1 {
			error("\(v) too small. Energy must be 1 or more.")
			return false
		}
		clear_error()
		return true
	}

	func validate_population(_ control: NSControl) -> Bool {
		if is_blank(control.stringValue) {
			error("Nothing entered. Enter a number 1..100.")
			return false
		}
		
		if !is_comma_int(control.stringValue) {
			error("Invalid format. Digits and comma's only.")
			return false
		}

		let v = get_comma_int(control.stringValue)

		if v < 1 {
			error("\(v) too small. Population must be between 1..100.")
			return false
		} else if v > 100 {
			error("\(v) too big. Population must be between 1..100.")
			return false
		}

		clear_error()
		return true
	}
	
	func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		let x, y: Int
		
		(x, y) = FIND(control)
		
		if x == 3 {
			print("Energy \(y)\n")
			return validate_energy(control)
			
		} else if x == 4 {
			print("population \(y)\n")
			return validate_population(control)
			
		} else if x == 5 {
			print("seed file\(y)\n")
			return true
		}

		if control == seedControl {
			return validate_seed(control)
		}

		if control == widthControl {
			return validate_size(control)
		}

		if control == heightControl {
			return validate_size(control)
		}

		if control == terrainTxt {
			return true
		}

		return true
	}

	func textShouldEndEditing(_ textObject: NSText) -> Bool {
		print("Will; this be called?")
		return true
	}
	
	func controlTextDidChange(_ obj: Notification) {
		print("F!")
	}

	func controlTextDidEndEditing(_ obj: Notification) {
		print("C T D E EEDND")
		let c = obj.object as! NSControl
		var x, y: Int
		print("control Text Did End Editing \(c.stringValue)")
		(x, y) = FIND(c)

		if x == 3 {
			c.stringValue = format_comma(c.stringValue)
			modified = true
			return
		}

		if x == 4 {
			c.stringValue = format_comma(c.stringValue)
			modified = true
			return
		}

		if( c == seedControl || c == widthControl
						|| c == heightControl ) {
			c.stringValue = format_comma(c.stringValue)
			modified = true
		}
	}

	func populate_dialog() {
		var count: Int
		var ed: UnsafeMutablePointer<EVOLVE_DFLT>
		var sp2 = UnsafeMutablePointer<STRAIN_PROFILE>(nil)

		seedControl.intValue = generate_seed()
		widthControl.intValue = ep!.pointee.width
		heightControl.intValue = ep!.pointee.height

		//let tf = String(cString: &ep!.pointee.terrain_file.0) // KJS TESTING FIX
		let tf = Cstr0(&ep!.pointee.terrain_file.0, 1000)
		terrainTxt.stringValue = tf

		if ep!.pointee.want_barrier != 0 {
			ovalCheck.state = NSControl.StateValue.on
		} else {
			ovalCheck.state = NSControl.StateValue.off
		}

		count = 0
		for y in 0 ..< 8 {
			ed = EvolvePreferences_get_ith_dflt(ep, Int32(y))

			if ed.pointee.profile_idx == -1 {
				blank_out_row(y+1)
				sp2 = NewUniverse_Get_StrainProfile(&nuo, Int32(y))
				sp2!.pointee.strop.enabled = 0
				continue
			}

			let pi = Int(ed.pointee.profile_idx)

			enable_row(y+1)
			count += 1
		
			let w1 = C2(1, y+1)
			let w2 = C2(3, y+1)
			let w3 = C2(4, y+1)
			let w4 = C2(5, y+1)
			let cb = w1! as! NSComboBox

//			let name = String(cString: &ep!.pointee.strain_profiles[pi].name.0) // KJS new recipe for Cstr
			let name = Cstr0(&ep!.pointee.strain_profiles[pi].name.0, 1000)

			w1!.stringValue = name
			w2!.intValue = ed.pointee.energy
			w3!.intValue = ed.pointee.population
//			w4!.stringValue = String(cString: &ed.pointee.seed_file.0) // KJS new C str
			w4!.stringValue = Cstr0(&ed.pointee.seed_file.0, 1000)

			sp2 = NewUniverse_Get_StrainProfile(&nuo, Int32(y))
			StrainProfile_Set_Name(sp2, name)
			sp2!.pointee.strop = ep!.pointee.strain_profiles[pi].strop
			sp2!.pointee.kfmo  = ep!.pointee.strain_profiles[pi].kfmo
			sp2!.pointee.kfops = ep!.pointee.strain_profiles[pi].kfops
			sp2!.pointee.strop.enabled = 1

			comboBoxEventsOff = true
			cb.selectItem(at: pi+1)
			comboBoxEventsOff = false
		}
	}
	
	func RCV(_ c: NSControl) -> Int32 {
		return Int32( get_comma_int(c.stringValue) )
	}

	//
	// called when strain profile combo box changed, use preferences
	//
	func read_ith_profile_from_preferences(_ i: Int, _ sp: UnsafeMutablePointer<STRAIN_PROFILE>) {
		let c = C2(1, i+1)
		let cb = c as! NSComboBox
		let idx = cb.indexOfSelectedItem

		print("read_ith_profile_from_prefs idx is \(idx)\n")

		assert(idx >= 0)

		var sp2: UnsafeMutablePointer<STRAIN_PROFILE>
		sp2 = EvolvePreferences_Get_StrainProfile(ep, Int32(idx-1))

		sp.pointee.energy = sp2.pointee.energy
		sp.pointee.population = sp2.pointee.population

//		StrainProfile_Set_SeedFile(sp, String(cString: &ep!.pointee.strain_profiles[i].seed_file.0) ) // KJS testing
		StrainProfile_Set_SeedFile(sp, Cstr0(&ep!.pointee.strain_profiles[i].seed_file.0, 1000) )
		StrainProfile_Set_Name(sp, &sp2.pointee.name.0)
		StrainProfile_Set_Description(sp, StrainProfile_Get_Description(sp2))

		sp.pointee.strop = sp2.pointee.strop
		sp.pointee.kfmo = sp2.pointee.kfmo
		sp.pointee.kfops = sp2.pointee.kfops
		sp.pointee.strop.enabled = 1
	}

	func read_ith_profile(_ i: Int, _ sp: UnsafeMutablePointer<STRAIN_PROFILE>) {
		var c = C2(1, i+1)
		if c!.stringValue != "" {
			var sp2: UnsafeMutablePointer<STRAIN_PROFILE>
			sp2 = NewUniverse_Get_StrainProfile(&nuo, Int32(i))
			
			c = C2(3, i+1)
			sp.pointee.energy = RCV(c!)
			
			c = C2(4, i+1)
			sp.pointee.population = RCV(c!)
			
			c = C2(5, i+1)
			StrainProfile_Set_SeedFile(sp, c!.stringValue)
			StrainProfile_Set_Name(sp, &sp2.pointee.name.0)
			StrainProfile_Set_Description(sp, StrainProfile_Get_Description(sp2))

			sp.pointee.strop = sp2.pointee.strop
			sp.pointee.kfmo = sp2.pointee.kfmo
			sp.pointee.kfops = sp2.pointee.kfops
			sp.pointee.strop.enabled = 1

		} else {
			sp.pointee.strop.enabled = 0
		}
	}
	
	// read the form and validate any errors.
	// return 1 on successful validation. populate the
	// output variables.
	func read_dialog() -> Bool {
		var ed: UnsafeMutablePointer<EVOLVE_DFLT>
		var sp = UnsafeMutablePointer<STRAIN_PROFILE>(nil)
		var sp2 = UnsafeMutablePointer<STRAIN_PROFILE>(nil)

		nuo.width = RCV(widthControl)
		nuo.height = RCV(heightControl)
		nuo.seed = RCV(seedControl)
		nuo.want_barrier = Int32(ovalCheck.state.rawValue)
		NewUniverse_Set_TerrainFile(&nuo, terrainTxt.stringValue)
		nuo.so.mode = 0

		for i in 0...7 {
			var c = C2(1, i+1)
			if c!.stringValue != "" {
				let cb = c as! NSComboBox
				let idx = cb.indexOfSelectedItem

				sp2 = EvolvePreferences_Get_StrainProfile(ep, Int32(idx-1))
				sp = NewUniverse_Get_StrainProfile(&nuo, Int32(i))

				c = C2(3, i+1)
				sp!.pointee.energy = RCV(c!)
				
				c = C2(4, i+1)
				sp!.pointee.population = RCV(c!)
				
				c = C2(5, i+1)
				StrainProfile_Set_SeedFile(sp, c!.stringValue)
				StrainProfile_Set_Name(sp, &sp2!.pointee.name.0)
				StrainProfile_Set_Description(sp, StrainProfile_Get_Description(sp2))

				sp!.pointee.strop.enabled = 1

				ed = EvolvePreferences_get_ith_dflt(ep, Int32(i))

				ed.pointee.profile_idx = Int32(idx-1)
				ed.pointee.energy = sp!.pointee.energy
				ed.pointee.population = sp!.pointee.population

				EvolvePreferences_set_ith_dflt_seed_file(ep, Int32(i), &sp!.pointee.seed_file.0);

			} else {
				ed = EvolvePreferences_get_ith_dflt(ep, Int32(i))
				ed.pointee.profile_idx = -1
			}
		}
		
		let err = create_the_universe()
		if err != "" {
			error(err)
			return false
		}
				
		if( modified ) {
			ep!.pointee.width = nuo.width
			ep!.pointee.height = nuo.height
			ep!.pointee.want_barrier = nuo.want_barrier
			ep!.pointee.so.mode = nuo.so.mode
			EvolvePreferences_set_terrain_file(ep, &nuo.terrain_file.0)
			save_preferences(ep!)
		}
		
		return true
	}
	
	func create_the_universe() -> String {
		var errbuf = Array(repeating: CChar(0), count: 1000)
				
		u = CreateUniverse(&nuo, &errbuf)

		if u == nil {
			let str = String(cString: errbuf)
			return "Universe Create Failed: \(str)"
		} else {
			return ""
		}
	}
	
	func file_selector(_ dir: String) -> String? {
		fd.directoryURL = URL(fileURLWithPath: dir)
		fd.nameFieldStringValue = "seed.kf"
		fd.prompt = "Select"
		fd.message = "Choose KFORTH .kf Seed program"
		fd.runModal()
		print("File: \(fd.representedFilename)\n")
		print("File: \(fd.url)\n")
		if fd.url != nil {
			return fd.url!.path
		}
		return nil
	}

	@IBAction func browseBut(_ sender: Any) {
		print("Browse Pressed")
		let v = sender as! NSView
		let x, y: Int
		(x, y) = FIND(v)
		
		let c = C2(5, y)
							
		let url = URL(fileURLWithPath: c!.stringValue)
		let dirUrl = url.deletingLastPathComponent()
		
		let f = file_selector(dirUrl.path)
		if f != nil {
			c!.stringValue = f!
			modified = true
		}
	}

	func get_profile_name(_ slot: Int) -> String {
		let c = C2(1, slot+1)
		return c!.stringValue
	}

	//
	// Look for strain profile
	//
	func find_profile_idx(_ name: String) -> Int {
		for i in 0 ..< Int(ep!.pointee.nprofiles) {
			var sp = UnsafeMutablePointer<STRAIN_PROFILE>(nil)
//			var name2 = String(cString: &ep!.pointee.strain_profiles[i].name.0) // KJS testing new recipe
			let name2 = Cstr0(&ep!.pointee.strain_profiles[i].name.0, 100)

			if name2 == name {
				return i
			}
		}
		assert(false)
		return -1
	}

	@IBAction func customizeBut(_ sender: Any) {
		let v = sender as! NSView
		let x, y, i: Int
		(x, y) = FIND(v)
		i = y-1

		clear_error()

		let pname = get_profile_name(i)
		let pi = find_profile_idx(pname)

		let scd = StrainCustomizeDialog()
		scd.customizeMode = false
		scd.clear_strain_profiles()
		for i in 0 ..< Int(ep!.pointee.nprofiles) {
			scd.add_strain_profile( &ep!.pointee.strain_profiles[i] )
		}
		scd.sp_idx = pi
		scd.doit(sender)

		//
		// the rule is if they hit OKAY, then we go aheadd and update the dialog.
		// we don't need to know if they updated anything or not.
		//
		if !scd.success { return }

		if ep != nil {
			EvolvePreferences_Clear_StrainProfiles(ep)
		}
			
		for i in 0 ..< scd.nsptab.count {
			EvolvePreferences_Add_StrainProfile(ep, &scd.nsptab[i].pointee)
		}
		
		save_preferences(ep!)

		//
		// This iterates over the 8 slots
		// If it is enabled, it refereshes the data from the preferences
		// and re-populates the slot. If that profile has been deleted, then clear the corresponding slot.
		//
		for i in 0..<8 {
			var sp = STRAIN_PROFILE()
			read_ith_profile(i, &sp)
			if sp.strop.enabled != 0 {
				let pname = get_profile_name(i)
				let j = find_profile_idx(pname)
				if j < 0 {
					// this can happen if the user deleted the profile, so clear this slot.
					clear_slot(i+1)
				} else {
					populate_slot(i+1, j)

					var sp2 = UnsafeMutablePointer<STRAIN_PROFILE>(nil)
					sp2 = NewUniverse_Get_StrainProfile(&nuo, Int32(i))
					sp2!.pointee.strop = scd.nsptab[j].pointee.strop
					sp2!.pointee.kfmo = scd.nsptab[j].pointee.kfmo
					sp2!.pointee.kfops = scd.nsptab[j].pointee.kfops
				}
			}
		}
		modified = true
	}

	func numberOfItems(in comboBox: NSComboBox) -> Int {
		return Int(ep!.pointee.nprofiles) + 1
	}
	
	func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
		if index == 0 {
			return ""
		} else {
			//let s = String(cString: &self.ep!.pointee.strain_profiles[index-1].name.0) // KJS testing
			let s = Cstr0(&self.ep!.pointee.strain_profiles[index-1].name.0, 1000)
			return s
		}
	}
	
	func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
		if string == "" {
			return 0
		}
		
		let upperBound = Int(self.ep!.pointee.nprofiles)
		for i in 0..<upperBound {
//			let s = String(cString: &self.ep!.pointee.strain_profiles[i].name.0) // KJS testing new recipe
			let s = Cstr0(&self.ep!.pointee.strain_profiles[i].name.0, 100)
			if string == s {
				return i+1
			}
		}
		return NSNotFound
	}
	
	func blank_out_row(_ y: Int) {
		var c = C2(3, y)
		c!.stringValue = ""
		c!.isEnabled = false
		c = C2(4, y)
		c!.stringValue = ""
		c!.isEnabled = false
		c = C2(5, y)
		c!.stringValue = ""
		c!.isEnabled = false
		c = C2(6, y)
		c!.isEnabled = false
		c = C2(7, y)
		c!.isEnabled = false
		c = C2(0, y)
		c!.isEnabled = false
	}
	
	func enable_row(_ y: Int) {
		var c = C2(3, y)
		c!.isEnabled = true
		c = C2(4, y)
		c!.isEnabled = true
		c = C2(5, y)
		c!.isEnabled = true
		c = C2(6, y)
		c!.isEnabled = true
		c = C2(7, y)
		c!.isEnabled = true
		c = C2(0, y)
		c!.isEnabled = true
	}

	//
	// populate the new universe slot from the model
	// evolve preference strain profile given by 'idx'
	//
	func populate_slot(_ y: Int, _ idx: Int) {
		enable_row(y)
		var e = C2(3, y)
		e!.intValue = ep!.pointee.strain_profiles[idx].energy
		e = C2(4, y)
		e!.intValue = ep!.pointee.strain_profiles[idx].population
		e = C2(5, y)
//		e!.stringValue = String(cString: &ep!.pointee.strain_profiles[idx].seed_file.0)  // KJS new
		e!.stringValue = Cstr0(&ep!.pointee.strain_profiles[idx].seed_file.0, 1000)
	}

	func clear_slot(_ y: Int) {
		blank_out_row(y)
		var sp = UnsafeMutablePointer<STRAIN_PROFILE>(nil)
		sp = NewUniverse_Get_StrainProfile(&nuo, Int32(y-1))
		sp!.pointee.strop.enabled = 0
	}
	
	func comboBoxSelectionDidChange(_ notification: Notification) {
		let c = notification.object as! NSControl
		var x, y: Int
		
		if comboBoxEventsOff {
			return
		}
		
		(x, y) = FIND(c)
		print("Selection Did Change coordinated \(x), \(y)\n")
		
		let cb = c as! NSComboBox
		let i = cb.indexOfSelectedItem-1

		if i < 0 {
			blank_out_row(y)
			var sp = UnsafeMutablePointer<STRAIN_PROFILE>(nil)
			sp = NewUniverse_Get_StrainProfile(&nuo, Int32(y-1))
			sp!.pointee.strop.enabled = 0
		} else {
//			let ss = String(cString: &ep!.pointee.strain_profiles[i].name.0) // KJS testing
			let ss = Cstr0(&ep!.pointee.strain_profiles[i].name.0, 100)
			print("s is \(ss)\n")

			populate_slot(y, i)

			var sp = UnsafeMutablePointer<STRAIN_PROFILE>(nil)
			sp = NewUniverse_Get_StrainProfile(&nuo, Int32(y-1))

			read_ith_profile_from_preferences(y-1, sp!)
			modified = true
		}
	}
	
	// both checkboxes call this when clicked, update
	// the modified flag
	@IBAction func checkButs(_ sender: Any) {
		modified = true
	}
	
	@IBAction func browseTerrainBut(_ sender: Any) {
		let url = URL(fileURLWithPath: terrainTxt!.stringValue)
		let dirUrl = url.deletingLastPathComponent()
		let f = file_selector(dirUrl.path)
		if f != nil {
			terrainTxt!.stringValue = f!
			modified = true
		}
	}
	
	@IBOutlet var seedControl: NSTextField!
	@IBOutlet var widthControl: NSTextField!
	@IBOutlet var heightControl: NSTextField!
	@IBOutlet var ovalCheck: NSButton!
	@IBOutlet var terrainTxt: NSTextField!
	
	@IBOutlet var errorLabel: NSTextField!
	@IBOutlet var grid: NSGridView!
	@IBOutlet var popTxt: NSTextFieldCell!
	
	var fd = FileDialog()
	var ep = UnsafeMutablePointer<EVOLVE_PREFERENCES>(nil)
	var modified: Bool = false
	var comboBoxEventsOff: Bool = false
	
	public var success: Bool = false
	public var nuo = NEW_UNIVERSE_OPTIONS()
	public var u = UnsafeMutablePointer<UNIVERSE>(nil)
}
