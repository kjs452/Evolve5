//
//  KforthInstructionDialog.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 9/2/22.
//

import Cocoa

class KforthInstructionDialog: NSWindowController,
							   NSWindowDelegate,
							   NSTableViewDelegate,
							   NSTableViewDataSource {

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        td.delegate = self
        td.dataSource = self
        populate_dialog()
		populate_wakeup_opcode();
		populate_detail_area();
    }

	func populate_wakeup_opcode() {
		var r: Int

		r = get_row_for_instruction(wakeup_opcode)
		if r >= 0 {
			// KJS set selection
			td.selectRowIndexes(IndexSet(integer: r), byExtendingSelection: false)
			td.scrollRowToVisible(r)
		}

	}

	func populate_dialog() {
		print("Fill")
		if (filter & 4) != 0 {
			// find instructions, enable 'Insert' button
			insertBut.isHidden = false
		} else {
			insertBut.isHidden = true
		}
	}

	func populate_detail_area() {
		if td.selectedRow < 0 {
			descLabel.stringValue = ""
			commentLabel.stringValue = ""
			usageLabel.stringValue = ""
			hlp.isEnabled = false
			hlp.isHidden = true
			return
		}
        var row = td.selectedRow
        print("selection did change row = \(row)")
		var istr: String
        var s: String

		var x = UnsafeMutablePointer<KFORTH_IHELP>(nil)
		x = get_instruction_at_row(row)

		istr = String(cString: x!.pointee.instruction)
        //s = istr + "      ; " + String(cString: x!.pointee.comment)
		s = String(cString: x!.pointee.instruction)
		insertInstruction = istr
        commentLabel.stringValue = s
		usageLabel.stringValue = "Usage: " + String(cString: x!.pointee.comment)

		s = String(cString: x!.pointee.description)
        descLabel.stringValue = s
		hlp.isEnabled = true
		hlp.isHidden = false
	}
    
    @IBAction func insertBut(_ sender: Any) {
		close()
    }
    
    @IBAction func closeBut(_ sender: Any) {
		insertInstruction = ""
		close()
    }
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("KforthInstructionDialog")
    }

	func windowWillClose(_ notification: Notification) {
		NSApplication.shared.stopModal()
	}
	
	func doit(_ sender: Any?, _ opcode: String, _ filter: Int) {
		self.filter = filter
		self.wakeup_opcode = opcode
		showWindow(sender)
		NSApplication.shared.runModal(for: self.window!)
	}
                
    //
    // NSTableViewDelegate stuff
    //
    func numberOfRows(in tableView: NSTableView) -> Int {
		var result: Int = 0

		for i in 0 ..< Int(Kforth_Instruction_Help_len) {
			var x = UnsafeMutablePointer<KFORTH_IHELP>(nil)
			x = Kforth_Instruction_Help + i

			var success: Bool = (Int(x!.pointee.mask) & filter) != 0

			if success {
				result += 1
			}
		}
		return result
    }

	func get_row_for_instruction(_ instr: String) -> Int {
		var ith_row: Int = 0
		for i in 0 ..< Int(Kforth_Instruction_Help_len) {
			var x = UnsafeMutablePointer<KFORTH_IHELP>(nil)
			x = Kforth_Instruction_Help + i

			var success: Bool = (Int(x!.pointee.mask) & filter) != 0
			if success {
				var s = String(cString: x!.pointee.instruction)
				if s == instr {
					return ith_row
				}
				ith_row += 1
			}
		}
		return -1;
	}

	func get_instruction_at_row(_ row: Int) -> UnsafeMutablePointer<KFORTH_IHELP>? {
		var ith_row: Int = 0
		for i in 0 ..< Int(Kforth_Instruction_Help_len) {
			var x = UnsafeMutablePointer<KFORTH_IHELP>(nil)
			x = Kforth_Instruction_Help + i

			var success: Bool = (Int(x!.pointee.mask) & filter) != 0
			if success {
				if ith_row == row {
					return Kforth_Instruction_Help + i
				}

				ith_row += 1
			}
		}
		return nil
	}
    
    func tableView(_ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int) -> NSView? {
     
        guard let cellView = tableView.makeView(withIdentifier:
            NSUserInterfaceItemIdentifier(rawValue: "Instruction"),
            owner: self) as? NSTableCellView
        else {
            return nil
        }

        var s: String
		var x = UnsafeMutablePointer<KFORTH_IHELP>(nil)
		x = get_instruction_at_row(row)

        s = String(format: "%-18s ; %s",
					x!.pointee.instruction,
					x!.pointee.comment )

         cellView.textField?.stringValue = s
        
        return cellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
		/*
        var row = td.selectedRow
        print("selection did change row = \(row)")
		var istr: String
        var s: String

		var x = UnsafeMutablePointer<KFORTH_IHELP>(nil)
		x = get_instruction_at_row(row)

		istr = String(cString: x!.pointee.instruction)
        s = istr + "      ; " + String(cString: x!.pointee.comment)

		insertInstruction = istr
        commentLabel.stringValue = s
        s = String(cString: Kforth_Instruction_Help[row].description)
        descLabel.stringValue = s */
		
		populate_detail_area();
    }
	
	@IBAction func helpBut(_ sender: Any) {
		if td.selectedRow < 0 {
			return;
		}
		var row = td.selectedRow

		var x = UnsafeMutablePointer<KFORTH_IHELP>(nil)
		x = get_instruction_at_row(row)
		var symbol = String(cString: x!.pointee.symbol)
		var file = "ref_" + symbol
		ShowHelp(file)
	}
	
	@IBOutlet var hlp: NSButton!
    @IBOutlet var td: NSTableView!
    @IBOutlet var commentLabel: NSTextField!
    @IBOutlet var descLabel: NSTextField!
	@IBOutlet var usageLabel: NSTextField!
	@IBOutlet var insertBut: NSButton!
	
	var filter: Int = 0
	var wakeup_opcode: String = ""
	
	public var insertInstruction: String = ""
}
