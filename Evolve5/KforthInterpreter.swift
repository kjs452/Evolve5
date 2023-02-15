//
//  KforthInterpreter.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 8/31/22.
//

import Cocoa
import Foundation
import SwiftUI

class KforthInterpreter: NSWindowController,
						 NSTextViewDelegate,
						 NSWindowDelegate,
						 NSTableViewDelegate,
						 NSTableViewDataSource,
						 NSTextFieldDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        //iw = KforthInstructionDialog()
		// this needed to prevent text being black when in dark
		// mode.
		sourceCode.usesAdaptiveColorMappingForDarkAppearance = true
		disassembly.usesAdaptiveColorMappingForDarkAppearance = true

		//	[textView setSelectedTextAttributes:
		//     [NSDictionary dictionaryWithObjectsAndKeys:
		//      [NSColor blackColor], NSBackgroundColorAttributeName,
		//      [NSColor whiteColor], NSForegroundColorAttributeName,
		//				      nil]];
		//disassembly.selectedTextAttributes = [
		//	NSAttributedString.Key.backgroundColor: NSColor.yellow,
		//	NSAttributedString.Key.foregroundColor: NSColor.red
		//]
		sourceCode.isAutomaticDashSubstitutionEnabled = false
		sourceCode.isAutomaticQuoteSubstitutionEnabled = false
		populate_disassembly()
		clear_error()
		populate_source_code("main: {\n   2 2 +\n}\n")

		var seed = UInt32( generate_seed() )
		sim_random_init(seed, &kfcd.er)

		kfopsBuf = DummyEvolveOperations().pointee
		kfops = UnsafeMutablePointer<KFORTH_OPERATIONS>(&kfopsBuf)
		KforthInterpreter_Replace_Instructions(kfops)
		find_call_instructions()
		populate_instructions()

		kforth_mutate_options_defaults(&kfmo)
		init_opt_table()

		populate_machine()
		populate_protections_tab()
		populate_mutations_tab()
    }

	func populate_protections_tab()
	{
		npcTxt.stringValue = "0"
		symTxt.stringValue = ""
	}

    func textDidChange(_ notification: Notification) {
    }

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("KforthInterpreter")
    }
	
	func windowWillClose(_ notification: Notification) {
		print("window will Close")
		NSApplication.shared.stopModal()
	}
	
	func error(_ str: String) {
		errorLabel.stringValue = str
	}

	func clear_error() {
		errorLabel.stringValue = ""
	}
	
	func doit(_ sender: Any?) {
		showWindow(sender)
		NSApplication.shared.runModal(for: self.window!)
	}

	// build a list of opcodes that are perform a function call
	// and need to be step'd over
	func find_call_instructions() {
		var opname: String
		var op = UnsafeMutablePointer<KFORTH_OPERATION>(nil)

		callopcodes.removeAll()
		write_opcodes.removeAll()

		for i in 0 ..< kfops!.pointee.count {
			op = kforth_ops_get(kfops!, Int32(i));
			opname = String(cString: op!.pointee.name)
			if str_is_call(opname) {
				callopcodes.append(Int16(i))
			} else if str_is_write(opname) {
				write_opcodes.append(Int16(i))
			}
		}
	}

	func is_call_instruction() -> Bool {
		var opcode: Int16
		var cb, pc: Int16

		cb = kfm!.pointee.loc.cb
		pc = kfm!.pointee.loc.pc

		if pc >= kfp!.pointee.block[Int(cb)]![Int(-1)] {
			return false
		}

		opcode = kfp!.pointee.block[Int(cb)]![Int(pc)]   // heh heh heh

		if callopcodes.contains(opcode) {
			return true
		}
		return false
	}

	func is_write_instruction() -> Bool {
		var opcode: Int16
		var cb, pc: Int16

		cb = kfm!.pointee.loc.cb
		pc = kfm!.pointee.loc.pc

		if pc >= kfp!.pointee.block[Int(cb)]![Int(-1)] {
			return false
		}

		opcode = kfp!.pointee.block[Int(cb)]![Int(pc)]

		if write_opcodes.contains(opcode) {
			return true
		}
		return false
	}

	func call_stack_number_of_rows(_ tableView: NSTableView) -> Int {
		if kfm == nil {
			return 0
		}
		return Int(kfm!.pointee.csp)
	}

	func data_stack_number_of_rows(_ tableView: NSTableView) -> Int {
		if kfm == nil {
			return 0
		}
		return Int(kfm!.pointee.dsp)
	}

	func instructions_number_of_rows(_ tableView: NSTableView) -> Int {
		if kfops == nil {
			return 0
		}

		return Int(kfops!.pointee.count)
	}

	func populate_data_stack_row(_ tableView: NSTableView,
						_ tableColumn: NSTableColumn?,
						_ row: Int ) -> Any? {
		if kfm == nil {
			return nil
		}

		var s: String
		
		var value = kforth_machine_ith_data_stack(kfm, Int32(row))
			
		var s1 = String(format: "%2d:", row)
		var s3 = format_comma("\(value)")
		var s2 = String(repeating: " ", count: 12 - s3.count)

		s = s1 + s2 + s3

		return s;
	}

	func populate_call_stack_row(_ tableView: NSTableView,
						_ tableColumn: NSTableColumn?,
						_ row: Int ) -> Any? {
		if kfm == nil {
			return nil
		}

		var s: String
		
		var loc: KFORTH_LOC
		loc = kforth_machine_ith_call_stack(kfm, Int32(row))

		s = String(format: "(cb = %d, pc = %d)",
				Int(loc.cb),
				Int(loc.pc) )

		return s;
	}

	func populate_instructions_row(_ tableView: NSTableView,
						_ tableColumn: NSTableColumn?,
						_ row: Int ) -> Any?
	{
		if kfops == nil {
			return nil
		}
		if tableColumn == instrCol {
			return instructionTable[row].0
		} else {
			return instructionTable[row].2
		}
	}

	func read_instructions()
	{
		while kfops!.pointee.nprotected > 0 {
			var op = kforth_ops_get(kfops, Int32(0))
			kforth_ops_set_unprotected(kfops, op!.pointee.name)
		}

		for i in 0 ..< instructionTable.count {
			var instr = instructionTable[i]

			if instr.2 {
				kforth_ops_set_protected(kfops, instr.0)
			}
		}

		// now we need to rebuild this
		find_call_instructions()
	}

	func read_data_stack_row(
							_ tableView: NSTableView,
							_  object: Any?,
							_ tableColumn: NSTableColumn?,
							_ row: Int )
	{
		// not readable
	}

	func read_call_stack_row(
							_ tableView: NSTableView,
							_  object: Any?,
							_ tableColumn: NSTableColumn?,
							_ row: Int )
	{
		// not readable
	}

	func read_instructions_row(
							_ tableView: NSTableView,
							_  object: Any?,
							_ tableColumn: NSTableColumn?,
							_ row: Int )
	{

		if tableColumn == instrCol {
			instructionTable[row].0 = object as! String
		} else {
			instructionTable[row].2 = object as! Bool
			needsRecompile = true
		}
		instructionTableModified = true
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

	//
	// NSTableViewDelegate
	// tag 100 = data stack
	// tag 200 = call stack
	// tag 300 = instructions
	//
	func numberOfRows(in tableView: NSTableView) -> Int {
		if tableView.tag == 100 {
			return data_stack_number_of_rows(tableView)
		} else if tableView.tag == 200 {
			return call_stack_number_of_rows(tableView)
		} else if tableView.tag == 300 {
			return instructions_number_of_rows(tableView)
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
		} else if tableView.tag == 300 {
			return populate_instructions_row(tableView, tableColumn, row)
		}
		assert(false)
		return nil
	}

	func tableView(_ tableView: NSTableView,
			 setObjectValue object: Any?,
						for tableColumn: NSTableColumn?,
				   row: Int) {

		if tableView.tag == 100 {
			read_data_stack_row(tableView, object, tableColumn, row)
		} else if tableView.tag == 200 {
			read_call_stack_row(tableView, object, tableColumn, row)
		} else if tableView.tag == 300 {
			read_instructions_row(tableView, object, tableColumn, row)
		}
	}

	//////////////////////////////////////////////////////////////////////
	//
	// Table View Data Source END
	//
	//////////////////////////////////////////////////////////////////////

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
		var cb = Int32(0)
		print("text should end editing")

		if control.tag == 400 {
			var s = control.stringValue
			print("lookup symbol \(s)")
			cb = kforth_program_find_symbol(sourceCode.string, control.stringValue)
			if cb < 0 {
				error("No such label '\(s)'")
				return false
			} else {
				npcTxt.stringValue = "\(cb)"
				symTxt.stringValue = ""
			}
		} else if control.tag == 500 {
			print("validate npc")

			cb = Int32( get_comma_int(npcTxt.stringValue) )
			if cb < 0 {
				error("Protected Code Blocks: \(cb) too small.")
				return false
			}
		} else if control.tag == 600 {
			//
			// mutation tab controls all use tag '600'
			//
			var success: Bool
			var err: String
			(success, err) = validate_ctrl(control, control.stringValue)
			error(err)
			if success {
				reformat_control(control)
			}
			return success
		}

		if kfp != nil {
			if cb > kfp!.pointee.nblocks {
				kfp!.pointee.nprotected = kfp!.pointee.nblocks
			} else {
				kfp!.pointee.nprotected = Int32(cb)
			}
			populate_protected_code_blocks();
			clear_error()
		}

		return true
	}
	
	func controlTextDidBeginEditing(_ obj: Notification) {
		print("Begin Editing")
	}

	func controlTextDidChange(_ obj: Notification) {
		print("Text Did Change.")
	}
	
	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////
    
	func file_selector(_ dir: String) -> String? {
		fd.directoryURL = URL(fileURLWithPath: dir)
		fd.nameFieldStringValue = seedFilename
		fd.prompt = "Load"
		fd.message = "Load KFORTH .kf program"
		let ms = fd.runModal()
		if ms == NSApplication.ModalResponse.OK {
			print("File: \(fd.representedFilename)\n")
			print("File: \(fd.url)\n")
			if fd.url != nil {
				g_DataPath = fd.url!.deletingLastPathComponent().path
				seedFilename = fd.url!.lastPathComponent
				return fd.url!.path
			}
		}
		return nil
	}
	
	func file_selector_for_save(_ dir: String) -> String? {
		sd.directoryURL = URL(fileURLWithPath: dir)
		sd.nameFieldStringValue = seedFilename
		sd.prompt = "Save"
		sd.message = "Save KFORTH .kf program"
		let ms = sd.runModal()
		if ms == NSApplication.ModalResponse.OK {
			print("File: \(sd.representedFilename)\n")
			print("File: \(sd.url)\n")
			if sd.url != nil {
				g_DataPath = sd.url!.deletingLastPathComponent().path
				seedFilename = fd.url!.lastPathComponent
				return sd.url!.path
			}
		}
		return nil
	}
	
    @IBAction func saveBut(_ sender: Any) {
		var str = read_source_code()
		var p = file_selector_for_save(g_DataPath)
		if p != nil {
			write_file( URL(fileURLWithPath: p!), str )
		}
    }

	@IBAction func loadBut(_ sender: Any) {		
		print("Load But")
		var p = file_selector(g_DataPath)
		if p == nil {
			return
		}
		var str: String
		var errstr: String
		(str, errstr) = read_file( URL(fileURLWithPath: p!) )
		if errstr != "" {
			error(errstr)
		} else {
			populate_source_code(str)
			clear_error()
		}
	}
    
    @IBAction func instrBut(_ sender: Any) {
        print("Instr But")
		var iw: KforthInstructionDialog

        iw = KforthInstructionDialog()
		var r = disassembly.selectedRange()
		var s: String
		print("R is \(r)")

		if kfm == nil {
			s = ""
		} else if r == NSRange() {
			var r = find_location(kfm!.pointee.loc.cb, kfm!.pointee.loc.pc)
			if r == nil {
				s = ""
			} else {
				s = find_instruction_rng(r!)
			}
		} else {
			s = find_instruction_rng(r)
		}

		iw.doit(sender, s, 3)
    }

	func populate_reg(_ c: NSTextField, _ value: Int16) {
		var s = format_comma("\(value)")
		c.stringValue = s
	}

	func clear_reg(_ c: NSTextField) {
		c.stringValue = ""
	}
	
	func populate_stack_selection(_ c:  NSTableView, _ i: Int16) {
		let x = IndexSet(integer: Int(i))
		c.selectRowIndexes(x, byExtendingSelection: false)
		c.scrollRowToVisible(Int(i))
	}

	func populate_data_stack() {
		dsTv.reloadData()
		if kfm == nil {
			return
		}
		

		populate_stack_selection(dsTv, kfm!.pointee.dsp-1)
	}

	func populate_call_stack() {
		csTv.reloadData()
		if kfm == nil {
			return
		}

		populate_stack_selection(csTv, kfm!.pointee.csp-1)
	}
	
	func populate_machine() {
		if kfm == nil {
			clear_reg(cbTxt)
			clear_reg(pcTxt)
			clear_reg(r0Txt)
			clear_reg(r1Txt)
			clear_reg(r2Txt)
			clear_reg(r3Txt)
			clear_reg(r4Txt)
			clear_reg(r5Txt)
			clear_reg(r6Txt)
			clear_reg(r7Txt)
			clear_reg(r8Txt)
			clear_reg(r9Txt)
		} else {
			populate_reg(cbTxt, kfm!.pointee.loc.cb)
			populate_reg(pcTxt, kfm!.pointee.loc.pc)
			populate_reg(r0Txt, kfm!.pointee.R.0)
			populate_reg(r1Txt, kfm!.pointee.R.1)
			populate_reg(r2Txt, kfm!.pointee.R.2)
			populate_reg(r3Txt, kfm!.pointee.R.3)
			populate_reg(r4Txt, kfm!.pointee.R.4)
			populate_reg(r5Txt, kfm!.pointee.R.5)
			populate_reg(r6Txt, kfm!.pointee.R.6)
			populate_reg(r7Txt, kfm!.pointee.R.7)
			populate_reg(r8Txt, kfm!.pointee.R.8)
			populate_reg(r9Txt, kfm!.pointee.R.9)
		}

		populate_data_stack()
		populate_call_stack()
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

	func find_location_rng(_ r: NSRange) -> KFORTH_LOC? {
		if kfd == nil {
			return nil
		}

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

	func find_instruction_rng(_ r: NSRange) -> String {
		if kfd == nil {
			return ""
		}
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
	
	func get_selection_range() -> NSRange? {
		if kfm != nil {
			return find_location(kfm!.pointee.loc.cb, kfm!.pointee.loc.pc)
		} else {
			return nil
		}
	}

	// mark all the protected code blocks with a diffent label color
	func populate_protected_code_blocks() {
		if kfd == nil {
			return
		}

		var protected = Int(kfp!.pointee.nprotected)

		for i in 0 ..< Int(kfd!.pointee.pos_len) {
			var cb = Int( kfd!.pointee.pos[i].cb )
			var pc = Int( kfd!.pointee.pos[i].pc )
			var s = Int( kfd!.pointee.pos[i].start_pos )
			var e = Int( kfd!.pointee.pos[i].end_pos )

            if pc == -1 {
				if cb < protected {
					var r = NSRange(location: s, length: e-s+1)
					disassembly.setTextColor(NSColor.blue, range: r)
				} else {
					var r = NSRange(location: s, length: e-s+1)
					disassembly.setTextColor(nil, range: r)
				}
            }
		}
		
	}
	
	func populate_location() {
		if kfd == nil {
			return
		}

		let r = get_selection_range()
		if r != nil {
			if lastRedRange != nil {
				disassembly.setTextColor(nil, range: lastRedRange!)
				lastRedRange = nil
				disassembly.setSelectedRange( NSRange() )
			} else {
//				var r2 = NSRange(location: 0, length: disassembly.textStorage!.length)
//				disassembly.setTextColor(nil, range: r2)
			}

			disassembly.setSelectedRange(r!)
			disassembly.scrollRangeToVisible(r!)
			disassembly.showFindIndicator(for: r!)
			disassembly.setTextColor(NSColor.red, range: r!)
			disassembly.setSelectedRange( NSRange() )
			lastRedRange = r!

		} else {
			if lastRedRange != nil {
				disassembly.setTextColor(nil, range: lastRedRange!)
				lastRedRange = nil
				disassembly.setSelectedRange( NSRange() )
			} else {
//				var r2 = NSRange(location: 0, length: disassembly.textStorage!.length)
//				disassembly.setTextColor(nil, range: r2)
//				disassembly.setSelectedRange( NSRange() )
			}
		}
	}
	
	func populate_code(_ c: NSTextView, _ str: String) {
		//		sourceCode.string = program
		//		sourceCode.textStorage?.setAttributedString(NSAttributedString(string: program))

		//let quote = program
		//let font = NSFont.systemFont(ofSize: 12)
				
		let font2 = NSFont.userFixedPitchFont(ofSize: 12)
				
		let attributes = [NSAttributedString.Key.font: font2]
		let attributedQuote = NSAttributedString(string: str, attributes: attributes as [NSAttributedString.Key : Any])
		c.textStorage!.setAttributedString(attributedQuote)
	}

	func populate_instructions()
	{
		var op = UnsafeMutablePointer<KFORTH_OPERATION>(nil)
		var name: String

		if kfops == nil {
			return
		}

		instructionTable.removeAll()

		for i in 0 ..< Int(kfops!.pointee.count) {
			op = kforth_ops_get(kfops, Int32(i))
			name = String(cString: op!.pointee.name)

			instructionTable.append( (name, i, false) )
		}

		if sortorder.order != SortOrder.ORDER.NATURAL {
	 		sort_instruction_table(&instructionTable, sortorder)
		}

		instrTv.reloadData()
	}

	func populate_disassembly() {
		if kfd != nil {
			var program = String(cString: kfd!.pointee.program_text)
			populate_code(disassembly, program)
		} else {
			populate_code(disassembly, "")
		}
		disassembly.needsDisplay = true
	}

	func populate_source_code(_ program: String) {
		populate_code(sourceCode, program)
	}

	func read_source_code() -> String {
		return sourceCode.string
	}
	
	func disassemble_program() {
		if kfd != nil {
			kforth_disassembly_delete(kfd)
			kfd = nil
		}

		if kfp == nil {
			return
		}

        kfd = kforth_disassembly_make(kfops, kfp, 55, 1)

		if kfd == nil {
			var str = "kforth dissasembly make failed"
			error(str)
		}

		populate_disassembly()
	}
	
	func compile_program(_ source_code: String) {
		if kfp != nil {
			kforth_delete(kfp)
			kfp = nil
		}

		if kfm != nil {
			kforth_machine_delete(kfm)
			kfm = nil
		}

		read_instructions()

		var eb: [CChar]
		eb = Array(repeating: CChar(0), count: 1000)

        kfp = kforth_compile(source_code, kfops, &eb)
		if kfp == nil {
	        var str = String(cString: &eb, encoding: String.Encoding.ascii)!
			error(str)
			return
		}

		kfm = kforth_machine_make()

		disassemble_program()
		needsRecompile = false
	}
    
	@IBAction func compileBut(_ sender: Any) {
		var source_code = sourceCode.string
		breakpoints.removeAll()
		compile_program(source_code)
		populate_machine()
		populate_location()
		
		if kfp == nil {
			return
		}

		var npc = get_comma_int(npcTxt.stringValue)

		if npc < 0 {
			error("Protected Code Blocks: \(npc) too small.")
			return
		}

		if npc > kfp!.pointee.nblocks {
			kfp!.pointee.nprotected = kfp!.pointee.nblocks
		} else {
			kfp!.pointee.nprotected = Int32(npc)
		}

		populate_protected_code_blocks();
		clear_error()
	}
	
	@IBAction func resetBut(_ sender: Any) {
		if kfm == nil {
			return
		}
		kforth_machine_reset(kfm)
		clear_error()
		populate_machine()
		populate_location()
	}
	
	@IBAction func stepBut(_ sender: Any) {
		var modified: Bool = false
		clear_error()

		if kfm != nil {
			if kforth_machine_terminated(kfm) != 0 {
				error("Terminated.")
			} else {
				modified = false
				if is_write_instruction() { modified = true }
				kforth_machine_execute(kfops, kfp, kfm, &kfcd)
				if kforth_machine_terminated(kfm) != 0 {
					error("Terminated.")
				}
			}
		}

		if modified {
			disassemble_program()

			insert_breakpoint_indicator()
			populate_protected_code_blocks();
		}
		
		populate_machine()
		populate_location()
	}
	
	@IBAction func stepOver(_ sender: Any) {
		var cb, pc, css: Int16
		var modified: Bool = false
		var count = Int(0)

		clear_error()
		if kfm == nil {
			return
		}

		if kforth_machine_terminated(kfm) != 0 {
			error("Terminated.")
			return
		}

		if !is_call_instruction() {
			stepBut(sender)
			return
		}

		css = kfm!.pointee.csp
		cb = kfm!.pointee.loc.cb
		pc = kfm!.pointee.loc.pc

		for i in 0..<step_limit {

			if i > 0 && break_point_reached() {
				error("Break Point.")
				break
			}

			if is_write_instruction() { modified = true }

			kforth_machine_execute(kfops, kfp, kfm, &kfcd)
			if kforth_machine_terminated(kfm) != 0 {
				error("Terminated.")
				break
			}

			if kfm!.pointee.csp == css
						&& kfm!.pointee.loc.cb == cb
						&& kfm!.pointee.loc.pc == pc + 1 {
				break
			}
			count += 1
		}

		if count == step_limit {
			error("Step limit reached.")
		}

		if modified {
			disassemble_program()
			insert_breakpoint_indicator()
			populate_protected_code_blocks();
		}
		
		populate_machine()
		populate_location()
	}

	func break_point_reached() -> Bool {
		for i in 0 ..< breakpoints.count {
			var loc1 = breakpoints[i]
			var loc2 = kfm!.pointee.loc
			if loc1.pc == loc2.pc && loc1.cb == loc2.cb {
				return true
			}
		}
		return false
	}

	@IBAction func runBut(_ sender: Any) {
		var modified: Bool = false
		print("Run But")
		clear_error()

		if kfm != nil {
			if kforth_machine_terminated(kfm) != 0 {
				error("Terminated.")
			} else {
				for i in 0..<step_limit {
					if i > 0 && break_point_reached() {
						error("Break Point.")
						break
					}

					if is_write_instruction() { modified = true }

					kforth_machine_execute(kfops, kfp, kfm, &kfcd)
					if kforth_machine_terminated(kfm) != 0 {
						error("Terminated.")
						break
					}
				}

				if kforth_machine_terminated(kfm) == 0 && !break_point_reached() {
					error("Step limit reached.")
				}

			}
		}
		
		if modified {
			disassemble_program()
			insert_breakpoint_indicator()
			populate_protected_code_blocks();
		}

		populate_machine()
		populate_location()
	}
	
	@IBAction func clearbpBut(_ sender: Any) {
		for i in 0 ..< breakpoints.count {
			var loc = breakpoints[i]
			var r = find_location(loc.cb, loc.pc)
			if r != nil {
				var r2 = NSRange(location: r!.location-1, length: 1)
				disassembly.textStorage!.replaceCharacters(in: r2, with: " ")
			}
		}
		breakpoints.removeAll()
		clear_error()
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
		for i in 0 ..< breakpoints.count {
			loc = breakpoints[i]

			r = find_location(loc.cb, loc.pc)
			r2 = NSRange(location: r!.location-1, length: 1)
			disassembly.textStorage!.replaceCharacters(in: r2!, with: bpChar)
		}
	}
	
	@IBAction func bpBut(_ sender: Any) {
		var r, r2, r3: NSRange?
		var bpChar: String
		var loc: KFORTH_LOC?

		print("break point But")

		r = disassembly.selectedRange()
		print("R is \(r)")

		if kfm == nil {
			return
		}

		if r == NSRange() {
			bpChar = "\u{270B}"
			for i in 0 ..< breakpoints.count {
				var loc1 = breakpoints[i]
				var loc2 = kfm!.pointee.loc
				if loc1.cb == loc2.cb && loc1.pc == loc2.pc {
					bpChar = " "
					breakpoints.remove(at: i)
					break
				}
			}
			r2 = find_location(kfm!.pointee.loc.cb, kfm!.pointee.loc.pc)
			if bpChar != " " {
				breakpoints.append(kfm!.pointee.loc)
			}
		} else {
			loc = find_location_rng(r!)
			if loc == nil {
				return
			}

			bpChar = "\u{270B}"
			for i in 0 ..< breakpoints.count {
				var loc1 = breakpoints[i]
				var loc2 = loc!
				if loc1.cb == loc2.cb && loc1.pc == loc2.pc {
					bpChar = " "
					breakpoints.remove(at: i)
					break
				}
			}
			r2 = find_location(loc!.cb, loc!.pc)
			if bpChar != " " {
				breakpoints.append(loc!)
			}
		}

		if r2 != nil {
			r3 = NSRange(location: r2!.location-1, length: 1)
			disassembly.textStorage!.replaceCharacters(in: r3!, with: bpChar)
			clear_error()
		} else {
			error("No location selected.")
		}
	}
	
	@IBAction func helpBut(_ sender: Any) {
		ShowHelp("kforth_interpreter_dialog")
	}
	
	@IBAction func closeBut(_ sender: Any) {
		close()
	}

	func validate_mutations_tab() -> Bool {
		var success: Bool
		var err: String
		
		//
		// validate mutation fields
		//
		for i in 0 ..< OptTable.count {
			var opt = OptTable[i]
			(success, err) = opt.validate(opt.c.stringValue)
			if !success {
				error(err)
				return false
			}
		}
		clear_error()

		return true
	}

	//////////////////////////////////////////////////////////////////////
	//
	// Mini-evolution/Mutation Algorithm
	//
	struct SCORE {
		var score = Int(0)
		var nsteps = Int(0)
	}

	func score_program_once(_ prog: UnsafeMutablePointer<KFORTH_PROGRAM>, _ step_limit: Int) -> SCORE {
		var result = SCORE()
		var count = Int(0)

		kforth_machine_reset(kfm)

		for i in 0 ..< step_limit {
			kforth_machine_execute(kfops, prog, kfm, &kfcd)
			if kforth_machine_terminated(kfm) != 0 {
				break
			}
			count += 1
		}

		if count == step_limit {
			// program never terminated in the alloted time
			result.score = -32768;
		} else if kfm!.pointee.dsp == 0 {
			result.score = 0;
		} else {
			result.score = Int( kforth_machine_ith_data_stack(kfm, Int32(kfm!.pointee.dsp-1)) )
		}

		result.nsteps = count
		return result
	}

	//
	// Run program 'trail' times, and compute average score and
	// average number of steps.
	//
	func score_program(_ TRIALS: Int, _ prog: UnsafeMutablePointer<KFORTH_PROGRAM>, _ step_limit: Int) -> SCORE {
		var avg = SCORE()
		var s = SCORE()

		avg.score = 0
		avg.nsteps = 0
		for k in 0 ..< TRIALS {
			s = score_program_once(prog, step_limit)
			avg.score += s.score
			avg.nsteps += s.nsteps
		}

		if TRIALS > 0 {
			avg.score = avg.score / TRIALS
			avg.nsteps = avg.nsteps / TRIALS
		}

		return avg
	}

	func mutate_program() {
		var TIMES = Int(tim)
		var POPULATION = Int(pop)
		var TRIALS = Int(tri)
		var s = SCORE()
		var best = SCORE()
		var tmp_kfp = UnsafeMutablePointer<KFORTH_PROGRAM>(nil)
		var cur_kfp = UnsafeMutablePointer<KFORTH_PROGRAM>(nil)
		var best_kfp = UnsafeMutablePointer<KFORTH_PROGRAM>(nil)

		cur_kfp = kforth_copy(kfp)

		for i in 0 ..< TIMES {

			best_kfp = kforth_copy(cur_kfp)
			best = score_program(TRIALS, best_kfp!, 10000)

			for j in 0 ..< POPULATION {
				tmp_kfp = kforth_copy(cur_kfp)
				kforth_mutate(kfops, &kfmo, &kfcd.er, tmp_kfp!)

				s = score_program(TRIALS, tmp_kfp!, 10000)

				if TRIALS == 0 
						|| s.score > best.score
						|| (s.score == best.score && s.nsteps < best.nsteps) {
					if best_kfp != nil {
						kforth_delete(best_kfp)
					}
					best_kfp = tmp_kfp
					best = s

				} else {
					kforth_delete(tmp_kfp)
				}
			}
			kforth_delete(cur_kfp)
			cur_kfp = kforth_copy(best_kfp)
		}
		kforth_delete(kfp)
		kfp = cur_kfp
	}
	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////
	
	@IBAction func mutateBut(_ sender: Any) {
		var success: Bool

		success = validate_mutations_tab()
		if !success {
			return
		}

		if kfp == nil {
			return
		}

		if needsRecompile {
			error("Must recompile, due to recent changes")
			return
		}

		assert(kfm != nil)
		kforth_machine_reset(kfm)

		breakpoints.removeAll()
		read_instructions()

		read_mutations_tab()

		mutate_program()

		disassemble_program()

		populate_disassembly()
		insert_breakpoint_indicator()
		populate_protected_code_blocks();
		populate_machine()
		populate_location()
	}
	
	@IBOutlet var errorLabel: NSTextField!
	@IBOutlet var sourceCode: NSTextView!
	@IBOutlet var disassembly: NSTextView!
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
	@IBOutlet var dsTv: NSTableView!
	@IBOutlet var csTv: NSTableView!
	@IBOutlet var instrTv: NSTableView!
	@IBOutlet var instrCol: NSTableColumn!
	@IBOutlet var protCol: NSTableColumn!
	@IBOutlet var npcTxt: NSTextField!
	@IBOutlet var symTxt: NSTextField!

	@IBOutlet var mmmTxt: NSTextField!	
	
	//
	// mutation tab text fields are all stored in this
	// array.
	// 
	var OptTable = Array<OPT>()

	@IBOutlet var mmaTxt: NSTextField!		// max apply
	@IBOutlet var mcbTxt: NSTextField!		// max code blocks
	@IBOutlet var mslTxt: NSTextField!		// max strand length
	@IBOutlet var mduTxt: NSTextField!
	@IBOutlet var mdeTxt: NSTextField!
	@IBOutlet var minTxt: NSTextField!		// insertion
	@IBOutlet var mtrTxt: NSTextField!
	@IBOutlet var mmoTxt: NSTextField!		// modification
	@IBOutlet var mmcTxt: NSTextField!		// mutate code block
	@IBOutlet var timTxt: NSTextField!
	@IBOutlet var popTxt: NSTextField!
	@IBOutlet var triTxt: NSTextField!		// trials

	func find_opt_idx(_ c: NSControl) -> Int {
		for i in 0 ..< OptTable.count {
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

	func validate_ctrl(_ c: NSControl, _ val: String) -> (Bool, String) {
		let opt = find_opt(c)
		return opt.validate(val)
	}

	func reformat_control(_ c: NSControl) {
		let opt = find_opt(c)

		if opt.type == 0 {
			c.stringValue = format_comma(c.stringValue)

 		} else if opt.type == 1 {
			c.stringValue = format_percent(c.stringValue)

		} else if opt.type == 2 {
			// nothing to do for string
		}
	}

	func populate_opt_idx(_ idx: Int) {
		let opt = OptTable[idx]
		switch idx {
		case 0:		opt.populate(kfmo.max_apply)
		case 1:		opt.populate(kfmo.max_code_blocks)
		case 2:		opt.populate(kfmo.xlen)
		case 3:		opt.populate(kfmo.prob_duplicate)
		case 4:		opt.populate(kfmo.prob_delete)
		case 5:		opt.populate(kfmo.prob_insert)
		case 6:		opt.populate(kfmo.prob_transpose)
		case 7:		opt.populate(kfmo.prob_modify)
		case 8:		opt.populate(kfmo.prob_mutate_codeblock)
		case 9:		opt.populate(tim)
		case 10:	opt.populate(pop)
		case 11:	opt.populate(tri)
		default:	assert(false)
		}
	}

	func read_opt_idx(_ idx: Int) {
		let opt = OptTable[idx]

		switch idx {
		case 0:		opt.read(&kfmo.max_apply)
		case 1:		opt.read(&kfmo.max_code_blocks)
		case 2:		opt.read(&kfmo.xlen)
		case 3:		opt.read(&kfmo.prob_duplicate)
		case 4:		opt.read(&kfmo.prob_delete)
		case 5:		opt.read(&kfmo.prob_insert)
		case 6:		opt.read(&kfmo.prob_transpose)
		case 7:		opt.read(&kfmo.prob_modify)
		case 8:		opt.read(&kfmo.prob_mutate_codeblock)
		case 9:		opt.read(&tim)
		case 10:	opt.read(&pop)
		case 11:	opt.read(&tri)
		default:	assert(false)
		}
	}

	func read_mutations_tab() {
		for i in 0 ..< OptTable.count {
			read_opt_idx(i)
		}
	}

	func populate_mutations_tab() {
		for i in 0 ..< OptTable.count {
			populate_opt_idx(i)
		}
	}

	func init_opt_table() {
		let mmaHlp = "Max Apply"
		let mcbHlp = "Max Code Blocks"
		let mslHlp = "Strand Length"
		let mduHlp = "Duplication"
		let mdeHlp = "Deletion"
		let minHlp = "Insertion"
		let mtrHlp = "Transposition"
		let mmoHlp = "Modification"
		let mmcHlp = "Mutate Code Block"
		let timHlp = "Times"
		let popHlp = "Population"
		let triHlp = "Trials"

		OptTable.append( OPT(c: mmaTxt,		help: mmaHlp,		type: 0, low: 0, high: 10) )	// 0
		OptTable.append( OPT(c: mcbTxt,		help: mcbHlp,		type: 0, low: 0, high: 1000) )	// 1
		OptTable.append( OPT(c: mslTxt,		help: mslHlp,		type: 0, low: 1, high: 20) )	// 2
		OptTable.append( OPT(c: mduTxt,		help: mduHlp,		type: 1, low: 0, high: 0) )		// 3
		OptTable.append( OPT(c: mdeTxt,		help: mdeHlp,		type: 1, low: 0, high: 0) )		// 4
		OptTable.append( OPT(c: minTxt,		help: minHlp,		type: 1, low: 0, high: 0) )		// 5
		OptTable.append( OPT(c: mtrTxt,		help: mtrHlp,		type: 1, low: 0, high: 0) )		// 6
		OptTable.append( OPT(c: mmoTxt,		help: mmoHlp,		type: 1, low: 0, high: 0) )		// 7
		OptTable.append( OPT(c: mmcTxt,		help: mmcHlp,		type: 1, low: 0, high: 0) )		// 8
		OptTable.append( OPT(c: timTxt,		help: timHlp,		type: 0, low: 1, high: 100) )	// 9
		OptTable.append( OPT(c: popTxt,		help: popHlp,		type: 0, low: 1, high: 100) )	// 10
		OptTable.append( OPT(c: triTxt,		help: triHlp,		type: 0, low: 0, high: 1000) )	// 11
	}
	
	var instructionTable = Array<Instruction>()
	var instructionTableModified = false

	var kfmo = KFORTH_MUTATE_OPTIONS()
	var tim = Int32(1)
	var pop = Int32(1)
	var tri = Int32(0)
	var step_limit: Int = 2 * (1000*1000)

	var lastRedRange: NSRange!
	var needsRecompile = Bool(false)
	
	var fd = FileDialog()
	var sd = NSSavePanel()
	var kfcd = KFORTH_INTERPRETER_CLIENT_DATA()
    var kfp = UnsafeMutablePointer<KFORTH_PROGRAM>(nil)
    var kfm = UnsafeMutablePointer<KFORTH_MACHINE>(nil)
    var kfd = UnsafeMutablePointer<KFORTH_DISASSEMBLY>(nil)
	var kfops = UnsafeMutablePointer<KFORTH_OPERATIONS>(nil)
	var kfopsBuf = KFORTH_OPERATIONS()
	var breakpoints = Array<KFORTH_LOC>()
	var disassembly_updated: Bool = false
	var callopcodes = Array<Int16>()
	var write_opcodes = Array<Int16>()
	var sortorder = SortOrder()
	var seedFilename = String("seed.kf")
}
