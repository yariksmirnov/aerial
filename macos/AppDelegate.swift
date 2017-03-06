//
//  AppDelegate.swift
//  Aerial-Mac
//
//  Created by Yaroslav Smirnov on 30/11/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Cocoa
import XCGLogger

let Log: XCGLogger = {
    let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)
    
    // Create a destination for the system console log (via NSLog)
    let systemDestination = ConsoleDestination(identifier: "advancedLogger.systemDestination")
    
    // Optionally set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = false
    systemDestination.showThreadName = false
    systemDestination.showLevel = false
    systemDestination.showFileName = false
    systemDestination.showLineNumber = false
    systemDestination.showDate = false
    
    // Add the destination to the logger
    log.add(destination: systemDestination)
    
    return log
}()

import MASPreferences

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    var prefWindowController: MASPreferencesWindowController!
    
    override open class func initialize() {
        ValueTransformer.setValueTransformer(LogTransformer(),
                                             forName: NSValueTransformerName(rawValue: "LogTransformer"))
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let levels: [LogLevel] = [.fatal, .error, .warning, .info, .debug, .verbose]
        var colorsDefault = [String: Data]()
        for lvl in levels {
            var color = NSColor.black
            switch lvl {
            case .fatal: color = NSColor.orange
            case .error: color = NSColor.red
            case .warning: color = NSColor.yellow
            case .info: color = NSColor.gray
            case .debug: color = NSColor.black
            case .verbose: color = NSColor.lightGray
            default: color = NSColor.black
            }
            let transformer = ValueTransformer(forName: NSValueTransformerName.unarchiveFromDataTransformerName)
            colorsDefault["logs.colors.\(lvl.description.lowercased())"] =
                transformer?.reverseTransformedValue(color) as? Data
        }
        NSUserDefaultsController.shared().initialValues = colorsDefault
        NSUserDefaultsController.shared().revertToInitialValues(nil)
        
        let logsController = NSStoryboard(name: "Preferences", bundle: nil)
            .instantiateController(withIdentifier: "Logs")
        prefWindowController = MASPreferencesWindowController(
            viewControllers: [logsController],
            title: "Preferences"
        )
    }
    
    @IBAction func openPrefereces(_ sender: NSMenuItem) {
        prefWindowController.showWindow(nil)
    }
}

