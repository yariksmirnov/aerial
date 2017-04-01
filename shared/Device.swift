//
//  Peer.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 07/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import MultipeerConnectivity
import ObjectMapper
import Dollar

public class Device: NSObject {
    
    var peerID: MCPeerID
    var service: ConnectionService!

    var state: MCSessionState = .notConnected {
        didSet {
            service.state = state
        }
    }
    
    //Cocoa-binding support
    dynamic var children = [Device]()
    dynamic var isLeaf = true
    
    var uuid = UUID().uuidString
    
    var name: String {
        return peerID.displayName
    }

    dynamic var logs = [LogMessage]()
    dynamic var containerTree = [File]()
    
    init(peerID: MCPeerID, session: PeerSession) {
        self.peerID = peerID
        super.init()
        self.service = ConnectionService(session: session, device: self)
        installListeners()
    }
    
    private func installListeners() {
        service.on(.log) { [weak self] data, _ in
            guard let logData = data as? [[String: Any]] else { return }
            if let messages = Mapper<LogMessage>().mapArray(JSONArray: logData) {
                let mLogs = self?.mutableArrayValue(forKeyPath: #keyPath(logs))
                mLogs?.addObjects(from: messages)
            }
        }
        service.on(.containerTree) { [weak self] data, _ in
            guard let treeData = data as? [[String: Any]] else { return }
            if let tree = Mapper<File>().mapArray(JSONArray: treeData) {
                let mTree = self?.mutableArrayValue(forKeyPath: #keyPath(containerTree))
                mTree?.removeAllObjects()
                mTree?.addObjects(from: tree)
                File.printTree(tree: tree)
            }
        }
        service.on(.inspector) { [weak self] data, _ in
            guard let s = self else { return }
            guard let recordsData = data as? [[String: Any]] else { return }
            if let records = Mapper<InspectorRecord>().mapArray(JSONArray: recordsData) {
                var newRecords = records
                var newInfo = s.inspectorInfo
                for record in newInfo {
                    for newRecord in records {
                        if newRecord.title == record.title {
                            record.value = newRecord.value
                             newRecords = $.remove(newRecords, value: newRecord)
                        }
                    }
                }
                newInfo.append(contentsOf: newRecords)
                s.inspectorInfo = newInfo
            }
        }
    }
    
    override public var hashValue: Int {
        return peerID.hashValue
    }

    dynamic var inspectorInfo = [InspectorRecord]()
}

extension Device {
    
    public static func ==(lhs: Device, rhs: Device) -> Bool {
        return lhs.peerID.displayName == rhs.peerID.displayName
    }
    
}

