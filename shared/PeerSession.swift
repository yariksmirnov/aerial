//
//  PeerSession.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 07/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import MultipeerConnectivity

protocol PeerSessionDelegate: class {
    
    func session(_ session: PeerSession, didCreate device: Device)
    func session(_ session: PeerSession, didLost device: Device)
    
}

class FileRequest {
    var file: File
    var device: Device
    
    init(file: File, device: Device) {
        self.file = file
        self.device = device
    }
}

typealias FileRequestCompletion = (URL, Error?) -> Void

protocol PeerSessionListener {

    func onReceive(data: Data)
    func onReceive(file: File, error: Error?)

}

final class PeerSession: NSObject {
    
    fileprivate(set) var session: MCSession
    #if os(iOS)
    private var peer = MCPeerID(displayName: UIDevice.current.name)
    #else
    private var peer = MCPeerID(displayName: Host.current().localizedName!)
    #endif
    private let AerialServiceType = "aerialdebuger"
    var browser: MCNearbyServiceBrowser?
    var advertiser: MCNearbyServiceAdvertiser?
    
    fileprivate(set) var isAdvertising = false
    fileprivate(set) var isBrowsing = false
    
    private var devices = [String: Device]()

    private(set) var listeners = [String: PeerSessionListener]()
    
    weak var delegate: PeerSessionDelegate?

    var currentDevice: Device {
        return getOrCreateDevice(withID: peer)
    }
    
    override init() {
        self.session = MCSession(
            peer: peer,
            securityIdentity: nil,
            encryptionPreference: .none
        )
        super.init()
        
        self.session.delegate = self
    }
    
    func advertise() {
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: AerialServiceType)
        advertiser?.delegate = self
        isAdvertising = true
        advertiser?.startAdvertisingPeer()
    }
    
    func browse() {
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: AerialServiceType)
        browser?.delegate = self
        isBrowsing = true
        browser?.startBrowsingForPeers()
    }
    
    func getOrCreateDevice(withID peerID: MCPeerID) -> Device {
        if let device = devices[peerID.displayName] {
            if device.peerID != peerID {
                device.peerID = peerID
            }
            return device
        } else {
            let device = Device(peerID: peerID, session: self)
            devices[device.peerID.displayName] = device
            delegate?.session(self, didCreate: device)
            return device
        }
    }

    func recreateSession() {
        self.session = createMultipeerSession()
        self.session.delegate = self
    }

    private func createMultipeerSession() -> MCSession {
        return MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .none)
    }

    func getDeviceIfExists(forPeer peerID: MCPeerID) -> Device? {
        if let device = devices[peerID.displayName], device.peerID == peerID {
            return device
        }
        return nil
    }

    func addListener(_ listener: PeerSessionListener, forDevice device: Device) {
        listeners[device.name] = listener
    }

    func send(data: Data, toDevice device: Device) -> Bool {
        do {
            try session.send(data, toPeers: [device.peerID], with: .reliable)
            return true
        } catch {
            Log.e("Failed to send data to \(device.name): \(error.localizedDescription)")
            return false
        }
    }

    func send(fileUrl: URL, toDevice device: Device) {
        session.sendResource(
            at: fileUrl,
            withName: fileUrl.absoluteString,
            toPeer: device.peerID
        ) { error in
            if let e = error {
                Log.e("Failed to send file at \(fileUrl) to \(device.name): \(e)")
            }
        }
    }

}
