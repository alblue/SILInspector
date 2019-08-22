//
//  AppDelegate.swift
//  SILInspector
//
//  Created by Alex Blewitt on 21/11/2015.
//  Copyright © 2015 Bandlem Ltd. All rights reserved.
//
import Foundation
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTabViewDelegate {

	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var tabView: NSTabView!
	@IBOutlet weak var programText: NSTextField!

	@IBOutlet weak var sourceView: NSScrollView!
	@IBOutlet weak var silView: NSScrollView!
	@IBOutlet weak var canonicalView: NSScrollView!
	@IBOutlet weak var asmView: NSScrollView!
	@IBOutlet weak var irView: NSScrollView!
	@IBOutlet weak var astView: NSScrollView!
	@IBOutlet weak var parseView: NSScrollView!
	
	var demangle = false
	var optimize = false
	var moduleOptimize = false
	var parseAsLibrary = false

	@IBAction
	func changeFontSize(_ sender:NSSlider) {
		setFontSize(sender.integerValue)
	}

	@IBAction
	func demangle(_ sender:NSButton) {
        demangle = sender.state != NSControl.StateValue.off
		// cause a redraw
		tabView(tabView, willSelect: tabView.selectedTabViewItem)
	}

	@IBAction
	func parseAsLibrary(_ sender:NSButton) {
		parseAsLibrary = sender.state != NSControl.StateValue.off
		// cause a redraw
		tabView(tabView, willSelect: tabView.selectedTabViewItem)
	}

	@IBAction
	func optimize(_ sender:NSButton) {
		optimize = sender.state != NSControl.StateValue.off
		// cause a redraw
		tabView(tabView, willSelect: tabView.selectedTabViewItem)
	}

	@IBAction
	func moduleOptimize(_ sender:NSButton) {
		moduleOptimize = sender.state != NSControl.StateValue.off
		// cause a redraw
		tabView(tabView, willSelect: tabView.selectedTabViewItem)
	}
	
	func setFontSize(_ size:Int) {
		let font = NSFontManager.shared.font(withFamily: "Monaco", traits: .unboldFontMask , weight: 0, size: CGFloat(size))
		for scrollView in [sourceView, astView, parseView, silView, canonicalView, irView, asmView] {
			let textView = scrollView?.documentView as! NSTextView
			textView.font = font
		}
	}
	var source:String {
		get {
			return (sourceView.documentView as! NSTextView).string
		}
		set {
			(sourceView.documentView as! NSTextView).string = newValue
		}
	}
	var sil:String {
		get {
			return (silView.documentView as! NSTextView).string
		}
		set {
			(silView.documentView as! NSTextView).string = newValue
		}
	}
	var canonical:String {
		get {
			return (canonicalView.documentView as! NSTextView).string
		}
		set {
			(canonicalView.documentView as! NSTextView).string = newValue
		}
	}
	var parse:String {
		get {
			return (parseView.documentView as! NSTextView).string
		}
		set {
			(parseView.documentView as! NSTextView).string = newValue
		}
	}
	var ast:String {
		get {
			return (astView.documentView as! NSTextView).string
		}
		set {
			(astView.documentView as! NSTextView).string = newValue
		}
	}
	var asm:String {
		get {
			return (asmView.documentView as! NSTextView).string
		}
		set {
			(asmView.documentView as! NSTextView).string = newValue
		}
	}
	var ir:String {
		get {
			return (irView.documentView as! NSTextView).string
		}
		set {
			(irView.documentView as! NSTextView).string = newValue
		}
	}
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		setFontSize(18)
		let textView = sourceView.documentView as! NSTextView
		textView.isAutomaticQuoteSubstitutionEnabled = false
		textView.isAutomaticDashSubstitutionEnabled = false
		textView.isAutomaticTextReplacementEnabled = false
		textView.isAutomaticSpellingCorrectionEnabled = false
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
		let title = tabViewItem?.label
		switch title {
		case .some("SIL Raw"):
			updateSIL()
		case .some("SIL Canonical"):
			updateCanonical()
		case .some("AST"):
			updateAST()
		case .some("Parse"):
			updateParse()
		case .some("IR"):
			updateIR()
		case .some("Assembly"):
			updateAsm()
		default:
			programText.stringValue = ""
		}
	}
	func updateSIL() {
		sil = runProgram("swiftc - -emit-silgen")
	}
	func updateCanonical() {
		canonical = runProgram("swiftc - -emit-sil")
	}
	func updateAST() {
		ast = runProgram("swiftc - -dump-ast")
	}
	func updateParse() {
		parse = runProgram("swiftc - -dump-parse")
	}
	func updateIR() {
		ir = runProgram("swiftc - -emit-ir")
	}
	func updateAsm() {
		asm = runProgram("swiftc - -emit-assembly")
	}

	func withParseAsLibrary(_ program:String) -> String {
		return parseAsLibrary ? program + " -parse-as-library -module-name SILInspector" : program
	}
	func withOptimize(_ program:String) -> String {
		return optimize ? program + " -O" : program
	}
	func withModuleOptimize(_ program:String) -> String {
		return moduleOptimize ? program + " -whole-module-optimization" : program
	}
	func withDemangle(_ program:String) -> String {
		return demangle ? program + " | xcrun swift-demangle" : program
	}
	
	func runProgram(_ program:String) -> String {
		let toRun = withDemangle(withOptimize(withModuleOptimize(withParseAsLibrary(program))))
		programText.stringValue = toRun
		let inputPipe = Pipe()
		let inputFile = inputPipe.fileHandleForWriting
		inputFile.write(source.data(using: .utf8)!)
		inputFile.closeFile()
		let task = Process()
		task.launchPath = "/bin/bash"
		task.arguments = [ "-c", toRun]
		let errorPipe = Pipe()
		let outputPipe = Pipe()
		task.standardInput = inputPipe
		task.standardOutput = outputPipe
		task.standardError = errorPipe
		task.launch()
		let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
		let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
		let output = String(data: outputData, encoding: .utf8)!
		let error = String(data: errorData, encoding: .utf8)!
		return error == "" || error == "\n" ? output : error
	}
//	var fontSize: Int {
//		set {
//			print("Setting font size to \(newValue)")
//		}
//	}
}

