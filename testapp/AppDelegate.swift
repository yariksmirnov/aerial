//
//  AppDelegate.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 30/11/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import UIKit
import CocoaLumberjack
import XCGLogger

let Logger: XCGLogger = {
    let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)
    
    // Create a destination for the system console log (via NSLog)
    let systemDestination = ConsoleDestination(identifier: "advancedLogger.systemDestination")
    
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

let corkDest = CorkDestination(identifier: "cork")

let TestLog: XCGLogger = {
    let log = XCGLogger(identifier: "testlogger", includeDefaultDestinations: false)

    // Create a destination for the system console log (via NSLog)

    corkDest.outputLevel = .debug
    corkDest.showLogIdentifier = false
    corkDest.showFunctionName = false
    corkDest.showThreadName = false
    corkDest.showLevel = false
    corkDest.showFileName = false
    corkDest.showLineNumber = false
    corkDest.showDate = false

    // Add the destination to the logger
    log.add(destination: corkDest)

    return log
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let debugger = Debugger()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
        -> Bool
    {

        debugger.externalLogger = Logger
        debugger.loggers.append(corkDest)
        debugger.startSession()
        
        return true
    }

}

extension XCGLogger: Logging {
    public func error(_ msg: String) {
        error(msg, userInfo: [:])
    }
    public func warn(_ msg: String) {
        warning(msg, userInfo: [:])
    }
    public func info(_ msg: String) {
        info(msg, userInfo: [:])
    }
    public func debug(_ msg: String) {
        debug(msg, userInfo: [:])
    }
    public func verbose(_ msg: String) {
        verbose(msg, userInfo: [:])
    }
}

