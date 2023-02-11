//
//  ViewOrganismDialog.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 10/9/22.
//
// Directions:
//
//		d7		d0		d1
// 		NW		N		NE
// d6	W		.		E	d2
//		SW		S		SE
//		d5		d4		d3
//
// d0 north				(0,1)
// d1 north east
// d2 east				(1,0)
// d3 south east
// d4 south				(0,-1)
// d5 south west
// d6 west				(-1,0)
// d7 north west
//
// widget tags:
//	1000	- data stack
//	2000	- call stack
//	3000	- cpu tab
//	4000	- vision tab
//	5000	- sound tab
//
//
import Cocoa
import Foundation
import SwiftUI

class ViewOrganismDialog: NSWindowController,
						NSTextViewDelegate,
						NSWindowDelegate,
						NSTableViewDelegate,
						NSTableViewDataSource,
						NSTextFieldDelegate {

	//////////////////////////////////////////////////////////////////////
	//
	// START UP / SHUT DOWN
	//
	// Machinery used by swift ui to initialize/deinit the class and start up
	//
	//////////////////////////////////////////////////////////////////////
	
	override func windowDidLoad() {
		super.windowDidLoad()

		// this needed to prevent text being black when in dark mode.
		disassemblyTv.usesAdaptiveColorMappingForDarkAppearance = true

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		populate_dialog()
		clear_error()
		avatar!.doit_cell(m.u!, m.c!, cell_clicked)
	}

	override var windowNibName: NSNib.Name? {
		return NSNib.Name("ViewOrganismDialog")
	}
	
	func windowWillClose(_ notification: Notification) {
		print("window will close")
		NSApplication.shared.stopModal()
		redraw_evolve5_document()
	}

	func doit(_ sender: Any?, _ u: UnsafeMutablePointer<UNIVERSE>, _ ec: EvolveCanvas?) {
		m = Model(u)
		m.ec = ec
		showWindow(sender)
		NSApplication.shared.runModal(for: self.window!)
	}

	//////////////////////////////////////////////////////////////////////
	//        BEGIN DELEGATE / DATA SOURCE STUFF                        //
	//////////////////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////////////////
	//
	// TEXT VIEW DELEGATE
	//
	//////////////////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////////////////
	//
	// TABLE VIEW DELEGATE
	//
	//////////////////////////////////////////////////////////////////////
	//
	// NSTableViewDelegate
	// tag 100 = data stack
	// tag 200 = call stack
	//
	func numberOfRows(in tableView: NSTableView) -> Int {
		if m.kfm == nil {
			return 0
		}

		if tableView.tag == 100 {
			return Int(m.kfm!.pointee.dsp)
		} else if tableView.tag == 200 {
			return Int(m.kfm!.pointee.csp)
		}
		assert(false)
		return 0
	}

	func tableView(_ tableView: NSTableView,
			 objectValueFor tableColumn: NSTableColumn?,
				   row: Int) -> Any? {
		if tableView.tag == 100 {
			return populate_data_stack_row(tableView, tableColumn, row)
		} else if tableView.tag == 200 {
			return populate_call_stack_row(tableView, tableColumn, row)
		}
		assert(false)
		return nil
	}

	func tableView(_ tableView: NSTableView,
			 setObjectValue object: Any?,
						for tableColumn: NSTableColumn?,
				   row: Int) {

		if tableView.tag == 100 {
			// read_data_stack_row(tableView, object, tableColumn, row)
		} else if tableView.tag == 200 {
			// read_call_stack_row(tableView, object, tableColumn, row)
		}
	}

	//////////////////////////////////////////////////////////////////////
	//
	// TABLE VIEW DATA SOURCE
	//
	//////////////////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////////////////
	//
	// TEXT FIELD DELEGATE
	//
	//////////////////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////////////////
	//          END DELEGATE / DATA SOURCE STUFF                        //
	//////////////////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////////////////
	//
	// VIEW
	//	populate routines - take values from the model and populate the GUI
	//	read routines - take values from the GUI and populate the model
	//	validate routines - validate values from the GUI
	//
	//////////////////////////////////////////////////////////////////////


	//////////////////////////////////////////////////////////////////////
	//
	// Populate routines
	//
	
	func populate_dialog() {
		populate_organism_tab()
		populate_cpu_tab()
		populate_vision_tab()
		populate_sound_tab()
		populate_odor_tab()
		populate_editability()
	}

	func populate_editability()
	{
		if m.editMode {
			butStep.isEnabled = false
			butStepOver.isEnabled = false
			butRun.isEnabled = false
			butBreakPoint.isEnabled = false
			butClear.isEnabled = false
			buttLoad.isEnabled = true
			butCompile.isEnabled = true
		} else {
			butStep.isEnabled = true
			butStepOver.isEnabled = true
			butRun.isEnabled = true
			butBreakPoint.isEnabled = true
			butClear.isEnabled = true
			buttLoad.isEnabled = false
			butCompile.isEnabled = false
		}
	}

	//
	// If cell based energy model applies show
	//		"(123 / 1,2345)"		cell energy, organism energy
	// if the old energy model applies show
	//		"(123 / 1,2345)"		organism energy/ncells, organism energy/ncells 
	//
	func populate_energy() {
		var str1: String
		var str2: String
		var oe: Int
		var ce: Int
		var nc: Int

		oe = Int( m.o!.pointee.energy )
		nc = Int( m.o!.pointee.ncells )

		ce = oe / nc

		str1 = format_comma( "\(ce)" )
		str2 = format_comma( "\(oe)" )
		energyTxt.stringValue = str1 + " / " + str2
	}

	func populate_organism_tab()
	{
		var o: UnsafeMutablePointer<ORGANISM>
		var str: String

		o = m.o!
		var oid: Int64 = o.pointee.id
		var energy: Int32 = o.pointee.energy
		
		str = format_comma("\(oid)")
		oidTxt.stringValue = str
		
		str = format_comma("\(energy)")
		energyTxt.stringValue = str

		populate_long_long(oidTxt, o.pointee.id)
		populate_long_long(pid1Txt, o.pointee.parent1)
		populate_long_long(pid2Txt, o.pointee.parent2)
		populate_int32(genTxt, o.pointee.generation)
		populate_energy()
		populate_int32(ageTxt, o.pointee.age)
		populate_int16(g0Txt, m.u!.pointee.G0)

		var val = Universe_Get_Strain_Global(m.u, o.pointee.strain)
		populate_int16(s0Txt, val)

		populate_disassembly()
		insert_breakpoint_indicator()
		populate_protected_code_blocks()
		populate_location()
	}

	func populate_code(_ c: NSTextView, _ str: String) {
		let font2 = NSFont.userFixedPitchFont(ofSize: 12)
				
		let attributes = [NSAttributedString.Key.font: font2]
		let attributedQuote = NSAttributedString(string: str, attributes: attributes as [NSAttributedString.Key : Any])
		c.textStorage!.setAttributedString(attributedQuote)
	}

	// mark all the protected code blocks with a diffent label color
	func populate_protected_code_blocks() {
		var protected = Int(m.kfp!.pointee.nprotected)

		for i in 0 ..< Int(m.kfd!.pointee.pos_len) {
			var cb = Int( m.kfd!.pointee.pos[i].cb )
			var pc = Int( m.kfd!.pointee.pos[i].pc )
			var s = Int( m.kfd!.pointee.pos[i].start_pos )
			var e = Int( m.kfd!.pointee.pos[i].end_pos )

            if pc == -1 {
				if cb < protected {
					var r = NSRange(location: s, length: e-s+1)
					disassemblyTv.setTextColor(NSColor.blue, range: r)
				} else {
					var r = NSRange(location: s, length: e-s+1)
					disassemblyTv.setTextColor(nil, range: r)
				}
            }
		}
	}

	func populate_location() {
		let r = m.get_location_range()
		if r != nil {
			if m.currentLocRange != nil {
				disassemblyTv.setTextColor(nil, range: m.currentLocRange!)
				m.currentLocRange = nil
				disassemblyTv.setSelectedRange( NSRange() )
			}

			disassemblyTv.setSelectedRange(r!)
			disassemblyTv.scrollRangeToVisible(r!)
			disassemblyTv.showFindIndicator(for: r!)
			disassemblyTv.setTextColor(NSColor.red, range: r!)
			disassemblyTv.setSelectedRange( NSRange() )
			m.currentLocRange = r!

		} else {
			if m.currentLocRange != nil {
				disassemblyTv.setTextColor(nil, range: m.currentLocRange!)
				m.currentLocRange = nil
				disassemblyTv.setSelectedRange( NSRange() )
			}
		}
	}

	func populate_disassembly() {
		if m.kfd != nil {
			var program = String(cString: m.kfd!.pointee.program_text)
			populate_code(disassemblyTv, program)
		} else {
			populate_code(disassemblyTv, "")
		}
		disassemblyTv.needsDisplay = true
	}

	func populate_int16(_ txt: NSTextField!, _ val: Int16)
	{
		txt.stringValue = format_comma("\(val)")
	}

	func populate_long_long(_ txt: NSTextField!, _ val: Int64)
	{
		txt.stringValue = format_comma("\(val)")
	}

	func populate_int32(_ txt: NSTextField!, _ val: Int32)
	{
		txt.stringValue = format_comma("\(val)")
	}

	func populate_dist_value(_ txt: NSTextField!, _ dir: Int)
	{
		var csdi: CELL_SENSE_DATA_ITEM
		var val: Int32

		csdi = CellSensoryData_ith_item(&m.csd, Int32(dir))

		val = csdi.dist
		txt.stringValue = format_comma("\(val)")
	}

	func populate_sense_value(_ txt: NSTextField!, _ mode: CB, _ dir: Int)
	{
		var csdi: CELL_SENSE_DATA_ITEM
		var val: Int32

		csdi = CellSensoryData_ith_item(&m.csd, Int32(dir))

		if mode == CB.LOOK {
			val = csdi.what
		} else if mode == CB.TEMPERATURE {
			val = csdi.energy
		} else if mode == CB.SIZE {
			val = csdi.size
		} else if mode == CB.MOOD {
			val = csdi.mood
		} else if mode == CB.MESSAGE {
			val = csdi.message
		} else  {
			val = 0
			assert(false)
		}

		txt.stringValue = format_comma("\(val)")
	}

	//
	// Make button look like the cell data in direction dir
	// #define VISION_TYPE_NONE	0
	// #define VISION_TYPE_CELL	1
	// #define VISION_TYPE_SPORE	2
	// #define VISION_TYPE_ORGANIC	4
	// #define VISION_TYPE_BARRIER	8
	// #define VISION_TYPE_SELF	16
	//
	func populate_gridthing(_ but: NSButton!, _ what: Int32, _ strain: Int32)
	{
		if (what & 1) != 0 {
			// set color to strain
			but.bezelColor = strainColor[Int(strain)]
		} else if (what & 2) != 0 {
			// spore color
			but.bezelColor = NSColor.init(calibratedRed: 0.0, green: 0.749, blue: 1.0, alpha: 1.0)
		} else if (what & 4) != 0 {
			// organic color
			but.bezelColor = NSColor.white
		} else if (what & 8) != 0 {
			// barrier color
			but.bezelColor = NSColor.black
		}
	}

	func populate_gridthing_dir(_ but: NSButton!, _ dir: Int)
	{
		var csdi: CELL_SENSE_DATA_ITEM

		csdi = CellSensoryData_ith_item(&m.csd, Int32(dir))
		populate_gridthing(but, csdi.what, csdi.strain)
	}

	func populate_odor(_ txt: NSTextField!, _ dir: Int)
	{
		var csdi: CELL_SENSE_DATA_ITEM
		var val: Int32

		csdi = CellSensoryData_ith_item(&m.csd, Int32(dir))
		val = csdi.odor
		txt.stringValue = format_comma("\(val)")
	}

	func populate_cpu_tab()
	{
		populate_int16(cbTxt, m.kfm!.pointee.loc.cb)
		populate_int16(pcTxt, m.kfm!.pointee.loc.pc)

		populate_int16(r0Txt, m.kfm!.pointee.R.0)
		populate_int16(r1Txt, m.kfm!.pointee.R.1)
		populate_int16(r2Txt, m.kfm!.pointee.R.2)
		populate_int16(r3Txt, m.kfm!.pointee.R.3)
		populate_int16(r4Txt, m.kfm!.pointee.R.4)
		populate_int16(r5Txt, m.kfm!.pointee.R.5)
		populate_int16(r6Txt, m.kfm!.pointee.R.6)
		populate_int16(r7Txt, m.kfm!.pointee.R.7)
		populate_int16(r8Txt, m.kfm!.pointee.R.8)
		populate_int16(r9Txt, m.kfm!.pointee.R.9)

		populate_int16(moodTxt, m.c!.pointee.mood)
		populate_int16(messageTxt, m.c!.pointee.message)

		var x: Int
		var y: Int
		var locStr: String

		x = Int(m.c!.pointee.x)
		y = Int(m.c!.pointee.y)
		locStr = "(\(x), \(y))"
		locTxt.stringValue = locStr

		var nc: Int32 = m.o!.pointee.ncells
		var i: Int

		i = m.cell_number + 1
		cellnumTxt.stringValue = format_comma("\(i)") + " of " + format_comma("\(nc)")

		populate_data_stack()
		populate_call_stack()
	}

	func populate_vision_tab()
	{
		populate_dist_value(vd0d, 0)
		populate_sense_value(vd0t, m.vmode, 0)
		populate_gridthing_dir(vd0b, 0)

		populate_dist_value(vd1d, 1)
		populate_sense_value(vd1t, m.vmode, 1)
		populate_gridthing_dir(vd1b, 1)

		populate_dist_value(vd2d, 2)
		populate_sense_value(vd2t, m.vmode, 2)
		populate_gridthing_dir(vd2b, 2)

		populate_dist_value(vd3d, 3)
		populate_sense_value(vd3t, m.vmode, 3)
		populate_gridthing_dir(vd3b, 3)

		populate_dist_value(vd4d, 4)
		populate_sense_value(vd4t, m.vmode, 4)
		populate_gridthing_dir(vd4b, 4)

		populate_dist_value(vd5d, 5)
		populate_sense_value(vd5t, m.vmode, 5)
		populate_gridthing_dir(vd5b, 5)

		populate_dist_value(vd6d, 6)
		populate_sense_value(vd6t, m.vmode, 6)
		populate_gridthing_dir(vd6b, 6)

		populate_dist_value(vd7d, 7)
		populate_sense_value(vd7t, m.vmode, 7)
		populate_gridthing_dir(vd7b, 7)

		populate_gridthing(v00b, 1, m.o!.pointee.strain)

		switch(m.vmode) {
		case CB.LOOK:
			vkey1.isHidden = false
			vkey2.isHidden = false
			vcombo.stringValue = "LOOK"

		case CB.SIZE:
			vkey1.isHidden = true
			vkey2.isHidden = true
			vcombo.stringValue = "SIZE"

		case CB.TEMPERATURE:
			vkey1.isHidden = true
			vkey2.isHidden = true
			vcombo.stringValue = "TEMPERATURE"

		default:
			assert(false)
		}
	}

	func populate_sound_tab()
	{
		populate_dist_value(sd0d, 0)
		populate_sense_value(sd0t, m.smode, 0)
		populate_gridthing_dir(sd0b, 0)

		populate_dist_value(sd1d, 1)
		populate_sense_value(sd1t, m.smode, 1)
		populate_gridthing_dir(sd1b, 1)

		populate_dist_value(sd2d, 2)
		populate_sense_value(sd2t, m.smode, 2)
		populate_gridthing_dir(sd2b, 2)

		populate_dist_value(sd3d, 3)
		populate_sense_value(sd3t, m.smode, 3)
		populate_gridthing_dir(sd3b, 3)

		populate_dist_value(sd4d, 4)
		populate_sense_value(sd4t, m.smode, 4)
		populate_gridthing_dir(sd4b, 4)

		populate_dist_value(sd5d, 5)
		populate_sense_value(sd5t, m.smode, 5)
		populate_gridthing_dir(sd5b, 5)

		populate_dist_value(sd6d, 6)
		populate_sense_value(sd6t, m.smode, 6)
		populate_gridthing_dir(sd6b, 6)

		populate_dist_value(sd7d, 7)
		populate_sense_value(sd7t, m.smode, 7)
		populate_gridthing_dir(sd7b, 7)

		populate_gridthing(s00b, 1, m.o!.pointee.strain)

		switch(m.smode) {
		case CB.MOOD:
			scombo.stringValue = "MOOD"

		case CB.MESSAGE:
			scombo.stringValue = "MESSAGE"

		default:
			assert(false)
		}
	}

	func populate_odor_tab()
	{
		var val: Int32

		populate_odor(od0t, 0)
		populate_odor(od1t, 1)
		populate_odor(od2t, 2)
		populate_odor(od3t, 3)
		populate_odor(od4t, 4)
		populate_odor(od5t, 5)
		populate_odor(od6t, 6)
		populate_odor(od7t, 7)

		val = m.csd.odor
		o00t.stringValue = format_comma("\(val)")
	}

	func populate_data_stack_row(_ tableView: NSTableView,
						_ tableColumn: NSTableColumn?,
						_ row: Int ) -> Any? {
		var s: String
		var value = kforth_machine_ith_data_stack(m.kfm, Int32(row))
			
		var s1 = String(format: "%2d:", row)
		var s3 = format_comma("\(value)")
		var s2 = String(repeating: " ", count: 12 - s3.count)

		s = s1 + s2 + s3

		return s
	}

	func populate_call_stack_row(_ tableView: NSTableView,
						_ tableColumn: NSTableColumn?,
						_ row: Int ) -> Any? {
		var s: String		
		var loc: KFORTH_LOC
		loc = kforth_machine_ith_call_stack(m.kfm, Int32(row))

		s = String(format: "(cb = %d, pc = %d)",
				Int(loc.cb),
				Int(loc.pc) )

		return s
	}

	func populate_stack_selection(_ c:  NSTableView, _ i: Int16) {
		let x = IndexSet(integer: Int(i))
		c.selectRowIndexes(x, byExtendingSelection: false)
		c.scrollRowToVisible(Int(i))
	}

	func populate_data_stack() {
		dataStack.reloadData()
		populate_stack_selection(dataStack, m.kfm!.pointee.dsp-1)
	}

	func populate_call_stack() {
		callStack.reloadData()
		populate_stack_selection(callStack, m.kfm!.pointee.csp-1)
	}

	//////////////////////////////////////////////////////////////////////
	//
	// Read Routines
	//

	//////////////////////////////////////////////////////////////////////
	//
	// Validate Routine
	//

	////////////////////////////////////////////////////////////////////////
	//
	// CONTROLLER
	//
	////////////////////////////////////////////////////////////////////////
	func error(_ str: String) {
		errorTxt.stringValue = str
	}

	func clear_error() {
		errorTxt.stringValue = ""
	}

	func change_smode(_ x: String) {
		if x == "MOOD" {
			m.smode = CB.MOOD
		} else if x == "MESSAGE" {
			m.smode = CB.MESSAGE
		} else {
			assert(false)
		}
		populate_sound_tab()
	}

	func change_vmode(_ x: String) {
		if x == "LOOK" {
			m.vmode = CB.LOOK
		} else if x == "SIZE" {
			m.vmode = CB.SIZE
		} else if x == "TEMPERATURE" {
			m.vmode = CB.TEMPERATURE
		} else {
			assert(false)
		}
		populate_vision_tab()
	}

	// step universe and redraw
	func step() {
		var alive: Bool
		var selected_cell = UnsafeMutablePointer<CELL>(m.c!)

		alive = m.step()
		if !alive {
			clear_error()
			close()
			return
		}

		// the selected cell changed, tell the avatar
		if m.c != selected_cell {
			avatar.SetCell(m.c!)
			error("Cell died.")
		} else {
			clear_error()
		}

		populate_dialog()
		redraw_evolve5_document()
		redraw_avatar()
	}

	// step over function calls, universe and redraw
	func step_over() {
		var alive: Bool
		var selected_cell = UnsafeMutablePointer<CELL>(m.c!)

		alive = m.step_over()
		if !alive {
			clear_error()
			close()
			return
		}

		// the selected cell changed, tell the avatar
		if m.c != selected_cell {
			avatar.SetCell(m.c!)
			error("Cell died.")
		} else if m.breakPointReached {
			error("Break Point reached.")
		} else {
			clear_error()
		}

		populate_dialog()
		redraw_evolve5_document()
		redraw_avatar()
	}

	// run universe until step limit or breakpoint
	func run() {
		var alive: Bool
		var selected_cell = UnsafeMutablePointer<CELL>(m.c!)

		alive = m.run_sim()
		if !alive {
			close()
			return
		}

		// the selected cell changed, tell the avatar
		if m.c != selected_cell {
			avatar.SetCell(m.c!)
			error("Cell died.")
		} else if m.stepLimitReached {
			error("Step Limit reached.")
		} else if m.breakPointReached {
			error("Break Point reached.")
		} else {
			clear_error()
		}

		populate_dialog()
		redraw_evolve5_document()
		redraw_avatar()
	}

 	func cell_clicked(_ x: Int, _ y: Int) {
		var success: Bool
		print("Cell Clicked: \(x), \(y)")

		success = m.set_new_cell(x, y)
		if success {
			populate_dialog()
			avatar.SetCell(m.c!)
			clear_error()
		}
	}

	func redraw_evolve5_document()
	{
		m.ec.needsDisplay = true
		// KJS TODO: Tell the simulation window to update the status bar.
	}

	func redraw_avatar()
	{
		avatar.RefocusOnOrganism(m.o!)
		avatar.needsDisplay = true
	}

	//
	// insert the breakpoint character into the dsiassembly text wherever a breakpoint is defined
	// call this when you have recomputed the disassembly 
	//
	func insert_breakpoint_indicator() {
		var r, r2: NSRange?
		var bpChar: String
		var loc: KFORTH_LOC

		bpChar = "\u{270B}"
		for i in 0 ..< m.breakpoints.count {
			loc = m.breakpoints[i]

			r = m.find_location(loc.cb, loc.pc)
			r2 = NSRange(location: r!.location-1, length: 1)
			disassemblyTv.textStorage!.replaceCharacters(in: r2!, with: bpChar)
		}
	}

	func do_breakpoint(_ loc: KFORTH_LOC?) {
		var r2, r3: NSRange?
		var bpChar: String

		bpChar = "\u{270B}"
		for i in 0 ..< m.breakpoints.count {
			var loc1 = m.breakpoints[i]
			var loc2 = loc!
			if loc1.cb == loc2.cb && loc1.pc == loc2.pc {
				bpChar = " "
				m.breakpoints.remove(at: i)
				break
			}
		}

		r2 = m.find_location(loc!.cb, loc!.pc)
		if bpChar != " " {
			m.breakpoints.append(loc!)
		}

		r3 = NSRange(location: r2!.location-1, length: 1)
		disassemblyTv.textStorage!.replaceCharacters(in: r3!, with: bpChar)
		clear_error()
	}

	// create/remove breakpoint at selection point
	func breakpoint() {
		var loc: KFORTH_LOC?
		var r: NSRange?

		r = disassemblyTv.selectedRange()

		if r == NSRange() {
			do_breakpoint(m.kfm!.pointee.loc)
		} else {
			loc = m.find_location_rng(r!)
			if loc == nil {
				return
			}
			do_breakpoint(loc)
		}
	}

	// remove breakpoints
	func clear_breakpoints() {
		for i in 0 ..< m.breakpoints.count {
			var loc = m.breakpoints[i]
			var r = m.find_location(loc.cb, loc.pc)
			if r != nil {
				var r2 = NSRange(location: r!.location-1, length: 1)
				disassemblyTv.textStorage!.replaceCharacters(in: r2, with: " ")
			}
		}
		m.breakpoints.removeAll()
		clear_error()
	}

	func show_instructions() {
		var iw: KforthInstructionDialog
        iw = KforthInstructionDialog()

		var r = disassemblyTv.selectedRange()

		var s: String

		if r == NSRange() {
			var r = m.find_current_location()
			if r == nil {
				s = ""
			} else {
				s = m.find_instruction_rng(r!)
			}
		} else {
			s = m.find_instruction_rng(r)
		}

		iw.doit(self, s, 3)
	}

	func help() {
		ShowHelp("view_organism_dialog")
	}

	func change_edit_state() {
		m.editMode = !m.editMode

		if m.editMode {
			print("Edit Mode is on")
			populate_editability()
		} else {
			// KJS TODO
			// Check if a modification has been made.
			// Ask if the user would like to hit 'Compile' or lose changes.
			print("Edit Mode is off")
			populate_editability()
		}
	}

	func file_selector_for_save(_ dir: String) -> String? {
		sd.directoryURL = URL(fileURLWithPath: dir)
		sd.nameFieldStringValue = "seed.kf"
		sd.prompt = "Save"
		sd.message = "Save KFORTH .kf program"
		let ms = sd.runModal()
		if ms == NSApplication.ModalResponse.OK {
			print("File: \(sd.representedFilename)\n")
			print("File: \(sd.url)\n")
			if sd.url != nil {
				g_DataPath = sd.url!.deletingLastPathComponent().path
				return sd.url!.path
			}
		}
		return nil
	}

	//////////////////////////////////////////////////////////////////////
	//
	// IB ACTIONS
	//
	//////////////////////////////////////////////////////////////////////
	@IBAction func StepBut(_ sender: Any) {
		step()
	}

	@IBAction func StepOverBut(_ sender: Any) {
		step_over()
	}

	@IBAction func RunBut(_ sender: Any) {
		run()
	}

	@IBAction func BreakpointBut(_ sender: Any) {
		breakpoint()
	}

	@IBAction func InstructionsBut(_ sender: Any) {
		show_instructions()
	}

	@IBAction func HelpBut(_ sender: Any) {
		help()
	}

	@IBAction func GotoBut(_ sender: Any) {
		clear_breakpoints()
	}

	@IBAction func CompileBut(_ sender: Any) {
	}

	@IBAction func ReloadBut(_ sender: Any) {
	}

	@IBAction func SaveBut(_ sender: Any) {
		var str: String
		var filename: String?

		filename = file_selector_for_save(g_DataPath)
		if filename != nil {
			str = m.program_text_for_save()
			write_file( URL(fileURLWithPath: filename!), str )
		}
	}

	@IBAction func CloseBut(_ sender: Any) {
		close()
	}

	@IBAction func soundBut(_ sender: Any) {
		change_smode(scombo.stringValue)
	}
	
	@IBAction func visionBut(_ sender: Any) {
		change_vmode(vcombo.stringValue)

	}
	
	@IBAction func editBut(_ sender: Any) {
		change_edit_state()
	}
	
	//////////////////////////////////////////////////////////////////////
	//
	// IB OUTLETS
	//
	//////////////////////////////////////////////////////////////////////
	@IBOutlet var errorTxt: NSTextField!
	@IBOutlet var avatar: EvolveCanvas!
	@IBOutlet var butStep: NSButton!
	@IBOutlet var butStepOver: NSButton!
	@IBOutlet var butRun: NSButton!
	@IBOutlet var butBreakPoint: NSButton!
	@IBOutlet var butClear: NSButton!
	@IBOutlet var buttLoad: NSButton!
	@IBOutlet var butCompile: NSButton!

	//////////////////////////////////////////////////////////////////////
	//
	// organism ib outlets
	//
	@IBOutlet var oidTxt: NSTextField!
	@IBOutlet var pid1Txt: NSTextField!
	@IBOutlet var pid2Txt: NSTextField!
	@IBOutlet var genTxt: NSTextField!
	@IBOutlet var ageTxt: NSTextField!
	@IBOutlet var energyTxt: NSTextField!
	@IBOutlet var g0Txt: NSTextField!
	@IBOutlet var s0Txt: NSTextField!
	@IBOutlet var disassemblyTv: NSTextView!

	
	//////////////////////////////////////////////////////////////////////
	//
	// cpu ib outlets
	//
	@IBOutlet var cbTxt: NSTextField!
	@IBOutlet var pcTxt: NSTextField!
	@IBOutlet var r0Txt: NSTextField!
	@IBOutlet var r1Txt: NSTextField!
	@IBOutlet var r2Txt: NSTextField!
	@IBOutlet var r3Txt: NSTextField!
	@IBOutlet var r4Txt: NSTextField!
	@IBOutlet var r5Txt: NSTextField!
	@IBOutlet var r6Txt: NSTextField!
	@IBOutlet var r7Txt: NSTextField!
	@IBOutlet var r8Txt: NSTextField!
	@IBOutlet var r9Txt: NSTextField!

	@IBOutlet var moodTxt: NSTextField!
	@IBOutlet var messageTxt: NSTextField!
	@IBOutlet var cellnumTxt: NSTextField!
	@IBOutlet var locTxt: NSTextField!

	@IBOutlet var dataStack: NSTableView!
	@IBOutlet var callStack: NSTableView!
	
	//////////////////////////////////////////////////////////////////////
	//
	// vision ib outlets
	//
	@IBOutlet var v00b: NSButton!		// (0,0) button

	@IBOutlet var vd0t: NSTextField!
	@IBOutlet var vd0d: NSTextField!
	@IBOutlet var vd0b: NSButton!

	@IBOutlet var vd1t: NSTextField!
	@IBOutlet var vd1d: NSTextField!
	@IBOutlet var vd1b: NSButton!

	@IBOutlet var vd2t: NSTextField!
	@IBOutlet var vd2d: NSTextField!
	@IBOutlet var vd2b: NSButton!

	@IBOutlet var vd3t: NSTextField!
	@IBOutlet var vd3d: NSTextField!
	@IBOutlet var vd3b: NSButton!

	@IBOutlet var vd4t: NSTextField!
	@IBOutlet var vd4d: NSTextField!
	@IBOutlet var vd4b: NSButton!

	@IBOutlet var vd5t: NSTextField!
	@IBOutlet var vd5d: NSTextField!
	@IBOutlet var vd5b: NSButton!

	@IBOutlet var vd6t: NSTextField!
	@IBOutlet var vd6d: NSTextField!
	@IBOutlet var vd6b: NSButton!

	@IBOutlet var vd7t: NSTextField!
	@IBOutlet var vd7d: NSTextField!
	@IBOutlet var vd7b: NSButton!

	@IBOutlet var vkey1: NSTextField!
	@IBOutlet var vkey2: NSTextField!
	@IBOutlet var vcombo: NSComboBox!

	//////////////////////////////////////////////////////////////////////
	//
	// sound ib outlets
	//
	@IBOutlet var s00b: NSButton!			// (0,0) button

	@IBOutlet var sd0t: NSTextField!
	@IBOutlet var sd0d: NSTextField!
	@IBOutlet var sd0b: NSButton!

	@IBOutlet var sd1t: NSTextField!
	@IBOutlet var sd1d: NSTextField!
	@IBOutlet var sd1b: NSButton!

	@IBOutlet var sd2t: NSTextField!
	@IBOutlet var sd2d: NSTextField!
	@IBOutlet var sd2b: NSButton!

	@IBOutlet var sd3t: NSTextField!
	@IBOutlet var sd3d: NSTextField!
	@IBOutlet var sd3b: NSButton!

	@IBOutlet var sd4t: NSTextField!
	@IBOutlet var sd4d: NSTextField!
	@IBOutlet var sd4b: NSButton!

	@IBOutlet var sd5t: NSTextField!
	@IBOutlet var sd5d: NSTextField!
	@IBOutlet var sd5b: NSButton!

	@IBOutlet var sd6t: NSTextField!
	@IBOutlet var sd6d: NSTextField!
	@IBOutlet var sd6b: NSButton!

	@IBOutlet var sd7t: NSTextField!
	@IBOutlet var sd7d: NSTextField!
	@IBOutlet var sd7b: NSButton!

	@IBOutlet var skey: NSTextField!
	@IBOutlet var scombo: NSComboBox!
	
	//////////////////////////////////////////////////////////////////////
	//
	// odor ib outlets
	//
	@IBOutlet var o00t: NSTextField!		// (0,0) text field

	@IBOutlet var od0t: NSTextField!	
	@IBOutlet var od1t: NSTextField!
	@IBOutlet var od2t: NSTextField!
	@IBOutlet var od3t: NSTextField!
	@IBOutlet var od4t: NSTextField!
	@IBOutlet var od5t: NSTextField!
	@IBOutlet var od6t: NSTextField!
	@IBOutlet var od7t: NSTextField!

	//////////////////////////////////////////////////////////////////////
	//
	// MODEL
	//
	//////////////////////////////////////////////////////////////////////
	enum CB {
		case MOOD
		case MESSAGE
		case SIZE
		case LOOK
		case TEMPERATURE
	}

	struct Model {
		init() {
			self.u = nil
			c = nil
			o = nil
			kfm = nil
		}

		init(_ u: UnsafeMutablePointer<UNIVERSE>? ) {
			self.u = u
			o = u!.pointee.selected_organism
			assert(o != nil)
			c = o!.pointee.cells
			assert(c != nil)
			refresh()
		}
		
		// free's any memory held by this object
		// KJS Note: I never tested this....
		mutating func uninitialize() {
			if kfd != nil {
				kforth_disassembly_delete(kfd)
				kfd = nil
			}
		}

		mutating func rebuild_disassembly() -> Bool {
			if kfd != nil {
				kforth_disassembly_delete(kfd)
				kfd = nil
			}

	        kfd = kforth_disassembly_make(kfops, kfp, 45, 0)
			if kfd == nil {
				errorStr = "kforth_dissasembly_make failed"
				return false
			}
			return true
		}

		// assumes 'u', 'o' and 'c' are setup.
		// set the other things
		mutating func refresh() {
			var strain: Int32

			kfm = UnsafeMutablePointer<KFORTH_MACHINE>(&c!.pointee.kfm)
			kfp = UnsafeMutablePointer<KFORTH_PROGRAM>(&o!.pointee.program)

			strain = o!.pointee.strain
			kfops = Universe_get_ith_kfops(u, strain)
			kfmo = Universe_get_ith_kfmo(u, strain)
			strop = Universe_get_ith_strop(u, strain)

			Universe_CellSensoryData(u, c, &csd)
			rebuild_disassembly()
			rebuild_call_write_instructions()
		}

		func find_current_location() -> NSRange? {
			return find_location(kfm!.pointee.loc.cb, kfm!.pointee.loc.pc)
		}

		func find_location(_ cb: Int16, _ pc: Int16) -> NSRange? {
			for i in 0 ..< Int(kfd!.pointee.pos_len) {
				let cb1 = kfd!.pointee.pos[i].cb
				let pc1 = kfd!.pointee.pos[i].pc
				if cb1 == cb && pc1 == pc {
					let start_pos = Int( kfd!.pointee.pos[i].start_pos )
					let end_pos = Int( kfd!.pointee.pos[i].end_pos )
					return NSRange(location: start_pos, length: end_pos - start_pos + 1)
				}
			}
			return nil
		}

		func get_location_range() -> NSRange? {
			return find_location(kfm!.pointee.loc.cb, kfm!.pointee.loc.pc)
		}

		//
		// Sorry for so many levels of indirection before reaching this
		// point. it handles all the model updates incurred when stepping
		// forward
		//
		mutating func do_step(_ step_limit: Int, _ stepOver: Bool) -> Bool {
			var curr = UnsafeMutablePointer<CELL>(nil)
			var found, mycell, myorganism: Bool
			var count: Int
			var cb, pc, css: Int16
			var done: Bool

			if is_call_instruction && stepOver {
				css = kfm!.pointee.csp
				cb = kfm!.pointee.loc.cb
				pc = kfm!.pointee.loc.pc
			} else {
				css = -1
				cb = -1
				pc = -1
			}

			programModified = false
			stepLimitReached = false
			breakPointReached = false
			count = 0
			done = false
			for i in 0 ..< step_limit {

				// simulate universe until cell simulated 1 step
				while true {
					mycell = false
					myorganism = false

					if u!.pointee.current_cell != nil {
						curr = u!.pointee.current_cell
						if curr!.pointee.organism == c!.pointee.organism {
							myorganism = true
							if kfm_is_write_instruction(&curr!.pointee.kfm, kfp!) {
								programModified = true
							}
						}
					}

					if u!.pointee.current_cell == c {
						mycell = true

						if count > 0 && break_point_reached {
							breakPointReached = true
							done = true
							break
						}

						if is_write_instruction {
							programModified = true
						}

					}

					Universe_Simulate(u)

					if u!.pointee.selected_organism == nil {
						o = nil
						c = nil
						return false
					}

					// we simulated the cell being viewed, see if it exists
					if mycell {
						count += 1

						found = false
						curr = o!.pointee.cells
						while curr != nil {
							if curr == c {
								found = true
								break
							}
							curr = curr!.pointee.next
						}

						if !found {
							c = o!.pointee.cells
							done = true
							break
						}

						if kfm!.pointee.csp == css
								&& kfm!.pointee.loc.cb == cb
								&& kfm!.pointee.loc.pc == pc + 1 {
							done = true
							break
						}
						break // exit inner loop because cell got simulated
					}
				}

				if done {
					break
				}
			}

			Universe_CellSensoryData(u, c, &csd)

			if count == step_limit {
				stepLimitReached = true
			}

			if programModified {
				rebuild_disassembly()
			}

			//
			// callers might like to know:
			//
			//	- did step limit get reached?		stepLimitReached
			//	- break point reached				breakPointReached
			//	- program modifed					programModified
			//

			return true
		}

		mutating func step() -> Bool {
			var rc: Bool
			rc = do_step(1, false)
			return rc
		}

		mutating func step_over() -> Bool {
			var rc: Bool
			if is_call_instruction {
				rc = do_step(1000, true)
			} else {
				rc = do_step(1, false)
			}
			return rc
		}

		mutating func run_sim() -> Bool {
			var rc: Bool
			rc = do_step(1000, true)
			return rc
		}

		// return cell offset in linked list starting with 0
		public var cell_number: Int {
			var curr = UnsafeMutablePointer<CELL>(nil)
			var i: Int

			i = 0
			curr = o!.pointee.cells
			while curr != nil {
				if curr == c {
					return i
				}
				curr = curr!.pointee.next
				i += 1
			}
			assert(false)
			return -1
		}

		//
		// If (x,y) is one of my cells make it the selection
		// return true if the cell was selected
		//
		public mutating func set_new_cell(_ x: Int, _ y: Int) -> Bool {
			var curr = UnsafeMutablePointer<CELL>(nil)

			curr = o!.pointee.cells
			while curr != nil {
				if curr!.pointee.x == x
						&& curr!.pointee.y == y {
					c = curr
					refresh()
					return true
				}
				curr = curr!.pointee.next
			}

			return false
		}

		public var is_call_instruction: Bool {
			var opcode: Int16
			var cb, pc: Int16

			cb = kfm!.pointee.loc.cb
			pc = kfm!.pointee.loc.pc

			if cb < 0 {
				return false
			}

			if pc >= kfp!.pointee.block[Int(cb)]![Int(-1)] {
				return false
			}

			opcode = kfp!.pointee.block[Int(cb)]![Int(pc)]   // heh heh heh

			if callopcodes.contains(opcode) {
				return true
			}
			return false
		}

		public func kfm_is_write_instruction(
							_ kfm: UnsafeMutablePointer<KFORTH_MACHINE>,
							_ kfp: UnsafeMutablePointer<KFORTH_PROGRAM> ) -> Bool {
			var opcode: Int16
			var cb, pc: Int16

			cb = kfm.pointee.loc.cb
			pc = kfm.pointee.loc.pc

			if cb < 0 {
				return false
			}

			if pc >= kfp.pointee.block[Int(cb)]![Int(-1)] {
				return false
			}

			opcode = kfp.pointee.block[Int(cb)]![Int(pc)]

			if write_opcodes.contains(opcode) {
				return true
			}
			return false
		}

		public var is_write_instruction: Bool {
			kfm_is_write_instruction(kfm!, kfp!)
/*
			var opcode: Int16
			var cb, pc: Int16

			cb = kfm!.pointee.loc.cb
			pc = kfm!.pointee.loc.pc

			if cb < 0 {
				return false
			}

			if pc >= kfp!.pointee.block[Int(cb)]![Int(-1)] {
				return false
			}

			opcode = kfp!.pointee.block[Int(cb)]![Int(pc)]

			if write_opcodes.contains(opcode) {
				return true
			}
			return false
*/
		}

		public var break_point_reached: Bool {
			for i in 0 ..< breakpoints.count {
				var loc1 = breakpoints[i]
				var loc2 = kfm!.pointee.loc
				if loc1.pc == loc2.pc && loc1.cb == loc2.cb {
					return true
				}
			}
			return false
		}

		// build a list of opcodes that perform a function call
		// and need to be step'd over, or update program memory
		mutating func rebuild_call_write_instructions() {
			var opname: String
			var op = UnsafeMutablePointer<KFORTH_OPERATION>(nil)

			callopcodes.removeAll()
			write_opcodes.removeAll()

			for i in 0 ..< kfops!.pointee.count {
				op = kforth_ops_get(kfops!, Int32(i))
				opname = String(cString: op!.pointee.name)
				if str_is_call(opname) {
					callopcodes.append(Int16(i))
				} else if str_is_write(opname) {
					write_opcodes.append(Int16(i))
				}
			}
		}

		func find_instruction_rng(_ r: NSRange) -> String {
			var f: Int = r.location
			for i in 0 ..< Int(kfd!.pointee.pos_len) {
				let start_pos = kfd!.pointee.pos[i].start_pos
				let end_pos = kfd!.pointee.pos[i].end_pos
				var cb: Int = Int(kfd!.pointee.pos[i].cb)
				var pc: Int = Int(kfd!.pointee.pos[i].pc)
				if end_pos >= f && pc >= 0 {
					var cblen = kfp!.pointee.block[cb]![-1]
					if pc < cblen {
						var x = kfp!.pointee.block[cb]!
						var y = x + pc
						var op = Int32(y.pointee)
						if (op & 0x8000) != 0 {
							return "" // literal
						}
						var ko = UnsafeMutablePointer<KFORTH_OPERATION>(nil)
						ko = kforth_ops_get(kfops, op)
						return String(cString: ko!.pointee.name)
					} else {
						return "" // after last instruction in code block
					}
				}
			}
			return ""
		}

		func find_location_rng(_ r: NSRange) -> KFORTH_LOC? {
			var f: Int = r.location
			for i in 0 ..< Int(kfd!.pointee.pos_len) {
				let start_pos = kfd!.pointee.pos[i].start_pos
				let end_pos = kfd!.pointee.pos[i].end_pos
				var cb = Int16(kfd!.pointee.pos[i].cb)
				var pc = Int16(kfd!.pointee.pos[i].pc)
				if end_pos >= f && pc >= 0 {
					return KFORTH_LOC(pc: pc, cb: cb)
				}
			}
			return nil
		}

		func program_text_for_save() -> String {
			var str = UnsafeMutablePointer<Int8>(nil)
			var program, result: String
			var strain: Int32

			if kfd == nil {
				return ""
			}

			strain = o!.pointee.strain

			str = kforth_metadata_comment_make(strain, strop, kfmo, kfops, kfp)
			result = String(cString: str!)
			kforth_metadata_comment_delete(str);		// KJS TODO need to implement

			program = String(cString: kfd!.pointee.program_text)
			result += program

			return result
		}

		var breakpoints = Array<KFORTH_LOC>()
		var callopcodes = Array<Int16>()
		var write_opcodes = Array<Int16>()

		public var u = UnsafeMutablePointer<UNIVERSE>(nil)
		public var c = UnsafeMutablePointer<CELL>(nil)
		public var o = UnsafeMutablePointer<ORGANISM>(nil)
		public var kfm = UnsafeMutablePointer<KFORTH_MACHINE>(nil)
		public var kfp = UnsafeMutablePointer<KFORTH_PROGRAM>(nil)
		public var kfd = UnsafeMutablePointer<KFORTH_DISASSEMBLY>(nil)
		public var kfops = UnsafeMutablePointer<KFORTH_OPERATIONS>(nil)
		public var kfmo = UnsafeMutablePointer<KFORTH_MUTATE_OPTIONS>(nil)
		public var strop = UnsafeMutablePointer<STRAIN_OPTIONS>(nil)

		public var csd = CELL_SENSE_DATA()
		public var vmode = CB.LOOK
		public var smode = CB.MESSAGE
		public var currentLocRange: NSRange!
		public var errorStr: String = ""
		public var ec: EvolveCanvas!
		public var programModified: Bool = false
		public var stepLimitReached: Bool = false
		public var breakPointReached: Bool = false
		public var editMode: Bool = false
	}

	var m = Model()
	var sd = NSSavePanel()
}
