//
//  utility.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 10/2/22.
//

import Foundation
import SwiftUI

// right click tool modes
enum RTC {
	case NONE
	case RADIO_ACTIVE
	case SET_MOUSE_POS
	case THICK_BARRIER
	case THIN_BARRIER
	case MOVE_ORGANISM
	case TWEAK_ENERGY
}

//
// Scaled to 10,000		2.5%	becomes 250
//
func get_percent_int(_ str: String) -> Int {
	var result = 0
	var decimal = false
	var frac = 1
	for ch in str {
		if ch >= "0" && ch <= "9" {
			result *= 10
			result += Int(ch.asciiValue! - "0".first!.asciiValue!)
			if decimal {
				frac = frac * 10
			}
		}

		if ch == "." {
			decimal = true
		}
	}

	// str			result		frac		answer
	// ----			------		-----		-------
	// 0.07			7			100			7
	// 0.70			70			100			70
	// 7.00			700			100			700
	// 7			7			1			700
	// 70.00		7000		100			result * (100/frac)	= 7000
	// 2.50			250			100			result * (100/frac)	= 250
	// 2.5			25			10			result * (100/frac)	= 250
	// 100.0		1000		10			result * (100/frac)	= 10000
	// 100			100			1			result * (100/frac)	= 10000
	// 100.00		10000		100			result * (100/frac)	= 10000

	return result * (100/frac)
}

//
// Make sure the thing is '4.56' or '4' or '100' or '99.99'
//	but not, '99.999' '99%' 
//	
//
func is_percent_int(_ str: String) -> Bool {
	let trimmedStr = str.trimmingCharacters(in: .whitespaces)
	var digits = 0
	var decimal = 0
	var frac = 0
	for ch in trimmedStr {
		if ch >= "0" && ch <= "9" {
			digits += 1
			if decimal > 0 {
				frac += 1
			}
		} else if ch == "." {
			decimal += 1
		}
	}

	if digits == 0 {
		return false
	}

	if decimal > 1 {
		return false
	}

	if frac > 2 {
		return false
	}

	return decimal + digits == trimmedStr.count
}

//
// format percent field:
//	value / 10000, 2 decimals
//
func format_percent(_ v: String) -> String {
	let percent = get_percent_int(v)
	let result = String(format: "%.2f", (Double(percent) / 10000.0) * 100)
	return result
}

func format_percent_int(_ v: Int) -> String {
	let result = String(format: "%.2f", (Double(v) / 10000.0) * 100)
	return result
}

func is_blank(_ str: String) -> Bool {
	var count = 0
	for ch in str {
		if ch == " " || ch == "\t" {
			count += 1
		}
	}
	return str.count == count
}

func get_comma_int(_ str: String) -> Int {
	var result: Int
	var neg = 1

	result = 0
	for ch in str {
		if ch >= "0" && ch <= "9" {
			result *= 10
			result += Int(ch.asciiValue! - "0".first!.asciiValue!)
		} else if ch == "-" {
			neg = -1;
		}
	}
	return neg * result
}

func is_comma_int(_ str: String) -> Bool {
	let trimmedStr = str.trimmingCharacters(in: .whitespaces)

	var commas = 0
	var digits = 0
	var minus = 0
	var i = 0
	for ch in trimmedStr {
		if ch >= "0" && ch <= "9" {
			digits += 1
		} else if ch == "," {
			commas += 1
		} else if ch == "-" {
			if i != 0 {
				return false
			}
			minus += 1
		}
		i += 1
	}
	if digits == 0 {
		return false
	}

	if minus > 1 {
		return false
	}

	return minus + digits + commas == trimmedStr.count
}

//
// reformat a 'str' which may already have comma's in them
// into a nice clean version with commas in the right place
//
func format_comma(_ str: String) -> String {
	var result = ""
	var count = 0
	for ch in str.reversed() {
		if ch == "," {
			continue
		}

		if ch == "-" {
			if result.first == "," {
				result.remove(at: result.startIndex)
			}
		}

		result = String(ch) + result
		if ch >= "0" && ch <= "9" {
			count = count + 1
		}

		if count == 3 {
			result = "," + result
			count = 0
		}

	}
	if result.first == "," {
		result.remove(at: result.startIndex)
	}
	return result
}


