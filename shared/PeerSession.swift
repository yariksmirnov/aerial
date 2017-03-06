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

class PeerSession: NSObject {
    
    fileprivate var session: MCSession
    #if os(iOS)
    private var peer = MCPeerID(displayName: UIDevice.current.name)
    #else
    private var peer = MCPeerID(displayName: Host.current().localizedName!)
    #endif
    private let AerialServiceType = "aerialdebuger"
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?
    
    fileprivate var isAdvertising = false
    fileprivate var isBrowsing = false
    
    private var devices = [MCPeerID: Device]()
    
    fileprivate var loadingCompletions = [File: FileRequestCompletion]()
    
    weak var delegate: PeerSessionDelegate?
    
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
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: AerialServiceType)
        browser?.delegate = self
        isBrowsing = true
        browser?.startBrowsingForPeers()
    }
    
    func browse() {
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: AerialServiceType)
        advertiser?.delegate = self
        isAdvertising = true
        advertiser?.startAdvertisingPeer()
    }
    
    func getFile(withRequest request: FileRequest, completion: @escaping FileRequestCompletion) {
        let url = ["url" : request.file.url.absoluteString ]
        request.device.socket.send(event: .loadFile, withData: url)
        loadingCompletions[request.file] = completion
    }
    
    func send(fileUrl: URL, toDevice device: Device, completion: @escaping (Error?) -> Void) {
        session.sendResource(at: fileUrl, withName: fileUrl.absoluteString, toPeer: device.peerID) { error in
            completion(error)
        }
    }
    
    fileprivate func getOrCreateDevice(withID peerID: MCPeerID) -> Device {
        if let device = devices[peerID] {
            return device
        } else {
            let device = Device(peerID: peerID)
            devices[device.peerID] = device
            delegate?.session(self, didCreate: device)
            return device
        }
    }
    
    fileprivate func createOutputStream(forDevice device: Device) {
        let peerID = device.peerID
        do {
            device.output = try session.startStream(withName: "\(peerID.displayName)-output", toPeer:device.peerID)
        } catch (let error) {
            Log.error("Failed to open stream to \(peerID.displayName): \(error)\n")
        }
    }
}

extension PeerSession: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        var stateStr = ""
        
        let device = getOrCreateDevice(withID: peerID)

        switch state {
        case .connected:
            stateStr = "connected"
            device.connected = true
        case .connecting:
            stateStr = "connecting"
        case .notConnected:
            stateStr = "notConnected"
            device.connected = false
        }
        if device.connected {
            createOutputStream(forDevice: device)
        }
        Log.info("\(peerID.displayName) transited to \(stateStr) state\n")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        let device = getOrCreateDevice(withID: peerID)
        device.input = stream
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) { }
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL,
                 withError error: Error?)
    {
        Log.info("Did receive \(resourceName) from \(peerID.displayName)\n")
        let device = getOrCreateDevice(withID: peerID)
        guard let url = URL(string: resourceName) else { return }
        if let file = device.containerTree[url] {
            let completion = loadingCompletions[file]
            completion?(localURL, error)
            loadingCompletions[file] = nil
        }
    }
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress)
    {
        Log.info("Start Receiving \(resourceName) from \(peerID.displayName)\n")
    }
}

extension PeerSession : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Log.info("Found peer: \(peerID.displayName)\n")
        _ = getOrCreateDevice(withID: peerID)
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Log.info("Lost peer: \(peerID.displayName)\n")
    }
}

extension PeerSession : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping ((Bool, MCSession?) -> Void))
    {
        Log.info("\nReceive invitation from \(peerID.displayName)")
        _ = getOrCreateDevice(withID: peerID)
        invitationHandler(true, self.session)
    }
}
