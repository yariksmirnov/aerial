//
//  Session.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 01/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import ObjectMapper

public class Aerial: NSObject {
    
    private var session = PeerSession()
    
    var device: Device? {
        didSet {
            if device != nil {
                updateSubsystems(withDevice: device!)
            }
        }
    }
    
    public var loggers = [CorkLogger]()
    let container: Container
    
    public override init() {
        container = Container(session: self.session)
        super.init()
        session.delegate = self
    }
    
    public func startSession() {
        session.advertise()
    }
    
    func updateSubsystems(withDevice device: Device) {
        for var logger in loggers {
            logger.socket = device.socket
        }
        container.device = device
    }

    public func updateDebugInfo(_ info: () -> [String: String]) {
        let records = info().map { InspectorRecord(title: $0.key, value: $0.value) }.toJSON()
        device?.socket.send(event: .inspector, withData: records)
    }
}

extension Aerial: PeerSessionDelegate {
    
    func session(_ session: PeerSession, didCreate device: Device) {
        self.device = device
    }
    
    func session(_ session: PeerSession, didLost device: Device) {
        
    }
    
}
