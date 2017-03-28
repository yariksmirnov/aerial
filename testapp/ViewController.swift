//
//  ViewController.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 30/11/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import XCGLogger

class ViewController: UIViewController {
    
    var timer: Timer?
    var aerial: Aerial?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = Timer(timeInterval: 2, target: self, selector: #selector(startLogging), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)


    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        aerial?.updateDebugInfo {
            ["APNS Token" : UUID().uuidString,
             "User Token" : UUID().uuidString,
             "Account ID" : "KZJDIWNO",
             "Access Token": UUID().uuidString,
             "Account" : [
                "Name" : "Enterprise Wrike",
                "ID" : "KSDIDKD",
                "Role" : "Collaborator"
                ]
            ]
        }
    }
    
    func startLogging() {
        TestLog.error("Error!!!: Something serious has failed with error")
        TestLog.warning("I must warn you. If you have not written unit test for this - it gonna be bullshit.")
        TestLog.info("Log messages have to contain usefull and clear information.")
        TestLog.debug("All of my variables are nil.")
        TestLog.verbose("Call this method, then that..")

        aerial?.updateDebugInfo {
            ["APNS Token" : UUID().uuidString,
             "User Token" : UUID().uuidString,
             "Account ID" : "KZJDIWNO",
             "Access Token": UUID().uuidString,
             "Account" : [
                "Name" : "Enterprise Wrike",
                "ID" : "KSDIDKD",
                "Role" : "Collaborator"
                ]
            ]
        }
    }
}



