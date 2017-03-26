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
    let debugger = Aerial()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
        -> Bool
    {

        Logger.level = .verbose

        debugger.loggers.append(corkDest)
        debugger.startSession()
        
        return true
    }

}

