//
//  DeviceManager.swift
//  Aerial-Mac
//
//  Created by Yaroslav Smirnov on 08/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Cocoa

class DeviceManager: NSObject {
    
    static let instance = DeviceManager()
    
    let session = PeerSession()

    dynamic var devices = [Device]()
    
    override init() {
        super.init()
        session.delegate = self
        session.browse()
    }
    
    func load(file: File, forDevice device: Device, completion: @escaping (File?) -> Void) {
        let request = FileRequest(file: file, device: device)
        session.getFile(withRequest: request) { tmpFileUrl, error in
            if let err = error {
                Log.error("\nFailed to receive file data: \(err)")
                return
            }
            let updateFile = self.store(file: file, atLocalUrl: tmpFileUrl, forDevice: device)
            completion(updateFile)
        }
    }
    
    var appDirectory: URL {
        let fm = FileManager.default
        let bundleId = Bundle.main.bundleIdentifier!
        let urls = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return urls.first!.appendingPathComponent(bundleId, isDirectory: true)
    }
    
    func directory(forDevice device: Device) -> URL {
        return appDirectory
            .appendingPathComponent("Containers", isDirectory: true)
            .appendingPathComponent(device.uuid, isDirectory: true)
    }
    
    func store(file: File, atLocalUrl localUrl: URL, forDevice device: Device) -> File? {
        let fm = FileManager.default
        let dir = directory(forDevice: device)
        let fileUrl = dir.appendingPathComponent(file.relativePath)
        let fileDir = fileUrl.deletingLastPathComponent()
        
        print("Storing received file...")
        print("\t\tTmp url: \(localUrl)")
        print("\t\tTarget directory: \(fileDir)")
        
        if !fm.fileExists(atPath: fileDir.path) {
            do {
                print("/t/t/tTarget directory does not exists. Will create...")
                try fm.createDirectory(at: fileDir, withIntermediateDirectories: true)
            } catch (let error) {
                Log.error("Failed to create App Directory: \(error)")
                return nil
            }
        }
        
        do {
            print("\t\tCopying from tmp directory to app container...")
            if fm.fileExists(atPath: fileUrl.path) {
                print("\t\tAlready exists previous version. Deleting...")
                try fm.removeItem(at: fileUrl)
            }
            try fm.copyItem(at: localUrl, to: fileUrl)
        } catch(let error) {
            Log.error("Failed to copy file from tmp directory: \(error)")
            return nil
        }
        
        file.inspectorUrl = fileUrl
        return file
    }
    
}

extension DeviceManager: PeerSessionDelegate {
    
    func session(_ session: PeerSession, didCreate device: Device) {
        if !devices.contains(device) {
            devices.append(device)
        }
    }
    
    func session(_ session: PeerSession, didLost device: Device) {
        
    }
    
}
