//
//  AppDelegate.swift
//  Evolve5
//
//  Created by Kenneth Stauffer on 8/31/22.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	
	override init() {
		print("Here init APP DELEGATE")
		super.init()
	}
		
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}
		
	override func awakeFromNib() {
		print("Awake From Nib")
		
		let yyy = Bundle.main.resourcePath! + "/help"
		g_HelpPath = yyy
		
		let xxx = Bundle.main.resourcePath! + "/ev5stuff"
		g_DataPath = xxx

		let f: Bool
		ep = EvolvePreferences_Make()

		f = load_preferences(ep!)
		if( f ) {
			save_preferences(ep!)  // KJS TODO - review if this makes sense to do
//			g_HelpPath = String(cString: &ep!.pointee.help_path.0) // KJS testing recipe
//			g_HelpPath = Cstr0( &ep!.pointee.help_path.0, 1000)
			//g_HelpPath = String(bytes: &ep!.pointee.help_path.0, encoding: String.Encoding.ascii)
//			g_HelpPath = ApplicationDirectory() + "/evolve5"
		}
		UserDefaults.standard.set(true, forKey: "NSDisabledDictationMenuItem")
		UserDefaults.standard.set(true, forKey: "NSDisabledCharacterPaletteMenuItem")
		
		// remove Search in the help menu
		let unusedMenu = NSMenu(title: "Unused")
		NSApplication.shared.helpMenu = unusedMenu
		// NSApplication.shared.delegate = self // Shouldn't need to do this.
		// EXPERIMENTAL_MAIN()
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
		print("Applicatiop will terminate")
	}
	
	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		print("A S S R S")
		return false
	}
	
	func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
		print("should open untitled file")
		return false
	}
	
	func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
		print("applicaton open untitlte dfile is called")
		return false
	}

	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
		print("should handle reopen")
		return false
	}
		
	@IBAction func launchKforthInterpreter(_ sender: Any) {
		print("Here Kforth Launch Interpreter")
		kid = KforthInterpreter()
		kid!.doit(sender)
	}
	
	@IBAction func aboutMenu(_ sender: Any) {
		print("about menu")
		ad = AboutDialog()
		ad!.doit(sender)
	}
		
	@IBAction func newMenu(_ sender: Any) {
		let nud = NewUniverseDialog()
		nud.doit(self, ep!)
		print("After modal doit\n")
		if !nud.success {
			return
		}
		let doc = Evolve5Document(u: nud.u!)
		nud.u = nil
		NSDocumentController.shared.addDocument(doc)
		doc.makeWindowControllers()
		doc.showWindows()
	}
	
	@IBAction func preferencesMenu(_ sender: Any) {
		let scd = StrainCustomizeDialog()
		scd.customizeMode = false
		scd.clear_strain_profiles()
		for i in 0 ..< Int(ep!.pointee.nprofiles) {
			scd.add_strain_profile( &ep!.pointee.strain_profiles[i] )
		}
		scd.sp_idx = 0
		scd.doit(sender)
		
		if scd.success && scd.was_modified {
			if ep != nil {
				EvolvePreferences_Clear_StrainProfiles(ep)
			}
			
			for i in 0 ..< scd.nsptab.count {
				EvolvePreferences_Add_StrainProfile(ep, &scd.nsptab[i].pointee)
			}
		}
		
		save_preferences(ep!)
	}
	
	@IBAction func zoomOut(_ sender: Any) {
	}
	
	@IBAction func helpContentsMenu(_ sender: Any) {
		ShowHelp("contents")
	}
	
	@IBAction func helpKforthMenu(_ sender: Any) {
		ShowHelp("kforth_reference")
	}
	
	@IBAction func helpOrganismMenu(_ sender: Any) {
		ShowHelp("organism_reference")
	}
	
	var kid: KforthInterpreter?
	var ad: AboutDialog?
	var xxy: Int = 666
	var ep = UnsafeMutablePointer<EVOLVE_PREFERENCES>(nil)
}

