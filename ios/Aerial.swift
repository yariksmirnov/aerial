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
import Dollar

public class Aerial: NSObject {
    
    private var session = PeerSession()
    
    var device: Device? {
        didSet {
            if let _ = device {
                updateSubsystems()
            }
        }
    }
    
    public var loggers = [CorkLogger]()
    var container: Container?
    
    public override init() {
        super.init()
        session.delegate = self
    }
    
    public func startSession() {
        session.advertise()
    }
    
    func updateSubsystems() {
        for var logger in loggers {
            logger.device = device
        }
        container = Container(device: device!)
        sendDebugInfo()
    }

    private var inspectorInfo = [String: Any]()

    public func updateDebugInfo(_ info: () -> [String: Any]) {
        inspectorInfo = $.merge(inspectorInfo, info())
        sendDebugInfo()
    }

    private func sendDebugInfo() {
        let records = inspectorInfo.map { InspectorRecord(title: $0.key, value: $0.value) }.toJSON()
        device?.service.send(event: .inspector, withData: records)
    }
}

extension Aerial: PeerSessionDelegate {
    
    func session(_ session: PeerSession, didCreate device: Device) {
        self.device = device
    }
    
    func session(_ session: PeerSession, didLost device: Device) {
        
    }
    
}