// *****************************************************************

func load_preferences(_ ep: UnsafeMutablePointer<EVOLVE_PREFERENCES>) -> Bool {
	var errbuf = Array(repeating: CChar(0), count: 1000)
	  var success: Int32
	  let fn = HomeDirectory() + "/.evolve5rc"
	  success = EvolvePreferences_Load_Or_Create_From_Scratch(ep, fn, &errbuf)
	  if success == 0 {
		  let str = String(cString: errbuf)
		  print("Unable to read prefs: \(str)\n")
		  return false
	  }
	
	  return true
  }
  
  func save_preferences(_ ep: UnsafeMutablePointer<EVOLVE_PREFERENCES>) {
	  var errbuf = Array(repeating: CChar(0), count: 1000)
	  var success: Int32
	  let fn = HomeDirectory() + "/.evolve5rc"

	  success = EvolvePreferences_Write(ep, fn, &errbuf)
	  if success == 0 {
		  let str = String(cString: errbuf)
		  print("Unable to write prefs: \(str)\n")
	  }
  }

//
// This global variable is set when the app starts. it
// is set to the subdirectory "data" located in the applications folder.
//
var g_DataPath: String = ""

//
// This global variable is set when the application begins. points
// to the locally installed .html help files
//
var g_HelpPath: String = ""

func ShowHelp(_ label: String) {
	let full = "file:" + g_HelpPath + "/" + label + ".html"
	
	let url =  URL(string: full)
	NSWorkspace.shared.open(url!)
}

func ShowUrl(_ url: String) {
	let full = "http://" + url
	
	let url =  URL(string: full)
	NSWorkspace.shared.open(url!)

}

//////////////////////////////////////////////////////////////////////
//
// The OPT class is kinda usefule. It holds widget fields and
// tag numbers with other properties.
//
//

//
// This class links the model fields to the UI controls
//
class OPT {
	init(	c: NSTextField,
			help: String,
			type: Int,
			low: Int,
			high: Int ) {
		self.c = c
		self.help = help
		self.modified = false
		self.type = type
		self.low = low
		self.high = high
	}

	func read(_ value: inout Int32) {
		if type == 0 {
			value = Int32( get_comma_int(c.stringValue) )
 		} else if type == 1 {
			value = Int32( get_percent_int(c.stringValue) )
		} else if type == 2 {
			// not valid operation for string
			assert(false)
		}
	}

	func read_str(_ value: inout String) {
		value = c.stringValue
	}

	func populate(_ value: Int32) {
		if type == 0 {
			c.stringValue = format_comma("\(value)")
		} else if type == 1 {
			c.stringValue = format_percent_int(Int(value))
		} else if type == 2 {
			c.stringValue = "\(value)"
		}
	}

	func populate_str(_ value: String) {
		if type == 0 {
			c.stringValue = format_comma(value)
		} else if type == 1 {
			c.stringValue = format_percent(value)
		} else if type == 2 {
			c.stringValue = value
		}
	}

