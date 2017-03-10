//
//  StreamDelegate.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 05/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Foundation
import ObjectMapper

typealias EventHandler = (Any?) -> Void

class Socket: NSObject, StreamDelegate {
    
    enum OpCode : UInt8 {
        case continueFrame = 0x0
        case textFrame = 0x1
        case binaryFrame = 0x2
        // 3-7 are reserved.
        case connectionClose = 0x8
        case ping = 0x9
        case pong = 0xA
        // B-F reserved.
    }
    
    private var writeQueue = OperationQueue()
    internal static let sharedSocketQueue = DispatchQueue(label: "com.aerial.socket", qos: .background)
    
    var inputStream: InputStream?
    var outputStream: OutputStream?
    
    var mapEventsToHandlers = [SocketEvent: EventHandler]()
    
    var eventsQueue = Data()
    
    func on(_ event: SocketEvent, handler: @escaping EventHandler) {
        mapEventsToHandlers[event] = handler
    }
    
    override init() {
        writeQueue.maxConcurrentOperationCount = 1
        super.init()
    }
    
    func send(event: SocketEvent, withData data: Any) {
        writeQueue.addOperation { [weak self] in
            guard let s = self else { return }
            do {
                print("\nSending \(event) event...")
                let eventWrapper = SocketEventWrapper()
                eventWrapper.name = event
                eventWrapper.data = data
                
                let json = eventWrapper.toJSON()
                let eventData = try JSONSerialization.data(withJSONObject: json, options: [])
                print("\tSerialized event data of \(eventData.count) bytes")
                
                let offset = MemoryLayout<UInt64>.size
                var packet = Data(count: eventData.count + offset)
                packet.withUnsafeMutableBytes { (buffer: UnsafeMutablePointer<UInt8>) in
                    Socket.writeUint64(buffer, offset: 0, value: UInt64(eventData.count))
                    eventData.copyBytes(to: buffer + offset, count: eventData.count)
                }
                print("\tAppneding event packet of \(packet.count) bytes")
                s.eventsQueue.append(packet)
                
                print("\tChecking stream availibility...")
                if s.outputStream?.hasSpaceAvailable == true && s.outputStream?.streamStatus == .open {
                    print("\tOutput stream is available. Will proccess write...")
                    s.processWrite()
                } else {
                    print("\tOutput stream is unavailable. Will wait for available space...")
                }
                
            } catch (let error) {
                Log.error("Failed to serialize data for event \(event): \(error)")
            }
        }
    }
    
    internal func configure(_ inputStream: InputStream, _ outputStream: OutputStream) {
        self.inputStream = inputStream
        self.outputStream = outputStream
        
        self.inputStream?.delegate = self
        self.outputStream?.delegate = self
        
        CFReadStreamSetDispatchQueue(self.inputStream, Socket.sharedSocketQueue)
        CFWriteStreamSetDispatchQueue(self.outputStream, Socket.sharedSocketQueue)
    }
    
    internal func open() {
        self.inputStream?.open()
        self.outputStream?.open()
    }
    
    internal func disconect() {
        Socket.sharedSocketQueue.sync {
            writeQueue.cancelAllOperations()
            eventsQueue.removeAll()
            
            self.inputStream?.close()
            self.outputStream?.close()
            
            self.inputStream = nil;
            self.outputStream = nil;
        }
    }
    
