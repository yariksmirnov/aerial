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

class Device: NSObject {
    
    var peerID: MCPeerID
    var input: InputStream? {
        didSet {
            tryConfigureSocket()
        }
    }
    var output: OutputStream? {
        didSet {
            tryConfigureSocket()
        }
    }
    var socket = Socket()
    
    var connected = false {
        didSet {
            if !connected {
                socket.disconect()
            }
        }
    }
    
    //Cocoa-binding support
    dynamic var children = [Device]()
    dynamic var isLeaf = true
    
    var uuid = UUID().uuidString
    
    var name: String {
        return peerID.displayName
    }
    
    init(peerID: MCPeerID) {
        self.peerID = peerID
        super.init()
    }
    
    private func tryConfigureSocket() {
        if let read = input, let write = output {
            installSocketListeners()
            socket.configure(read, write)
            socket.open()
            input = nil
            output = nil
        }
    }
    
    func installSocketListeners() {
        socket.on(.log) { [weak self] data in
            guard let logData = data as? [String: Any] else { return }
            if let message = Mapper<LogMessage>().map(JSON: logData) {
                let mLogs = self?.mutableArrayValue(forKeyPath: #keyPath(logs))
                mLogs?.add(message)
            }
        }
        socket.on(.containerTree) { [weak self] data in
            guard let treeData = data as? [[String: Any]] else { return }
            if let tree = Mapper<File>().mapArray(JSONArray: treeData) {
                self?.containerTree.append(contentsOf: tree)
                File.printTree(tree: tree)
            }
        }
        socket.on(.inspector) { [weak self] data in
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
    
    dynamic var logs = [LogMessage]()
    dynamic var containerTree = [File]()
    
    override var hashValue: Int {
        return peerID.hashValue
    }

    dynamic var inspectorInfo = [InspectorRecord]()
}

extension Device {
    
    public static func ==(lhs: Device, rhs: Device) -> Bool {
        return lhs.peerID.displayName == rhs.peerID.displayName
    }
    
}