	func validate(_ val: String) -> (Bool, String) {
		if type == 0 {
			if is_blank(val) {
				let err = String(help + ": cannot be blank. Valid range is \(low) to \(high)")
				return (false, err)
			}

			if !is_comma_int(val) {
				let err = String(help + ": '\(val)' invalid integer format. Valid range is \(low) to \(high)")
				return (false, err)
			}

			let v = get_comma_int(val)

			if v < low {
				let err = String(help + ": \(v) too small. Valid range is \(low) to \(high)")
				return (false, err)
			}

			if v > high {
				let err = String(help + ": \(v) too big. Valid range is \(low) to \(high)")
				return (false, err)
			}

 		} else if type == 1 {
			if is_blank(val) {
				let err = String(help + ": cannot be blank. Valid range is 0 to 100")
				return (false, err)
			}

			if !is_percent_int(val) {
				let err = String(help + ": '\(val)' invalid percent format. Valid input is 0.00 to 100.00")
				return (false, err)
			}

			let v = get_percent_int(val)

			if v < 0 {
				let err = String(help + ": \(v) too small. Valid range is 0 to 100")
				return (false, err)
			}

			if v > 10000 {
				let dv = Double(v) / 100.0
				let fv = format_percent( "\(dv)" )
				let err = String(help + ": \(fv) too big. Valid range is 0 to 100")
				return (false, err)
			}

		} else if type == 2 {
			// string field, easy
			return (true, "")
		}
		
		return (true, "")
	}

	var c: NSTextField
	var help: String = ""
	var modified: Bool = false
	var type: Int = 0		// 0-int, 1-percent, 2-filename
	var low: Int = 0
	var high: Int = 0
}

// munge 'now' time and return that
func generate_seed() -> Int32 {
	let a = NSDate()
	let b = a.timeIntervalSince1970
	let c = Int64(b)
	var d = String(c)
	d.remove(at: d.startIndex)
	let e = d.reversed()
	let f = String(e)
	let g = NSString(string: f).intValue

	return g
}

let strainColor: Array<NSColor> = [
	NSColor(red: 1.0, green: 1.0,   blue: 0.0,   alpha: 1.0), // yellow
	NSColor(red: 0.5, green: 0.5,   blue: 0.0,   alpha: 1.0), // olive
	NSColor(red: 0.0, green: 0.0,   blue: 1.0,   alpha: 1.0), // dark blue
	NSColor(red: 1.0, green: 0.0,   blue: 1.0,   alpha: 1.0), // purple
	NSColor(red: 1.0, green: 0.5,   blue: 0.0,   alpha: 1.0), // orange
	NSColor(red: 1.0, green: 0.529, blue: 0.529, alpha: 1.0), // pink
	NSColor(red: 0.0, green: 0.752, blue: 0.0,   alpha: 1.0), // green
	NSColor(red: 0.5, green: 0.5,   blue: 0.5,   alpha: 1.0) // grey
]

// opacity
let strainColor2: Array<NSColor> = [
	NSColor(red: 1.0, green: 1.0,   blue: 0.0,   alpha: 0.3), // yellow
	NSColor(red: 0.5, green: 0.5,   blue: 0.0,   alpha: 0.3), // olive
	NSColor(red: 0.0, green: 0.0,   blue: 1.0,   alpha: 0.3), // dark blue
	NSColor(red: 1.0, green: 0.0,   blue: 1.0,   alpha: 0.3), // purple
	NSColor(red: 1.0, green: 0.5,   blue: 0.0,   alpha: 0.3), // orange
	NSColor(red: 1.0, green: 0.529, blue: 0.529, alpha: 0.3), // pink
	NSColor(red: 0.0, green: 0.752, blue: 0.0,   alpha: 0.3), // green
	NSColor(red: 0.5, green: 0.5,   blue: 0.5,   alpha: 0.3) // grey
]

//
// sort instructions list by sort mode
//
struct SortOrder {
	public enum ORDER { case NATURAL; case ALPHA; case PROTFIRST; case PROTLAST; }
	public var order = ORDER.PROTFIRST

	mutating func next_instr() {
		switch order {
		case ORDER.NATURAL:	order = ORDER.ALPHA
		case ORDER.ALPHA:		order = ORDER.NATURAL
		case ORDER.PROTFIRST:	order = ORDER.NATURAL
		case ORDER.PROTLAST:	order = ORDER.NATURAL
		}
	}

	mutating func next_protected() {
		switch order {
		case ORDER.NATURAL:	order = ORDER.PROTFIRST
		case ORDER.ALPHA:		order = ORDER.PROTFIRST
		case ORDER.PROTFIRST:	order = ORDER.PROTLAST
		case ORDER.PROTLAST:	order = ORDER.PROTFIRST
		}
	}

