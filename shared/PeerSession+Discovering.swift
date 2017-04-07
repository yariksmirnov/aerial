//
//  PeerSession+Discovering.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 30/03/2017.
//  Copyright © 2017 Yaroslav Smirnov. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension PeerSession : MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Log.info("Halfpipe Found peer: \(peerID.displayName)\n")
        _ = getOrCreateDevice(withID: peerID)
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Log.info("Halfpipe Lost peer: \(peerID.displayName)\n")
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
