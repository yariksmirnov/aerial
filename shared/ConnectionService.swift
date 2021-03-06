//
//  PeerService.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 30/03/2017.
//  Copyright © 2017 Yaroslav Smirnov. All rights reserved.
//

import Foundation
import MultipeerConnectivity

typealias EventHandler = (Any, Method) -> Void
typealias FileLoadingHandler = (File, Error?) -> Void

final class ConnectionService {

    let session: PeerSession
    let device: Device

    var state: MCSessionState = .notConnected {
        didSet {
            if state == .connected {
                flushWaitingPackets()
            }
        }
    }

    var waitingPackets = [Packet]()

    fileprivate var eventHandler = [Event: EventHandler]()
    fileprivate var filesLoadingHandlers = [File: FileLoadingHandler]()

    init(session: PeerSession, device: Device) {
        self.session = session
        self.device = device

        session.addListener(self, forDevice: device)
    }

    func on(_ event: Event, handler: @escaping EventHandler) {
        eventHandler[event] = handler
    }

    func send(event: Event, withData data: Any?) {
        let packet = Packet()
        packet.name = event
        packet.data = data
        Log.d("Sending packet for \(event.rawValue) event")
        guard state == .connected else {
            Log.d("Not in connected state, adding to waiting packets to send later...")
            waitingPackets.append(packet)
            return
        }
        if let jsonData = packet.data() {
            if !session.send(data: jsonData, toDevice: device) {
                Log.w("Failed to send packet for \(event.rawValue), will try later")
                waitingPackets.append(packet)
            } else {
                guard !waitingPackets.isEmpty else { return }
                flushWaitingPackets()
            }
        }
    }

    func flushWaitingPackets() {
        Log.d("Flushing waiting packets...")
        var failedPackets = [Packet]()
        waitingPackets.forEach {
            guard let data = $0.data() else { return }
            if !self.session.send(data: data, toDevice: self.device) {
                Log.w("Failed to send packet for \($0.name.rawValue) event")
                failedPackets.append($0)
            }
        }
        waitingPackets.removeAll()
        waitingPackets.append(contentsOf: failedPackets)
        Log.d("\(waitingPackets.count) remains after flushing")
    }

    func send(file: File) {
        session.send(fileUrl: file.url, toDevice: device)
    }

    func load(file: File, handler: @escaping FileLoadingHandler) {
        guard filesLoadingHandlers[file] == nil else {
            Log.e("Attempet to load same file twice: \(file.url)")
            return
        }
        filesLoadingHandlers[file] = handler
        send(event: .loadFile, withData: file.toJSON())
    }

}

extension ConnectionService: PeerSessionListener {

    func onReceive(data: Data) {
        guard let packet = Packet.from(data: data) else { return }
        guard let handler = eventHandler[packet.name] else { return }
        guard let packetData = packet.data else { return }
        DispatchQueue.main.async {
            handler(packetData, packet.method)
        }
    }

    func onReceive(file: File, error: Error?) {
        if let e = error {
            Log.e("Failed to load file: \(e.localizedDescription)")
        }
        guard let handler = filesLoadingHandlers[file] else { return }
        filesLoadingHandlers[file] = nil
        handler(file, error)
    }

}