	func debugstr() -> String {
		switch order {
		case ORDER.NATURAL:		return "natural"
		case ORDER.ALPHA:		return "alpha"
		case ORDER.PROTFIRST:	return "protfirst"
		case ORDER.PROTLAST:	return "protlast"
		}
	}
}

typealias Instruction = (String, Int, Bool)

func sort_instruction_table(_ instructionTable: inout Array<Instruction>, _ s: SortOrder)
{
	func cmp_natural(_ a: Instruction, _ b: Instruction) -> Bool {
		return a.1 < b.1
	}

	func cmp_alpha(_ a: Instruction, _ b: Instruction) -> Bool {
		return a.0.caseInsensitiveCompare(b.0).rawValue < 0
		//return a.0.localizedCaseInsensitiveCompare(b.0).rawValue < 0
	}

	func cmp_protfirst(_ a: Instruction, _ b: Instruction) -> Bool {
			if a.2 == b.2 {
				return cmp_natural(a, b)
			}
			return a.2
	}

	func cmp_protlast(_ a: Instruction, _ b: Instruction) -> Bool {
			if a.2 == b.2 {
				return cmp_natural(a, b)
			}
			return b.2
	}

	var cmp: (_: Instruction, _: Instruction) -> Bool

	switch s.order {
	case SortOrder.ORDER.NATURAL:		cmp = cmp_natural
	case SortOrder.ORDER.ALPHA:			cmp = cmp_alpha
	case SortOrder.ORDER.PROTFIRST:		cmp = cmp_protfirst
	case SortOrder.ORDER.PROTLAST:		cmp = cmp_protlast
	}

	instructionTable.sort(by: cmp)
}

func read_file(_ fileURL: URL) -> (String, String) {
	var inString = ""
	var errorString = ""

	do {
	    inString = try String(contentsOf: fileURL)
	} catch {
	    errorString = "Failed reading: \(fileURL), Error: " + error.localizedDescription
	}
	print("Read from the file: \(inString)")
	return (inString, errorString)
}

func write_file(_ fileURL: URL, _ str: String) {
	do {
		try str.write(to: fileURL, atomically: false, encoding: .ascii)
	} catch(_) {
		assertionFailure("Failed writing to URL: \(fileURL)")
	}
}

func str_is_call(_ opname: String) -> Bool {
	return opname == "call"
				|| opname == "if"
				|| opname == "ifelse"
				|| opname == "TRAP1"
				|| opname == "TRAP2"
				|| opname == "TRAP3"
				|| opname == "TRAP4"
				|| opname == "TRAP5"
				|| opname == "TRAP6"
				|| opname == "TRAP7"
				|| opname == "TRAP8"
				|| opname == "TRAP9"
}

func str_is_write(_ opname: String) -> Bool {
	return opname == "NUMBER!"
				|| opname == "?NUMBER!"
				|| opname == "OPCODE!"
}


//
// Take a fixed width string from the C world and return
// a string constructed from each char.
// replaced this pattern:
//
// bo = String(cString: &sp.strop.name.0) // KJS testing new recipe
//
// this is needed when the a fixed width string from c needs to
// be converted to a cstring.
//
func Cstr0(_ ptr: UnsafeMutablePointer<CChar>, _ len: Int) -> String {
	var result = ""
	for j in 0 ..< len {
		let ch = ptr[j]
		if ch == 0 { break }
		result.append( String( UnicodeScalar(UInt8(ch))) )
	}
	return result
}

func HomeDirectory() -> String {
	return NSHomeDirectory()
}

func ApplicationDirectory() -> String {
	let x = Bundle.main.resourceURL
	return x!.absoluteURL.path
}

//
// This global variable contains all the Find Searches used during
// the execution of the simulator.
//
var g_FindExpressions: [String] = [
   "NUM-CELLS 10 =",
   "AGE 1000 <",
	"1 EXECUTING"
]
