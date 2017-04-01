//
//  PeerSession+SessionDelegate.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 30/03/2017.
//  Copyright © 2017 Yaroslav Smirnov. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension PeerSession: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        var stateStr = ""

        getOrCreateDevice(withID: peerID).state = state

        switch state {
        case .connected:
            stateStr = "connected"
        case .connecting:
            stateStr = "connecting"
        case .notConnected:
            stateStr = "notConnected"
            browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
        }
        Log.info("\(peerID.displayName) transited to \(stateStr) state\n")
    }

    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let listener = listeners[peerID.displayName] {
            listener.onReceive(data: data)
        }
    }

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL,
                 withError error: Error?)
    {
        Log.info("Did receive \(resourceName) from \(peerID.displayName)\n")
        guard let url = URL(string: resourceName) else { return }
        if let listener = listeners[peerID.displayName] {
            let device = getOrCreateDevice(withID: peerID)
            if let file = device.containerTree[url] {
                file.localUrl = localURL
                listener.onReceive(file: file, error: error)
            }
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
