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

        switch state {
        case .connected:
            stateStr = "connected"
        case .connecting:
            stateStr = "connecting"
        case .notConnected:
            stateStr = "notConnected"
            if advertiser != nil {
                session.disconnect()
                recreateSession()
            } else {
                browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
            }
        }
        if let device = getDeviceIfExists(forPeer: peerID) {
            Log.info("\(peerID.displayName) transited to \(stateStr) state\n")
            device.state = state
        } else {
            Log.w("\(peerID.displayName) transited to \(stateStr) state, but not in device list")
        }
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
        Log.v("Looking for file loading listeners...")
        if let listener = listeners[peerID.displayName] {
            Log.v("\tDid founds one")
            let device = getDeviceIfExists(forPeer: peerID)
            Log.v("Looking for file in container received previously...")
            if let file = device?.containerTree[url] {
                Log.d("Did found one")
                file.localUrl = localURL
                listener.onReceive(file: file, error: error)
            } else {
                Log.e("File isn't contained in received container")
            }
        } else {
            Log.e("\tNot listeners attached")
        }
    }
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress)
    {
        Log.info("Start Receiving \(resourceName) from \(peerID.displayName)\n")
    }

    func session(_ session: MCSession,
                 didReceiveCertificate certificate: [Any]?,
                 fromPeer peerID: MCPeerID, 
                 certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
