//
//  LogsPrefController.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 23/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Cocoa
import MASPreferences

class LogsPrefController: NSViewController, MASPreferencesViewController {

    var toolbarItemLabel: String! {
        return "General"
    }
    
    var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNamePreferencesGeneral)
    }
    
    override var identifier: String? {
        get {
            return "logs"
        }
        set {
            super.identifier = newValue
        }
    }
}
