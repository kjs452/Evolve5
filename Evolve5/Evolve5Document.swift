//
//  Document.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 8/31/22.
//

import Cocoa

class Evolve5Document: NSDocument {
	
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
		Swift.print("Evolve5Document is init()ing")
		
		create_a_universe()
		
		if ec == nil {
			Swift.print("EC not initializwed yet")
		}
    }
	
	deinit {
		if u != nil {
			Universe_Delete(u)
		}
	}
	
	convenience init(u: UnsafeMutablePointer<UNIVERSE>) {
		self.init()
		self.u = u
	}

    override class var autosavesInPlace: Bool {
        return false
    }

    override var windowNibName: NSNib.Name? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return NSNib.Name("Evolve5Document")
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
		Swift.print("ofType = \(typeName)")
		let data = Data()

		SetEvolveFileBridgeObject(data)
		Universe_Write_Using_CB(u)
		
        //throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		return GetEvolveFileBridgeObject()
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.
        // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
		Swift.print("ofType = \(typeName) len = \(data.count)")

		SetEvolveFileBridgeObject(data)
		u = Universe_Read_Using_CB()
		if u == nil {
	        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
    }

	//
	// simulate universe, "slower than run". more continious behavior.
	// the way we implement this is to remove the scale checkbox.
	//	
    @IBAction func goBut(_ sender: Any) {
		// KJS TODO remove this button
    }
    
	@IBAction func onceBut(_ sender: Any) {
		var age: Int
		var curr_age: Int

		age = Int( u!.pointee.age )
		curr_age = Int( u!.pointee.age )
		
		while age == curr_age {
			Universe_Simulate(u)
			curr_age = Int( u!.pointee.age )
		}

		populate()
		// KJS See what this does
		//self.updateChangeCount(NSDocument.ChangeType.changeDone)
	}

	//
	// Add a runloop that restarts forever (until stop button pressed).
	// The runloop will execute the number of steps indicated by
	//		self.steps		<--- which is based on speed controls/multiplier checkbox
	//
	// This is the animation for the simulator. It should respond dynamically
	// to changes in 'self.steps' and 'self.stopped'.
	//
	func do_run() {
		if !stopped {
			stopped = true
			populate_idle()
			return
		}

		populate_running()

		let rl = RunLoop.current
		let timeInterval: Double = 0.0001
		var count: Int = 0
		stopped = false
				
		let tm = Timer(timeInterval: timeInterval, repeats: true, block:
						{ (t: Timer) -> Void in
			for _ in 0 ... self.steps {
				if self.stopped {
					t.invalidate()
					break
				}
				Universe_Simulate(self.u)
			}
			self.populate()
			count += 1
		})

		rl.add(tm, forMode: RunLoop.Mode.default)
	}

	//
	// this button is supposed to be bulk simulate, supposed to be choppy
	//	
	@IBAction func runBut(_ sender: Any) {
		Swift.print("RunBut")
		do_run()
	}
	
	@IBAction func stopBut(_ sender: Any) {
		Swift.print("stop but")
		stopped = true
		runButW.state = NSControl.StateValue.off
		populate_idle()
    }
	
    @IBAction func viewAllBut(_ sender: Any) {
        Swift.print("view all but")
		ec.ViewAll()
    }
	
    @IBAction func zoomInBut(_ sender: Any) {
        Swift.print("zoom in but")
		ec.ZoomIn()
    }
	
    @IBAction func zoomOutBut(_ sender: Any) {
        Swift.print("zoom out but")
		ec.ZoomOut()
    }

	@IBAction func speedSlide(_ sender: Any) {
		steps = Int(speedCtrl.intValue)  * ((multCheck.integerValue != 0) ? SCALE : 1)
		Swift.print("Speed Slider steps=\(steps)")
	}
	
	@IBAction func times10(_ sender: Any) {
		steps = Int(speedCtrl.intValue) * ((multCheck.integerValue != 0) ? SCALE : 1)
		Swift.print("Times 10,000: steps=\(steps)")
	}
	
	func create_a_universe() {
		var nuo = NEW_UNIVERSE_OPTIONS()
		var errbuf = Array(repeating: CChar(0), count: 1000)
		
		NewUniverseOptions_Init(&nuo)
		
		nuo.seed = 70422111
		nuo.width = 700
		nuo.height = 400
		nuo.want_barrier = 1
		
		u = CreateUniverse(&nuo, &errbuf)

		if u == nil {
			let str = String(cString: errbuf)
			Swift.print("Universe Create Failed: \(str)")
		} else {
			Swift.print("Universe CREATION Succeeded!!!!!")
		}
	}

	func cursor_changed_cb(_ x: Int, _ y: Int) {
		populate_cursor(x, y)
	}

	override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
		Swift.print("widow Conotroller did load...")
		windowController.contentViewController?.representedObject = u
		if ec != nil {
			Swift.print("ec is not null, can be set")
			ec.doit_universe(u!, cursor_changed_cb)
		}
		populate()
		steps = 1*SCALE
		scale = SCALE
		populate_speed_ctrl()
		populate_right_click_menu()
	}
	
	@IBAction func universeMenu(_ sender: Any) {
		universeDialog = UniverseDialog()
		var fn: String
		if fileURL != nil {
			fn = fileURL!.path
		} else {
			fn = displayName
		}
		universeDialog!.doit(sender, u!, fn)
	}
	
	@IBAction func organismMenu(_ sender: Any) {
		let vod = ViewOrganismDialog()
		if u!.pointee.selected_organism != nil {
			vod.doit(sender, u!, ec!)
		}
	}
	

	@IBAction func findMenu(_ sender: Any) {
		findDialog = FindDialog()
		findDialog!.doit(sender, u!)
		if findDialog!.success {
			self.populate()
		}
	}
	
	@IBAction func clearTracersMenu(_ sender: Any) {
		Universe_ClearTracers(u!)
		self.populate()
	}

	@IBAction func clearMousePos(_ sender: Any) {
		Universe_ClearMouse(u!)
		self.populate()
	}

	func make_profile(_ i: Int) -> STRAIN_PROFILE
	{
		var sp = STRAIN_PROFILE()
		
		sp.strop = Universe_get_ith_strop(u, Int32(i)).pointee
		sp.kfmo = Universe_get_ith_kfmo(u, Int32(i)).pointee
		sp.kfops = Universe_get_ith_kfops(u, Int32(i)).pointee

		var str, bo: String
		// bo = String(cString: &sp.strop.name.0) // KJS testing new recipe
		bo = Cstr0(&sp.strop.name.0, 1000)
		str = "Strain \(i)  \(bo)"
		StrainProfile_Set_Name(&sp, str)
		
		return sp
	}
	
	@IBAction func strainsMenu(_ sender: Any) {
		let scd = StrainCustomizeDialog()
		
		scd.clear_strain_profiles()
		for i in 0..<8 {
			var c: UnsafeMutablePointer<STRAIN_OPTIONS>
			c = Universe_get_ith_strop(u, Int32(i))
			
			if c.pointee.enabled != 0 {
				var sp_item = make_profile(i)
				scd.add_strain_profile(&sp_item)
			}
		}
		
		assert( scd.nsptab.count >= 1 ) // blank universe fails here. KJS: ensure ALL universes  have 1 strain
											// defined
		
		scd.customizeMode = true
		scd.strainPreferences = true
		
		scd.doit(sender)
		
		if scd.success && scd.was_modified {
			var j: Int = 0
			for i in 0 ..< 8 {
				var c: UnsafeMutablePointer<STRAIN_OPTIONS>
				c = Universe_get_ith_strop(u, Int32(i))
				
				if c.pointee.enabled != 0 {
					if scd.modified[j] {
						Universe_set_ith_strop(u, Int32(i), &scd.nsptab[j].pointee.strop)
						Universe_set_ith_kfmo(u, Int32(i), &scd.nsptab[j].pointee.kfmo)
						Universe_update_protections(u,
								Int32(i),
								&scd.nsptab[j].pointee.kfops,
								Int32( scd.nsptab[j].pointee.kfmo.protected_codeblocks ) )
					}
					j += 1
				}
			}
		}
	}
	
	@IBAction func strainPopMenu(_ sender: Any) {
		strainPopulation = StrainPopulation()
		strainPopulation!.doit(sender, u!)
	}
	
	@IBAction func rctClicked(_ sender: Any) {
		Swift.print("rct clicked")
		let p = NSPoint(x: rtcBut!.frame.minX, y: rtcBut!.frame.minY)
		rctMenu.popUp(positioning: rctNone, at: p, in: kjs)
	}
	
	func clear_rct_menu() {
		for i in 1...7 {
			let x = rctMenu.item(withTag: i)
			x!.state = NSControl.StateValue.off
		}
	}

	func populate_rct_menu(_ tag: Int) {
		for i in 1...7 {
			var state: NSControl.StateValue
			if i == tag {
				state = NSControl.StateValue.on
			} else {
				state = NSControl.StateValue.off
			}
			let x = rctMenu.item(withTag: i)
			x!.state = state
		}
	}

	func populate() {
		populate_status_bar()
		ec.needsDisplay = true
	}

	func populate_idle() {
		statStat.stringValue = "Status: " + "Idle"
	}

	func populate_running() {
		statStat.stringValue = "Status: " + "Running"
	}

	func populate_cursor(_ x: Int, _ y: Int) {
		cursorStat.stringValue = "Cursor: " + "(\(x), \(y))"
	}

	func populate_speed_ctrl() {
		// multCheck =  1 or SCALE
		// steps = speedCtrl * multCheck
		// speedCtrl = steps / multCheck

		multCheck.intValue = (scale==SCALE)  ? 1 : 0;
		speedCtrl.intValue = Int32(steps / scale)
	}

	func populate_status_bar() {
		var age: Int64
		var nborn: Int64
		var ndie: Int64
		var norganism: Int32

		age = u!.pointee.age
		nborn = u!.pointee.nborn
		ndie = u!.pointee.ndie
		norganism = u!.pointee.norganism

		bornStat.stringValue = "Born: " + format_comma("\(nborn)")
		dieStat.stringValue = "Die: " + format_comma("\(ndie)")
		ageStat.stringValue = "Age: " + format_comma("\(age)")
		orgStat.stringValue = "Organisms: " + format_comma("\(norganism)")
	}

	func populate_right_click_menu() {
		clear_rct_menu()
	}

	func rtc_to_tag(_ r: RTC) -> Int {
		switch(rtcMode) {
		case RTC.NONE:			return 1
		case RTC.RADIO_ACTIVE:	return 4
		case RTC.SET_MOUSE_POS:	return 7
		case RTC.THICK_BARRIER:	return 2
		case RTC.THIN_BARRIER:	return 3
		case RTC.MOVE_ORGANISM:	return 5
		case RTC.TWEAK_ENERGY:	return 6
		}
	}
	
	func tag_to_rtc(_ t: Int) -> RTC {
		switch(t) {
		case 1: return RTC.NONE
		case 5: return RTC.MOVE_ORGANISM
		case 4: return RTC.RADIO_ACTIVE
		case 2: return RTC.THICK_BARRIER
		case 3: return RTC.THIN_BARRIER
		case 6: return RTC.TWEAK_ENERGY
		case 7: return RTC.SET_MOUSE_POS
		default: assert(false); return RTC.NONE
		}
	}

	@IBAction func rtcMenuItem(_ sender: Any) {
		Swift.print("RTC Menu Item Menu clicked")
		var c: NSMenuItem
		c = sender as! NSMenuItem
		Swift.print("Menu Item Tag IS: \(c.tag)")
		populate_rct_menu(c.tag)
		rtcMode = tag_to_rtc(c.tag)
		ec!.rtcMode = rtcMode
	}
	
	@IBAction func examineBut(_ sender: Any) {
		organismMenu(sender)
	}

	//////////////////////////////////////////////////////////////////////
	//
	// Copy & Past actions
	//
	func free_copied_organism() {
		if CopiedOrganism != nil {
			Universe_FreeOrganismCo(CopiedOrganism)
			CopiedOrganism = nil
		}
	}
	
	@IBAction func pasteBut(_ sender: Any) {
		if CopiedOrganism == nil {
			return
		}

		Universe_PasteOrganismCo(u, CopiedOrganism)
		populate()
	}
	
	@IBAction func copyBut(_ sender: Any) {
		if u!.pointee.selected_organism == nil {
			return
		}

		free_copied_organism()
		CopiedOrganism = Universe_CopyOrganismCo(u)
	}

	@IBAction func cutBut(_ sender: Any) {
		if u!.pointee.selected_organism == nil {
			return
		}

		free_copied_organism()
		CopiedOrganism = Universe_CutOrganismCo(u)
		populate()
	}
	
	@IBAction func delMenu(_ sender: Any) {
		if u!.pointee.selected_organism == nil {
			return
		}
		var x = UnsafeMutablePointer<COPIED_ORGANISM>(nil)

		x = Universe_CutOrganismCo(u)
		Universe_FreeOrganismCo(x)
		populate()
	}
	@IBAction func copy(_ sender: Any) {
		copyBut(sender)
	}
	
	@IBAction func cut(_ sender: Any) {
		cutBut(sender)
	}
	
	@IBAction func paste(_ sender: Any) {
		pasteBut(sender)
	}
	
	@IBAction func delete(_ sender: Any) {
		delMenu(sender)
	}


	@IBAction func saveBut(_ sender: Any) {
		save(sender)
	}
	
	@IBAction func loadBut(_ sender: Any) {
		NSDocumentController.shared.openDocument(sender)
	}
	
	@IBAction func newBut(_ sender: Any) {
		do {
			try NSDocumentController.shared.openUntitledDocumentAndDisplay(true)
		} catch {
			Swift.print("openUntitledDocumentAndDisplay exception")
		}
	}
	
	@IBOutlet var kjs: NSView!
    @IBOutlet var ec: EvolveCanvas!
	@IBOutlet var speedCtrl: NSSliderCell!
	@IBOutlet var multCheck: NSButton!
	@IBOutlet var rctMenu: NSMenu!
	@IBOutlet var rctNone: NSMenuItem!
	@IBOutlet var rtcBut: NSButton!
	@IBOutlet var runButW: NSButton!
	
	@IBOutlet var orgStat: NSTextFieldCell!
	@IBOutlet var bornStat: NSTextFieldCell!
	@IBOutlet var dieStat: NSTextFieldCell!
	@IBOutlet var ageStat: NSTextFieldCell!
	@IBOutlet var cursorStat: NSTextFieldCell!
	@IBOutlet var statStat: NSTextFieldCell!
		
	var u = UnsafeMutablePointer<UNIVERSE>(nil)
	var stopped: Bool = true
	var steps: Int = 0				// this is a number (0 ... 500) times 'scale'
	var scale: Int = 0				// 1 or SCALE or other values
	var universeDialog: UniverseDialog?
	var findDialog: FindDialog?
	var strainPopulation: StrainPopulation?
	// 0=none, 1=thick, 2=thin, 3=radio, 4=move, 5=tweak, 6=mouse-pos
	var rtcMode: RTC = RTC.NONE
	let SCALE: Int = 10_000
}

//
// This global variable holds the COPIED_ORGANISM, these operations will
// manipulate this global.
//
//	Cut		Command-X		Removes organism from universe and sets CopiedOrganism
//	Copy	Command-C		Copies organism from universe and sets CopiedOrganism
//	Paste	Command-V		Insert organism into universe using the CopiedOrganism
//
//
var CopiedOrganism = UnsafeMutablePointer<COPIED_ORGANISM>(nil)
