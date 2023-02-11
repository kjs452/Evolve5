//
//  TweakView.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 2/6/23.
//

import Cocoa
import CoreGraphics

class TweakView: NSView {
	
	@IBOutlet var contentView: NSView!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		print("Init Code Tweak View")
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		print("Init Frame Tweak View")
		setup()
	}
	
	@IBAction func OkBut(_ sender: Any) {
		print("OKBUT TWEAK VIEW")
		var ok: Bool = false
		var e: Int32 = 0
		
		removeFromSuperview()
		if is_comma_int(tweakTxt.stringValue) {
			e = Int32( get_comma_int(tweakTxt.stringValue) )
			if e >= 1 && e <= 100_000 {
				ok = true
			}
		}
		
		if !ok {
			NSSound.beep()
		}
		
		dismissedCB(e, ok)
	}
	
	@IBOutlet var tweakTxt: NSTextField!
	
	func setup() {
		let newNib = NSNib(nibNamed: "TweakView", bundle: Bundle(for: type(of: self)))
		newNib!.instantiate(withOwner: self, topLevelObjects: nil)
		canDrawSubviewsIntoLayer = true
		addSubview(contentView)
	}
	
	//
	// caller will call this on initial creation
	// The callback 'cb' will be called when the pop up is being dismissed
	//
	func do_it(_ energy: String, _ cb: @escaping (Int32, Bool) -> Void) {
		tweakTxt.stringValue = energy
		dismissedCB = cb
		tweakTxt.becomeFirstResponder()
//		tweakTxt.selectAll(self)
	}
	
	//
	// called by the client to make this view go away without
	// doing anything
	//
	func go_away() {
		print("Go Away tweak view")
		removeFromSuperview()
		dismissedCB(0, false)
	}
	
	var dismissedCB: (Int32, Bool) -> Void = do_nothing
}

fileprivate func do_nothing(_ e: Int32, _ ok: Bool) {
}

