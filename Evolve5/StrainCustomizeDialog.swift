//
//  StrainCustomizeDialog.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/29/22.
//

import Cocoa
import Foundation
import SwiftUI

class StrainCustomizeDialog: NSWindowController,
							NSWindowDelegate,
							NSTextFieldDelegate,
							NSTableViewDataSource,
							NSTableViewDelegate,
							NSComboBoxDataSource,
							NSComboBoxDelegate,
							NSTextViewDelegate {

	deinit {
		clear_strain_profiles()
	}

	var OptTable = Array<OPT>()
	
	let sayMode = "SAY Mode"
	let lookMode = "LOOK Mode"
	let eatMode = "EAT Mode"
	let broadcastMode = "Broadcast Mode"
	let growSize = "Grow Size"
	let makeBarr = "Make Barrier Mode"
	let omoveMode = "OMOVE Mode"
	let makesporeEnergy = "MAKE-SPORE Energy"
	let makeorganicMode = "MAKE-ORGANIC Mode"
	let cmoveMode = "CMOVE Mode"
	let cshiftMode = "CSHIFT Mode"
	let rotateMode = "ROTATE Mode"
	let growEnergy = "GROW Energy"
	let exudeMode = "EXUDE Mode"
	let spawnMode = "SPAWN Mode"
	let listenMode = "LISTEN Mode"
	let shoutMode = "SHOUT Mode"

	let mmaHlp = "Max Apply"
	let mmmHlp = "Merge Mode"
	let mslHlp = "Strand Length"
	let mduHlp = "Duplication"
	let mdeHlp = "Deletion"
	let minHlp = "Insertion"
	let mtrHlp = "Transposition"
	let mmoHlp = "Modification"
	let mmcHlp = "Mutate Code Block"

	let fcbeHlp = "Mutate CB Start"
	let mcbHlp = "Max Code Blocks"

	let deHlp = "Default Energy"
	let dpHlp = "Default Population"
	let seedHlp = "Seed File"

	let descHlp = "Notes"
	let symHlp = "Lookup Symbol"

	let growMode = "GROW Mode"
	let makeSporeMode = "MAKE-SPORE Mode"
	let sendEnergyMode = "SEND-ENERGY Mode"
	let keyPressMode = "KEY-PRESS Mode"
	let readMode = "READ Mode"
	let writeMode = "WRITE Mode"
	let sendMode = "SEND Mode"

	override func windowDidLoad() {
		super.windowDidLoad()

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		
		init_opt_table()
		populate_dialog()
	}
	
	func init_opt_table()
	{
		OptTable.removeAll()
		init_mut_table()
		init_options_table()
		init_def_table()
		init_notes_table()
	}

	func init_mut_table() {
		OptTable.append( OPT(c: mmaTxt,		help: mmaHlp,		type: 0, low: 0, high: 10) )			// 0
		OptTable.append( OPT(c: mmmTxt,		help: mmmHlp,		type: 0, low: 0, high: 2) )				// 1
		OptTable.append( OPT(c: mslTxt,		help: mslHlp,		type: 0, low: 1, high: 20) )			// 2
		OptTable.append( OPT(c: mduTxt,		help: mduHlp,		type: 1, low: 0, high: 0) )				// 3
		OptTable.append( OPT(c: mdeTxt,		help: mdeHlp,		type: 1, low: 0, high: 0) )				// 4
		OptTable.append( OPT(c: minTxt,		help: minHlp,		type: 1, low: 0, high: 0) )				// 5
		OptTable.append( OPT(c: mtrTxt,		help: mtrHlp,		type: 1, low: 0, high: 0) )				// 6
		OptTable.append( OPT(c: mmoTxt,		help: mmoHlp,		type: 1, low: 0, high: 0) )				// 7
		OptTable.append( OPT(c: mmcTxt,		help: mmcHlp,		type: 1, low: 0, high: 0) )				// 8
		OptTable.append( OPT(c: fcbeTxt,	help: fcbeHlp,		type: 0, low: -1, high: 100) )			// 9
		OptTable.append( OPT(c: symTxt,		help: symHlp,		type: 2, low: 0, high: 0) )				// 10
		OptTable.append( OPT(c: mcbTxt,		help: mcbHlp,		type: 0, low: 0, high: 1000) )			// 11
	}

	func init_options_table() {
		OptTable.append( OPT(c: sayTxt,		help: sayMode,			type: 0, low: 0, high: 255) )		// 12
		OptTable.append( OPT(c: lookTxt,	help: lookMode, 		type: 0, low: 0, high: 15) )		// 13
		OptTable.append( OPT(c: eatTxt,		help: eatMode,			type: 0, low: 0, high: 8191) )		// 14
		OptTable.append( OPT(c: broadcastTxt, help: broadcastMode,	type: 0, low: 0, high: 7) )			// 15
		OptTable.append( OPT(c: gsTxt,		help: growSize,			type: 0, low: 0, high: 1000) )		// 16
		OptTable.append( OPT(c: mbTxt,		help: makeBarr,			type: 0, low: 0, high: 3) )			// 17
		OptTable.append( OPT(c: omoveTxt,	help: omoveMode,		type: 0, low: 0, high: 0) )			// 18
		OptTable.append( OPT(c: mseTxt,		help: makesporeEnergy,	type: 0, low: 0, high: 1000) )		// 19
		OptTable.append( OPT(c: moTxt,		help: makeorganicMode,	type: 0, low: 0, high: 0) )			// 20
		OptTable.append( OPT(c: cmTxt,		help: cmoveMode,		type: 0, low: 0, high: 0) )			// 21
		OptTable.append( OPT(c: shTxt,		help: cshiftMode,		type: 0, low: 0, high: 0) )			// 22
		OptTable.append( OPT(c: rotTxt,		help: rotateMode,		type: 0, low: 0, high: 3) )			// 23
		OptTable.append( OPT(c: geTxt,		help: growEnergy,		type: 0, low: 0, high: 1000) )		// 24
		OptTable.append( OPT(c: exTxt,		help: exudeMode,		type: 0, low: 0, high: 63) )		// 25
		OptTable.append( OPT(c: spTxt,		help: spawnMode,		type: 0, low: 0, high: 127) )		// 26
		OptTable.append( OPT(c: lsTxt,		help: listenMode,		type: 0, low: 0, high: 1) )			// 27
		OptTable.append( OPT(c: shtTxt,		help: shoutMode,		type: 0, low: 0, high: 127) )		// 28
		OptTable.append( OPT(c: gmTxt,		help: growMode,			type: 0, low: 0, high: 0) )			// 29
		OptTable.append( OPT(c: msmTxt,		help: makeSporeMode,	type: 0, low: 0, high: 63) )		// 30
		OptTable.append( OPT(c: seTxt,		help: sendEnergyMode,	type: 0, low: 0, high: 2047) )		// 31
		OptTable.append( OPT(c: kpTxt,		help: keyPressMode,		type: 0, low: 0, high: 63) )		// 32
		OptTable.append( OPT(c: rdTxt,		help: readMode,			type: 0, low: 0, high: 127) )		// 33
		OptTable.append( OPT(c: wrTxt,		help: writeMode,		type: 0, low: 0, high: 1023) )		// 34
		OptTable.append( OPT(c: sendTxt,	help: sendMode,			type: 0, low: 0, high: 7) )			// 35
	}

	func init_def_table() {
		OptTable.append( OPT(c: deTxt,		help: deHlp,		type: 0, low: 1, 		high: 100000000) )	// 36
		OptTable.append( OPT(c: dpTxt,		help: dpHlp,		type: 0, low: 1, 		high: 100) )		// 37
		OptTable.append( OPT(c: seedTxt,	help: seedHlp,		type: 2, low: 0, 		high: 0) )			// 38
	}

	func init_notes_table() {
		OptTable.append( OPT(c: descTxt,	help: descHlp,		type: 2, low: 0, 	high: 0) )				// 39
	}

	func find_opt_idx(_ c: NSControl) -> Int {
		for i in 0..<OptTable.count {
			if OptTable[i].c == c {
				return i
			}
		}
		assert(false)
		return -1
	}

	func find_opt(_ c: NSControl) -> OPT {
		let idx = find_opt_idx(c)
		return OptTable[idx]
	}

	func populate_opt_idx(_ idx: Int) {
		let opt = OptTable[idx]
		let sp = nsptab[sp_idx]

		switch idx {
		case 0:		opt.populate(sp.pointee.kfmo.max_apply)
		case 1:		opt.populate(sp.pointee.kfmo.merge_mode)
		case 2:		opt.populate(sp.pointee.kfmo.xlen)
		case 3:		opt.populate(sp.pointee.kfmo.prob_duplicate)
		case 4:		opt.populate(sp.pointee.kfmo.prob_delete)
		case 5:		opt.populate(sp.pointee.kfmo.prob_insert)
		case 6:		opt.populate(sp.pointee.kfmo.prob_transpose)
		case 7:		opt.populate(sp.pointee.kfmo.prob_modify)
		case 8:		opt.populate(sp.pointee.kfmo.prob_mutate_codeblock)
		case 9:		opt.populate(sp.pointee.kfmo.protected_codeblocks)
		case 10:	symTxt.stringValue = lookupSymbol
		case 11:	opt.populate(sp.pointee.kfmo.max_code_blocks)
		case 12:	opt.populate(sp.pointee.strop.say_mode)
		case 13:	opt.populate(sp.pointee.strop.look_mode)
		case 14:	opt.populate(sp.pointee.strop.eat_mode)
		case 15:	opt.populate(sp.pointee.strop.broadcast_mode)
		case 16:	opt.populate(sp.pointee.strop.grow_size)
		case 17:	opt.populate(sp.pointee.strop.make_barrier_mode)
		case 18:	opt.populate(sp.pointee.strop.omove_mode)
		case 19:	opt.populate(sp.pointee.strop.make_spore_energy)
		case 20:	opt.populate(sp.pointee.strop.make_organic_mode)
		case 21:	opt.populate(sp.pointee.strop.cmove_mode)
		case 22:	opt.populate(sp.pointee.strop.cshift_mode)
		case 23:	opt.populate(sp.pointee.strop.rotate_mode)
		case 24:	opt.populate(sp.pointee.strop.grow_energy)
		case 25:	opt.populate(sp.pointee.strop.exude_mode)
		case 26:	opt.populate(sp.pointee.strop.spawn_mode)
		case 27:	opt.populate(sp.pointee.strop.listen_mode)
		case 28:	opt.populate(sp.pointee.strop.shout_mode)
		case 29:	opt.populate(sp.pointee.strop.grow_mode)
		case 30:	opt.populate(sp.pointee.strop.make_spore_mode)
		case 31:	opt.populate(sp.pointee.strop.send_energy_mode)
		case 32:	opt.populate(sp.pointee.strop.key_press_mode)
		case 33:	opt.populate(sp.pointee.strop.read_mode)
		case 34:	opt.populate(sp.pointee.strop.write_mode)
		case 35:	opt.populate(sp.pointee.strop.send_mode)

		case 36:	opt.populate(sp.pointee.energy)
		case 37:	opt.populate(sp.pointee.population)
		case 38:	opt.populate_str( Cstr0(&sp.pointee.seed_file.0, 1000) )

		case 39:	let s = String(cString: StrainProfile_Get_Description(sp))
					descTv.string = s
		default:	assert(false)
		}
	}

	func read_opt_idx(_ idx: Int) {
		let opt = OptTable[idx]
		let sp = nsptab[sp_idx]

		switch idx {
		case 0:		opt.read(&sp.pointee.kfmo.max_apply)
		case 1:		opt.read(&sp.pointee.kfmo.merge_mode)
		case 2:		opt.read(&sp.pointee.kfmo.xlen)
		case 3:		opt.read(&sp.pointee.kfmo.prob_duplicate)
		case 4:		opt.read(&sp.pointee.kfmo.prob_delete)
		case 5:		opt.read(&sp.pointee.kfmo.prob_insert)
		case 6:		opt.read(&sp.pointee.kfmo.prob_transpose)
		case 7:		opt.read(&sp.pointee.kfmo.prob_modify)
		case 8:		opt.read(&sp.pointee.kfmo.prob_mutate_codeblock)
		case 9:		opt.read(&sp.pointee.kfmo.protected_codeblocks)
		case 10:	opt.read_str(&lookupSymbol)
		case 11:	opt.read(&sp.pointee.kfmo.max_code_blocks)
		case 12:	opt.read(&sp.pointee.strop.say_mode)
		case 13:	opt.read(&sp.pointee.strop.look_mode)
		case 14:	opt.read(&sp.pointee.strop.eat_mode)
		case 15:	opt.read(&sp.pointee.strop.broadcast_mode)
		case 16:	opt.read(&sp.pointee.strop.grow_size)
		case 17:	opt.read(&sp.pointee.strop.make_barrier_mode)
		case 18:	opt.read(&sp.pointee.strop.omove_mode)
		case 19:	opt.read(&sp.pointee.strop.make_spore_energy)
		case 20:	opt.read(&sp.pointee.strop.make_organic_mode)
		case 21:	opt.read(&sp.pointee.strop.cmove_mode)
		case 22:	opt.read(&sp.pointee.strop.cshift_mode)
		case 23:	opt.read(&sp.pointee.strop.rotate_mode)
		case 24:	opt.read(&sp.pointee.strop.grow_energy)
		case 25:	opt.read(&sp.pointee.strop.exude_mode)
		case 26:	opt.read(&sp.pointee.strop.spawn_mode)
		case 27:	opt.read(&sp.pointee.strop.listen_mode)
		case 28:	opt.read(&sp.pointee.strop.shout_mode)
		case 29:	opt.read(&sp.pointee.strop.grow_mode)
		case 30:	opt.read(&sp.pointee.strop.make_spore_mode)
		case 31:	opt.read(&sp.pointee.strop.send_energy_mode)
		case 32:	opt.read(&sp.pointee.strop.key_press_mode)
		case 33:	opt.read(&sp.pointee.strop.read_mode)
		case 34:	opt.read(&sp.pointee.strop.write_mode)
		case 35:	opt.read(&sp.pointee.strop.send_mode)
		case 36:	opt.read(&sp.pointee.energy)
		case 37:	opt.read(&sp.pointee.population)
		case 38:
			var str: String = ""
			opt.read_str(&str)
			StrainProfile_Set_SeedFile(sp, str)
		case 39:
			StrainProfile_Set_Description(sp, descTv.string)
		default:	assert(false)
		}
	}

	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////
	
	override var windowNibName: NSNib.Name? {
		return NSNib.Name("StrainCustomizeDialog")
	}
	
	func windowWillClose(_ notification: Notification) {
		print("window will Close")
		NSApplication.shared.stopModal()
	}

	//////////////////////////////////////////////////////////////////////
	//
	// Validation
	//
	func set_error(_ str: String) {
		errorTxt.stringValue = str
	}

	func clear_error() {
		errorTxt.stringValue = ""
	}

	func validate_ctrl(_ c: NSControl, _ val: String) -> (Bool, String) {
		let opt = find_opt(c)
		return opt.validate(val)
	}

	func find_code_block(_ file: String, _ symbol: String) -> (Int, String) {
		var cb = Int32(0)
		var str: String = ""
		var errstr: String = ""
		(str, errstr) = read_file( URL(fileURLWithPath: file) )
		if errstr != "" {
			set_error(errstr)
			return (-1, errstr)
		}

		cb = kforth_program_find_symbol(str, symbol)
		if cb < 0 {
			return (-1, "No such symbol '\(symbol)' in \(file)")
		} else {
			return (Int(cb), "")
		}
	}

	func reformat_control(_ c: NSControl) {
		let opt = find_opt(c)

		if opt.type == 0 {
			c.stringValue = format_comma(c.stringValue)

 		} else if opt.type == 1 {
			c.stringValue = format_percent(c.stringValue)

		} else if opt.type == 2 {
			// nothing to do for string, unless its the lookup symbol field

			if c == symTxt {
				print("Reformat Control. lookup symbol \(c.stringValue)")
				let sp = nsptab[sp_idx]
				var cb: Int
				var errstr: String
//				let seedFile = String(cString: &sp.pointee.seed_file.0)  // KJS testing new recipe
				let seedFile = Cstr0(&sp.pointee.seed_file.0, 1000)

				(cb, errstr) = find_code_block(seedFile, c.stringValue)
				if cb >= 0 {
					fcbeTxt.stringValue = format_comma("\(cb)")
					read_ctrl(fcbeTxt)
					clear_error()
				} else {
					set_error(errstr)
				}
			}
		}
	}

	func clear_all_fields_modified() {
		for i in 0..<OptTable.count {
			OptTable[i].modified = false
		}
		instructionTableModified = false
	}

	func set_field_modified(_ c: NSControl) {
		let opt = find_opt(c)
		opt.modified = true
	}

	func populate_header() {
		if customizeMode {
			spLbl.isHidden = true
			if strainPreferences {
				window!.title = "Strain Properties"
			} else {
				window!.title = "Customize Strain"
			}
			addBut.isHidden = true

		} else {
			spLbl.isHidden = false
			spLbl.isHidden = false
			spLbl.stringValue = "Strain Profile"
			window!.title = "Strain Profiles"
			addBut.isHidden = false
		}
		populate_del_button()
		populate_rc_file_path()
	}
	
	func populate_selection() {
		profCombo.selectItem(at: sp_idx)
	}
	
	func populate_del_button() {
		if customizeMode {
			delBut.isHidden = true
		} else {
			delBut.isHidden = false
//			let s = String(cString: &nsptab[sp_idx].pointee.name.0) // KJS testing
			let s = Cstr0(&nsptab[sp_idx].pointee.name.0, 100)
			if s == "Default" {
				delBut.isEnabled = false
			} else {
				delBut.isEnabled = true
			}
		}
	}

	func populate_rc_file_path() {
		rcFileTxt.stringValue = "Resource file is: " + HomeDirectory() + "/.evolve5rc"
	}
	
	func populate_lookup_symbol() {
		if customizeMode {
			symTxt.isHidden = true
			symLbl.isHidden = true
		} else {
			symTxt.isHidden = false
			symLbl.isHidden = false
		}
		symTxt.stringValue = ""
	}

	func populate_instructions_tab() {
		let sp = nsptab[sp_idx]
		var ops = UnsafeMutablePointer<KFORTH_OPERATIONS>(nil)
		ops = StrainProfile_get_kfops(sp)

		var ops_all = UnsafeMutablePointer<KFORTH_OPERATIONS>(nil)
		ops_all = EvolveOperations()
		
		instructionTable.removeAll()

		for i in 0 ..< Int(ops_all!.pointee.count) {
			var op1 = UnsafeMutablePointer<KFORTH_OPERATION>(nil)
			op1 = kforth_ops_get(ops_all, Int32(i))
			var name1: String
			name1 = String(cString: op1!.pointee.name)

			var protected: Bool = false
			var found: Bool = false
			for j in 0 ..< Int(ops!.pointee.count) {
					var op2 = UnsafeMutablePointer<KFORTH_OPERATION>(nil)
					op2 = kforth_ops_get(ops, Int32(j))
					var name2: String
					name2 = String(cString: op2!.pointee.name)

					if name1 == name2 {
						found = true
						protected = (j < ops!.pointee.nprotected)
						break
					}
			}

			if !found {
				// a new instruction was created in the simulation code.
				// insert into list as protected.
				instructionTable.append( (name1, i, true) )
			} else {
				instructionTable.append( (name1, i, protected) )
			}
		}

		if sortorder.order != SortOrder.ORDER.NATURAL {
	 		sort_instruction_table(&instructionTable, sortorder)
		}
		instrTv.reloadData()
		populate_lookup_symbol()
	}

	func populate_mutations_tab() {
		populate_opt_idx(0)
		populate_opt_idx(1)
		populate_opt_idx(2)
		populate_opt_idx(3)
		populate_opt_idx(4)
		populate_opt_idx(5)
		populate_opt_idx(6)
		populate_opt_idx(7)
		populate_opt_idx(8)
		populate_opt_idx(9)
		populate_opt_idx(10)
		populate_opt_idx(11)
	}
	
	func populate_options_tab() {
		populate_opt_idx(12)
		populate_opt_idx(13)
		populate_opt_idx(14)
		populate_opt_idx(15)
		populate_opt_idx(16)
		populate_opt_idx(17)
		populate_opt_idx(18)
		populate_opt_idx(19)
		populate_opt_idx(20)
		populate_opt_idx(21)
		populate_opt_idx(22)
		populate_opt_idx(23)
		populate_opt_idx(24)
		populate_opt_idx(25)
		populate_opt_idx(26)
		populate_opt_idx(27)
		populate_opt_idx(28)
		populate_opt_idx(29)
		populate_opt_idx(30)
		populate_opt_idx(31)
		populate_opt_idx(32)
		populate_opt_idx(33)
		populate_opt_idx(34)
		populate_opt_idx(35)
	}

	func populate_misc_tab() {
		if customizeMode {
			tabView.removeTabViewItem(miscTab)
			return
		}
		populate_opt_idx(36)
		populate_opt_idx(37)
		populate_opt_idx(38)
	}

	func populate_notes_tab() {
		if customizeMode {
			tabView.removeTabViewItem(notesTab)
			return
		}
		populate_opt_idx(39)
	}
	
	func populate_dialog() {
		clear_error()
		populate_header()
		populate_tab_data()
		populate_selection()
	}
	
	func populate_tab_data() {
		populate_options_tab()
		populate_mutations_tab()
		populate_instructions_tab()
		populate_notes_tab()
		populate_misc_tab()
	}

	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////

	func read_options_tab() {
		read_opt_idx(0)
		read_opt_idx(1)
		read_opt_idx(2)
		read_opt_idx(3)
		read_opt_idx(4)
		read_opt_idx(5)
		read_opt_idx(6)
		read_opt_idx(7)
		read_opt_idx(8)
		read_opt_idx(9)
		read_opt_idx(10)
		read_opt_idx(11)
		read_opt_idx(12)
	}

	func read_mutations_tab() {
		read_opt_idx(11)
		read_opt_idx(12)
		read_opt_idx(13)
		read_opt_idx(14)
		read_opt_idx(15)
		read_opt_idx(16)
		read_opt_idx(17)
		read_opt_idx(18)
		read_opt_idx(19)
		read_opt_idx(20)
		read_opt_idx(21)
		read_opt_idx(22)
		read_opt_idx(23)
		read_opt_idx(24)
		read_opt_idx(25)
		read_opt_idx(26)
		read_opt_idx(27)
		read_opt_idx(28)
		read_opt_idx(29)
		read_opt_idx(30)
		read_opt_idx(31)
		read_opt_idx(32)
		read_opt_idx(33)
		read_opt_idx(34)
		read_opt_idx(35)
	}

	func read_misc_tab() {
		read_opt_idx(36)
		read_opt_idx(37)
		read_opt_idx(38)
	}

	func read_notes_tab() {
		read_opt_idx(39)
	}

	func read_instructions_tab() {
		let sp = nsptab[sp_idx]
		var ops = UnsafeMutablePointer<KFORTH_OPERATIONS>(nil)
		ops = StrainProfile_get_kfops(sp)

		ops!.pointee.count = 0
		ops!.pointee.nprotected = 0

		var ops_all = UnsafeMutablePointer<KFORTH_OPERATIONS>(nil)
		ops_all = EvolveOperations()

		for i in 0..<instructionTable.count {
			var op1 = UnsafeMutablePointer<KFORTH_OPERATION>(nil)
			op1 = kforth_ops_get(ops_all, Int32(i))
			kforth_ops_add2(ops, op1)
		}

		for i in 0..<instructionTable.count {
			let protected = instructionTable[i].2
			if protected {
				kforth_ops_set_protected(ops, instructionTable[i].0)
			}
		}
	}

	func read_dialog() {
		read_options_tab()
		read_mutations_tab()
		read_instructions_tab()
		read_notes_tab()
		read_misc_tab()
	}

	func read_ctrl(_ c: NSControl) {
		let idx = find_opt_idx(c)
		read_opt_idx(idx)
	}
	
	func doit(_ sender: Any?) {
		showWindow(sender)
		NSApplication.shared.runModal(for: self.window!)
	}

	func clear_strain_profiles() {
		for i in 0..<nsptab.count {
			nsptab[i].deallocate()
		}
		nsptab.removeAll()
		modified.removeAll()
	}
	
	func add_strain_profile(_ sp: UnsafeMutablePointer<STRAIN_PROFILE>) {
		let item = UnsafeMutableBufferPointer<STRAIN_PROFILE>.allocate(capacity: 1)
		item.assign(repeating: sp.pointee)
		
		nsptab.append(item.baseAddress!)
		modified.append(false)
	}

	func delete_strain_profile(_ idx: Int) {
		nsptab.remove(at: idx)
		modified.remove(at: idx)

	}

	//////////////////////////////////////////////////////////////////////
	//
	// Table View Data Source
	//
	func tableView(_ tableView: NSTableView, 
						    mouseDownInHeaderOf tableColumn: NSTableColumn) {
		if tableColumn == instrCol {
			sortorder.next_instr()
		} else {
			sortorder.next_protected()

		}
 		sort_instruction_table(&instructionTable, sortorder)
		instrTv.reloadData()
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		return instructionTable.count
	}
	
	func tableView(_ tableView: NSTableView,
			 objectValueFor tableColumn: NSTableColumn?,
				   row: Int) -> Any? {
		if tableColumn == instrCol {
			return instructionTable[row].0
		} else {
			return instructionTable[row].2
		}
	}
	
	func tableView(_ tableView: NSTableView,
			 setObjectValue object: Any?,
						for tableColumn: NSTableColumn?,
				   row: Int) {
		if tableColumn == instrCol {
			instructionTable[row].0 = object as! String
		} else {
			instructionTable[row].2 = object as! Bool
		}
		instructionTableModified = true
	}

	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////////////////
	//
	// Table View Delegate
	//

	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////////
	//
	// Combo Box Delegate
	//
	func comboBoxSelectionDidChange(_ notification: Notification) {
		let c = notification.object as! NSControl
		let cb = c as! NSComboBox
		let i = cb.indexOfSelectedItem
		
		if i < 0 {
			return
		}
		
		if instructionTableModified {
			// protect this call here, else it is called during dialog wake up
			read_instructions_tab()
		}
		sp_idx = i
		populate_tab_data()
		populate_del_button()
	}
	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////


	//////////////////////////////////////////////////////////////////////
	//
	// Combo Box Data Source
	//

	func numberOfItems(in comboBox: NSComboBox) -> Int {
		//return Int(ep!.pointee.nprofiles)
		return nsptab.count
	}
	
	func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
		if index < 0 {
			print("Negative index!")
			return "-"
		}
		
//		var s = String(cString: &nsptab[index].pointee.name.0) // KJS testing new recipe
		var s = Cstr0(&nsptab[index].pointee.name.0, 100)
		if modified[index] {
			s += "*"
		}
		return s
	}
	
	func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
		let upperBound = Int(nsptab.count)
		for i in 0..<upperBound {
//			let s = String(cString: &nsptab[i].pointee.name.0) // KJS testing new recipe
			let s = Cstr0(&nsptab[i].pointee.name.0, 100)
			if string == s {
				return i
			}
		}
		return NSNotFound
	}

	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////
	//
	// Text Field Delegate
	//

	func control(_ control: NSControl,
				 textShouldBeginEditing fieldEditor: NSText) -> Bool {
		print("Text Should Begin Editing Called")
		return true
	}

	func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		print("text should end editing")

		var success: Bool
		var err: String

		(success, err) = validate_ctrl(control, control.stringValue)
		set_error(err)
		
		if success {
			reformat_control(control)
		}

		return success
	}
	
	func controlTextDidBeginEditing(_ obj: Notification) {
		print("Begin Editing")
	}

	func controlTextDidChange(_ obj: Notification) {
		print("Text Did Change.")
		let c = obj.object as! NSTextField
		var success: Bool
		var err: String

		(success, err) = validate_ctrl(c, c.stringValue)
		if success {
			set_profile_modified()
			refresh_combo()
			read_ctrl(c)
		} else {
			set_field_modified(c)
		}
	}
	
	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////

	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////
	//
	// Text View Delegate
	//

	func textDidChange(_ notification: Notification) {
		print("TextDidChange TV")
		set_profile_modified()
		refresh_combo()
		read_ctrl(descTxt)
		clear_error()
	}

	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////

	func refresh_combo() {
		profCombo.reloadData()
		if profCombo.indexOfSelectedItem >= 0 {
			// this helps force a redraw
			profCombo.selectItem(at: profCombo.indexOfSelectedItem)
		}		
	}

	func set_profile_modified() {
		modified[sp_idx] = true
	}

	//
	// https://stackoverflow.com/questions/28362472/is-there-a-simple-input-box-in-cocoa
	//
	func getString(_ title: String, _ question: String, _ defaultValue: String) -> String {
		let msg = NSAlert()
		msg.alertStyle = NSAlert.Style.informational

		msg.addButton(withTitle: "OK")      // 1st button
		msg.addButton(withTitle: "Cancel")  // 2nd button
		msg.messageText = title
		msg.informativeText = question

		let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
		txt.stringValue = defaultValue

		msg.accessoryView = txt
		let response: NSApplication.ModalResponse = msg.runModal()

		if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
			return txt.stringValue
		} else {
			return ""
		}
	}
	
	func getYesNo(_ question: String) -> Bool {
		let msg = NSAlert()
		msg.alertStyle = NSAlert.Style.informational

		msg.addButton(withTitle: "Yes")      // 1st button
		msg.addButton(withTitle: "No")  // 2nd button
		msg.messageText = question
		msg.informativeText = ""

		let response: NSApplication.ModalResponse = msg.runModal()

		if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
			return true
		} else {
			return false
		}
	}
	
	func find_profile_idx(_ name: String) -> Int {
		for i in 0..<nsptab.count {
//			let s = String(cString: &nsptab[i].pointee.name.0) // KJS testing
			let s = Cstr0(&nsptab[i].pointee.name.0, 100)
			if s == name {
				return i
			}
		}
		return -1
	}

	@IBAction func cancelBut(_ sender: Any) {
		self.success = false
		close()
	}
	
	@IBAction func okBut(_ sender: Any) {
		var success: Bool
		var err: String

		for i in 0..<OptTable.count {
			let opt = OptTable[i]
			if opt.modified {
				(success, err) = opt.validate(opt.c.stringValue)
				if !success {
					set_error(err)
					return
				}
			}
		}

		for i in 0..<modified.count {
			if modified[i] {
				was_modified = true
				break
			}
		}
		
		if deleteCount > 0 {
			was_modified = true
		}
		
		if instructionTableModified {
			read_instructions_tab()
		}

		self.success = true
		close()
	}
	
	@IBAction func helpBut(_ sender: Any) {
		if customizeMode {
			ShowHelp("strain_properties_dialog")
		} else {
			ShowHelp("strain_profiles_dialog")
		}
	}

	@IBAction func addBut(_ sender: Any) {
		let x: String
		var j: Int = 0
		var newstr: String = ""
		let i = profCombo.indexOfSelectedItem

		// let str = String(cString: &nsptab[i].pointee.name.0) // KJS testing
		let str = Cstr0(&nsptab[i].pointee.name.0, 100)

		for i in 2...9 {
			newstr = str + "\(i)"
			j = find_profile_idx(newstr)
			if j == -1 {
				break
			}
		}
		
		if j != -1 {
			newstr = ""
		}
		
		x = getString("Enter new profile name:", "", newstr)
		if x ==  "" {
			return
		}

		j = find_profile_idx(x)
		if j != -1 {
			set_error("profile name '\(x)' already used.")
			return
		}

		// update the model
		add_strain_profile(nsptab[sp_idx])
		sp_idx = nsptab.count-1
		StrainProfile_Set_Name(nsptab[sp_idx], x)
		StrainOptions_Set_Name(&nsptab[sp_idx].pointee.strop, x)
		
		clear_all_fields_modified()
		set_profile_modified()
		clear_error()
		populate_tab_data()
		refresh_combo()
		profCombo.selectItem(at: sp_idx)
	}

	@IBAction func delBut(_ sender: Any) {
		var yes: Bool
		let i = profCombo.indexOfSelectedItem

//		let str = String(cString: &nsptab[i].pointee.name.0) // KJS testing
		let str = Cstr0(&nsptab[i].pointee.name.0, 100)

		yes = getYesNo("Delete strain profile '\(str)'?")
		if !yes {
			return
		}

		// update the model
		delete_strain_profile(sp_idx)
		if sp_idx >= nsptab.count {
			sp_idx = nsptab.count-1
		}
		deleteCount += 1

		clear_all_fields_modified()
		clear_error()
		populate_tab_data()
		refresh_combo()
		profCombo.selectItem(at: sp_idx)
	}
	
	func file_selector(_ dir: String) -> String? {
		fd.directoryURL = URL(fileURLWithPath: dir)
		fd.directoryURL = URL(fileURLWithPath: dir)
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
		let url = URL(fileURLWithPath: seedTxt!.stringValue)
		let dirUrl = url.deletingLastPathComponent()
		
		let f = file_selector(dirUrl.path)
		if f != nil {
			seedTxt!.stringValue = f!
			read_ctrl(seedTxt)
			set_profile_modified()
			refresh_combo()
		}
	}
	
	@IBAction func checkBut(_ sender: Any) {
		print("Check Button Pressed \(sender)")
		let tv: NSTableView = sender as! NSTableView
		print("tv = \(tv.selectedRow)")

		// update the model
		let i: Int = tv.selectedRow
		instructionTable[i].2 = !instructionTable[i].2

		set_profile_modified()
		refresh_combo()
		clear_error()
	}
	
	@IBAction func questionBut(_ sender: Any) {
		let c: NSButton = sender as! NSButton
		switch c.tag {
		case 1:		ShowHelp("ref_LOOK")
		case 2:		ShowHelp("ref_EAT")
		case 3:		ShowHelp("ref_BROADCAST")
		case 4:		ShowHelp("ref_GROW")
		case 5:		ShowHelp("ref_GROW")
		case 6:		ShowHelp("ref_GROW")
		case 7:		ShowHelp("ref_MAKE_SPORE")
		case 8:		ShowHelp("ref_MAKE_SPORE")
		case 9:		ShowHelp("ref_MAKE_ORGANIC")
		case 10:	ShowHelp("ref_MAKE_BARRIER")
		case 11:	ShowHelp("ref_SEND_ENERGY")
		case 12:	ShowHelp("ref_KEY_PRESS")
		case 13:	ShowHelp("ref_SPAWN")
		case 14:	ShowHelp("ref_LISTEN")
		case 15:	ShowHelp("ref_SHOUT")
		case 16:	ShowHelp("ref_CMOVE")
		case 17:	ShowHelp("ref_CSHIFT")
		case 18:	ShowHelp("ref_OMOVE")
		case 19:	ShowHelp("ref_EXUDE")
		case 20:	ShowHelp("ref_READ")
		case 21:	ShowHelp("ref_WRITE")
		case 22:	ShowHelp("ref_SAY")
		case 23:	ShowHelp("ref_SEND")
		case 24:	ShowHelp("ref_ROTATE")
		default:
			assert(false)
		}
	}

	@IBOutlet var sayTxt: NSTextField!
	@IBOutlet var lookTxt: NSTextField!
	@IBOutlet var eatTxt: NSTextField!
	@IBOutlet var broadcastTxt: NSTextField!
	@IBOutlet var gsTxt: NSTextField!
	@IBOutlet var mbTxt: NSTextField!
	@IBOutlet var omoveTxt: NSTextField!
	@IBOutlet var mseTxt: NSTextField!
	@IBOutlet var moTxt: NSTextField!
	@IBOutlet var cmTxt: NSTextField!
	@IBOutlet var shTxt: NSTextField!
	@IBOutlet var rotTxt: NSTextField!
	@IBOutlet var geTxt: NSTextField!
	@IBOutlet var exTxt: NSTextField!
	@IBOutlet var spTxt: NSTextField!
	@IBOutlet var lsTxt: NSTextField!
	@IBOutlet var shtTxt: NSTextField!
	@IBOutlet var gmTxt: NSTextField!
	@IBOutlet var msmTxt: NSTextField!
	@IBOutlet var seTxt: NSTextField!
	@IBOutlet var kpTxt: NSTextField!
	@IBOutlet var rdTxt: NSTextField!
	@IBOutlet var wrTxt: NSTextField!
	@IBOutlet var sendTxt: NSTextField!

	@IBOutlet var errorTxt: NSTextField!
	@IBOutlet var instrGrid: NSScrollView!
	var descTxt = NSTextField() // used to populate table with non-nil reference
	@IBOutlet var descTv: NSTextView!
	
	@IBOutlet var mmaTxt: NSTextField!
	@IBOutlet var mmmTxt: NSTextField!
	@IBOutlet var mslTxt: NSTextField!
	@IBOutlet var mduTxt: NSTextField!
	@IBOutlet var mdeTxt: NSTextField!
	@IBOutlet var minTxt: NSTextField!
	@IBOutlet var mtrTxt: NSTextField!
	@IBOutlet var mmoTxt: NSTextField!
	@IBOutlet var mmcTxt: NSTextField!
	@IBOutlet var fcbeTxt: NSTextField!
	@IBOutlet var symTxt: NSTextField!
	@IBOutlet var symLbl: NSTextField!
	@IBOutlet var mcbTxt: NSTextField!
	
	@IBOutlet var seedTxt: NSTextField!
	@IBOutlet var deTxt: NSTextField!
	@IBOutlet var dpTxt: NSTextField!
	
	@IBOutlet var miscTab: NSTabViewItem!
	@IBOutlet var notesTab: NSTabViewItem!
	@IBOutlet var tabView: NSTabView!
	@IBOutlet var spLbl: NSTextField!
	@IBOutlet var instrCol: NSTableColumn!
	@IBOutlet var enableCol: NSTableColumn!
	@IBOutlet var profCombo: NSComboBox!
	@IBOutlet var instrTv: NSTableView!
	@IBOutlet var addBut: NSButton!
	@IBOutlet var delBut: NSButton!
	
	@IBOutlet var rcFileTxt: NSTextField!
	
	var instructionTable = Array<Instruction>()
	var instructionTableModified = false
	var modified = Array<Bool>()
	var deleteCount: Int = 0
	var fd = FileDialog()

	public var customizeMode: Bool = false

	// this is used when customizeMode=true
	public var strainPreferences: Bool = false

	public var success: Bool = false
	public var was_modified: Bool = false
	public var nsptab = Array<UnsafeMutablePointer<STRAIN_PROFILE>>()
	public var sp_idx: Int = 0
	var sortorder = SortOrder()
	var lookupSymbol: String = ""
}