    private func processWrite() {
        writeQueue.addOperation { [weak self] in
            guard let s = self else { return }
            guard s.eventsQueue.count > 0 else {
                print("\tQueue is empty. Skipping write.")
                return
            }
            print("Proccessing write...")
            var total = 0
            let maxLength = s.eventsQueue.count
            print("\tEvent queue length: \(s.eventsQueue.count) bytes")
            guard let outStream = s.outputStream else { return }
            s.eventsQueue.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
                while true {
                    let writeBuffer = UnsafeRawPointer(bytes + total).assumingMemoryBound(to: UInt8.self)
                    print("\t\tTrying to write buffer of \(s.eventsQueue.count - total) bytes")
                    let len = outStream.write(writeBuffer, maxLength: maxLength - total)
                    if len < 0 {
                        Log.error("Failed to write to outputStream: \(outStream.streamError)")
                        s.eventsQueue.removeAll()
                        break
                    } else {
                        print("\t\tSuccessfully write \(len) bytes")
                        total += len
                    }
                    if total >= maxLength {
                        print("\t\tTotal: \(total) bytes.\n\t\tClearing queue...")
                        s.eventsQueue.removeAll()
                        break
                    }
                }
            }
        }
    }
    
    private func proccessInput() {
        print("\nProccessing Input...")
        var data = Data()
        guard let input = inputStream else {
            print("\tNo input stream available. Propably was closed. Skipping...")
            return
        }
        print("\tStream status: \(stat_str(input.streamStatus))")
        if inputStream?.streamError != nil {
            print("\tStream error: \(input.streamError)")
        }
        while (input.streamStatus == .open && input.hasBytesAvailable != false) {
            var buffer = [UInt8](repeating: 0, count: 4096)
            let length = input.read(&buffer, maxLength: buffer.count)
            print("\t\tHas read \(length) bytes")
            if length < 0 {
                fatalError("Failed to read data from stream: \(input.streamError)")
            }
            data.append(buffer, count: length)
            if inputStream?.streamStatus == .closed {
                print("\tStream status changed to closed")
                return
            }
        }
        guard data.count > 0 else {
            Log.warn("Recieved zero bytes data from stream, skipping")
            return
        }
        print("\tFinished reading data from input stream")
        print("\t\tTotal bytes read: \(data.count)")
        print("\tStart proccessing packets from buffer...")
        data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            var buffer = UnsafeBufferPointer(start: bytes, count: data.count)
            repeat {
                print("\t\tTrying to fetch packet from buffer of \(buffer.count) bytes ...")
                buffer = processRawInputData(inBuffer: buffer)
            } while buffer.count > 0
        }
    }
    
    private func processRawInputData(inBuffer buffer: UnsafeBufferPointer<UInt8>) -> UnsafeBufferPointer<UInt8> {
        guard let baseAddress = buffer.baseAddress else { return emptyBuffer }
        let length = Int(Socket.readUint64(baseAddress, offset: 0))
        print("\t\t\tPacket length: \(length) bytes")
        if length > buffer.count {
            print("\t\t\tERROR: Invalid packet length. Skipping buffer...")
            return emptyBuffer
        }
        let offset = MemoryLayout<UInt64>.size
        let eventData = Data(bytes: baseAddress + offset, count: Int(length))
        
        print("\t\t\tWill parse packet as JSON data...")
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: eventData, options: []) as! [String: Any]
            if let eventWrapper = Mapper<SocketEventWrapper>().map(JSON: jsonDict) {
                print("\t\t\tDid parse packet for \(eventWrapper.name) event. Finding handler...")
                let handler = self.mapEventsToHandlers[eventWrapper.name]
                if handler != nil {
                    print("\t\t\tDid found handler. Will notify on main queue.\n")
                }
                DispatchQueue.main.async {
                    handler?(eventWrapper.data)
                }
            }
        } catch (let error) {
            Log.error("Input events proccessing error: \(error)")
            return emptyBuffer
        }
        
        return buffer.fromOffset(offset + length)
    }
    
    private let emptyBuffer = UnsafeBufferPointer<UInt8>(start: nil, count: 0)
    
    internal func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            Log.info("\(aStream === self.inputStream ? "Input" : "Output") Stream has been opened")
        case Stream.Event.hasSpaceAvailable:
            if aStream == outputStream {
                print("\nOutput stream has available space. Will check for packet waiting to be send...")
                processWrite()
            }
        case Stream.Event.hasBytesAvailable:
            if aStream == inputStream {
                print("\nInput stream had bytes available. Will try read from stream...")
                proccessInput()
            }
        case Stream.Event.errorOccurred:
            Log.error("\(aStream === self.inputStream ? "Input" : "Output") Stream error: \(aStream.streamError)")
        case Stream.Event.endEncountered:
            Log.warn("\(aStream === self.inputStream ? "Input" : "Output") Stream encountered end")
        default:
            break;
        }
    }
    
    private static func readUint64(_ buffer: UnsafePointer<UInt8>, offset: Int) -> UInt64 {
        var value = UInt64(0)
        for i in 0...7 {
            value = (value << 8) | UInt64(buffer[offset + i])
        }
        return value
    }
    
    private static func writeUint64(_ buffer: UnsafeMutablePointer<UInt8>, offset: Int, value: UInt64) {
        for i in 0...7 {
            buffer[offset + i] = UInt8((value >> (8*UInt64(7 - i))) & 0xff)
        }
    }
}

private extension UnsafeBufferPointer {
    
    func fromOffset(_ offset: Int) -> UnsafeBufferPointer<Element> {
        return UnsafeBufferPointer<Element>(start: baseAddress?.advanced(by: offset),
                                            count: count - offset)
    }
    
}

func stat_str(_ status: Stream.Status) -> String {
    switch status {
    case .notOpen: return "notOpen"
    case .opening: return "opening"
    case .open: return "open"
    case .reading: return "reading"
    case .writing: return "writing"
    case .atEnd: return "atEnd"
    case .closed: return "closed"
    case .error: return "error"
    }
}

