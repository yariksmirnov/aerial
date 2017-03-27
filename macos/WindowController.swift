//
//  WindowController.swift
//  Aerial-Mac
//
//  Created by Yaroslav Smirnov on 01/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.title = "Halfpipe"

        if let screenRect = window?.screen?.frame {
            window?.setContentSize(NSSize(width: screenRect.size.width*0.6, height: screenRect.size.width*0.6))
        }
        
    }

}
