//
//  Session.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 01/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class Debugger: NSObject {
    
    private var session = PeerSession()
    
    var device: Device? {
        didSet {
            if device != nil {
                updateSubsystems(withDevice: device!)
            }
        }
    }
    
    var loggers = [CorkLogger]()
    let container: Container
    
    override init() {
        container = Container(session: self.session)
        super.init()
        session.delegate = self
    }
    
    func startSession() {
        session.advertise()
    }
    
    func updateSubsystems(withDevice device: Device) {
        for var logger in loggers {
            logger.socket = device.socket
        }
        container.device = device
    }
}

extension Debugger: PeerSessionDelegate {
    
    func session(_ session: PeerSession, didCreate device: Device) {
        self.device = device
    }
    
    func session(_ session: PeerSession, didLost device: Device) {
        
    }
    
}
