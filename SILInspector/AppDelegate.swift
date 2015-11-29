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
	
	var demangle = false;
	var optimize = false;
	var moduleOptimize = false;

	@IBAction
	func changeFontSize(sender:NSSlider) {
		setFontSize(sender.integerValue)
	}

	@IBAction
	func demangle(sender:NSButton) {
		demangle = sender.state != 0
		// cause a redraw
		tabView(tabView, willSelectTabViewItem: tabView.selectedTabViewItem)
	}

	@IBAction
	func optimize(sender:NSButton) {
		optimize = sender.state != 0
		// cause a redraw
		tabView(tabView, willSelectTabViewItem: tabView.selectedTabViewItem)
	}

	@IBAction
	func moduleOptimize(sender:NSButton) {
		moduleOptimize = sender.state != 0
		// cause a redraw
		tabView(tabView, willSelectTabViewItem: tabView.selectedTabViewItem)
	}
	
	func setFontSize(size:Int) {
		let font = NSFontManager.sharedFontManager().fontWithFamily("Monaco", traits: .UnboldFontMask , weight: 0, size: CGFloat(size))
		for scrollView in [sourceView, astView, parseView, silView, canonicalView, irView, asmView] {
			let textView = scrollView.documentView as! NSTextView
			textView.font = font
		}
	}
	var source:String {
		get {
			return (sourceView.documentView as! NSTextView).string!
		}
		set {
			(sourceView.documentView as! NSTextView).string = newValue
		}
	}
	var sil:String {
		get {
			return (silView.documentView as! NSTextView).string!
		}
		set {
			(silView.documentView as! NSTextView).string = newValue
		}
	}
	var canonical:String {
		get {
			return (canonicalView.documentView as! NSTextView).string!
		}
		set {
			(canonicalView.documentView as! NSTextView).string = newValue
		}
	}
	var parse:String {
		get {
			return (parseView.documentView as! NSTextView).string!
		}
		set {
			(parseView.documentView as! NSTextView).string = newValue
		}
	}
	var ast:String {
		get {
			return (astView.documentView as! NSTextView).string!
		}
		set {
			(astView.documentView as! NSTextView).string = newValue
		}
	}
	var asm:String {
		get {
			return (asmView.documentView as! NSTextView).string!
		}
		set {
			(asmView.documentView as! NSTextView).string = newValue
		}
	}
	var ir:String {
		get {
			return (irView.documentView as! NSTextView).string!
		}
		set {
			(irView.documentView as! NSTextView).string = newValue
		}
	}
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		setFontSize(36)
		let textView = sourceView.documentView as! NSTextView
		textView.automaticQuoteSubstitutionEnabled = false
		textView.automaticDashSubstitutionEnabled = false
		textView.automaticTextReplacementEnabled = false
		textView.automaticSpellingCorrectionEnabled = false
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	func tabView(tabView: NSTabView, willSelectTabViewItem tabViewItem: NSTabViewItem?) {
		let title = tabViewItem?.label
		switch(title) {
		case .Some("SIL"):
			updateSIL()
		case .Some("Canonical"):
			updateCanonical()
		case .Some("AST"):
			updateAST()
		case .Some("Parse"):
			updateParse()
		case .Some("IR"):
			updateIR()
		case .Some("Assembly"):
			updateAsm()
		default:
			programText.stringValue = ""
			break
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

	func withOptimize(program:String) -> String {
		return optimize ? program + " -O" : program
	}
	func withModuleOptimize(program:String) -> String {
		return moduleOptimize ? program + " -whole-module-optimization" : program
	}
	func withDemangle(program:String) -> String {
		return demangle ? program + " | xcrun swift-demangle" : program
	}
	
	func runProgram(program:String) -> String {
		let toRun = withDemangle(withOptimize(withModuleOptimize(program)))
		programText.stringValue = toRun
		let inputPipe = NSPipe()
		let inputFile = inputPipe.fileHandleForWriting
		inputFile.writeData(source.dataUsingEncoding(NSUTF8StringEncoding)!)
		inputFile.closeFile()
		let task = NSTask()
		task.launchPath = "/bin/bash"
		task.arguments = [ "-c", toRun]
		let errorPipe = NSPipe()
		let outputPipe = NSPipe()
		task.standardInput = inputPipe
		task.standardOutput = outputPipe
		task.standardError = errorPipe
		task.launch()
		let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
		let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
		let output = NSString(data: outputData, encoding: NSUTF8StringEncoding) as! String
		let error =  NSString(data: errorData, encoding: NSUTF8StringEncoding) as! String
		return error == "" ? output : error
	}
//	var fontSize: Int {
//		set {
//			print("Setting font size to \(newValue)")
//		}
//	}
}

