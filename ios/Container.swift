//
//  Container.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 14/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Foundation

class Container {
    
    var device: Device? {
        didSet {
            if device != nil {
                installListeners()
                updateContainerTree()
                sendTree()
            }
        }
    }
    var session: PeerSession
    
    var tree = [File]()
    
    var containerUrl: URL {
        let fm = FileManager.default
        let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        return docUrl!.deletingLastPathComponent()
    }
    
    init(session: PeerSession) {
        self.session = session
        updateContainerTree()
        File.printTree(tree: tree)
    }
    
    func updateContainerTree() {
        tree = tree(forDirectory: containerUrl)
    }
    
    private func installListeners() {
        device?.socket.on(.containerTree) { data in
            
        }
        device?.socket.on(.loadFile) { data in
            guard let fileRequest = data as? [String: Any] else { return }
            guard let url = URL(string: fileRequest["url"] as? String ?? "")?.absoluteURL else { return }
            
            self.session.send(fileUrl: url, toDevice: self.device!) { error in
                
            }
        }
    }
    
    private func sendTree() {
        let data = tree.toJSON()
        device?.socket.send(event: .containerTree, withData: data)
    }
    
    private func tree(forDirectory directory: URL) -> [File] {
        let fm = FileManager.default
        var files = [File]()
        do {
            let keys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
            let urls = try fm.contentsOfDirectory(at: directory,
                                                  includingPropertiesForKeys: keys)
            for url in urls {
                let file = File(url: url)
                let resourceValues = try url.resourceValues(forKeys: Set(keys))
                file.name = resourceValues.name ?? ""
                file.relativePath = url.absoluteString.replacingOccurrences(of: containerUrl.absoluteString, with: "")
                if resourceValues.isDirectory == true {
                    file.isLeaf = false
                    file.children = tree(forDirectory: url)
                }
                files.append(file)
            }
        } catch (let error) {
            Log.error("Failed to get content of directory \(directory): \(error)")
        }
        return files
    }
    
}
