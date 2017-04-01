//
//  File.swift
//  Aerial-Mac
//
//  Created by Yaroslav Smirnov on 07/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Foundation
import ObjectMapper

class File: NSObject, Mappable {
    
    var url: URL
    
    required init?(map: Map) {
        do {
            self.url = try map.value("url", using: URLTransform())
        } catch {
            return nil
        }
    }
    
    init(url: URL) {
        self.url = url
    }
    
    dynamic var name = ""
    dynamic var relativePath = ""
    dynamic var children = [File]()
    dynamic var isLeaf = true
    dynamic var inspectorUrl: URL?

    var localUrl: URL?

    #if os(OSX)
    var icon: NSImage {
        var image: NSImage
        if self.isLeaf {
            image = NSWorkspace.shared().icon(forFileType: url.pathExtension)
        } else {
            image = NSWorkspace.shared().icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kGenericFolderIcon)))
        }
        image.size = NSMakeSize(17, 17);
    
        return image;
    }
    #endif
    
    func mapping(map: Map) {
        url <- (map["url"], URLTransform())
        name <- map["name"]
        relativePath <- map["relativePath"]
        isLeaf <- map["isLeaf"]
        children <- map["children"]
    }
    
    static func printTree(tree: [File], indentLevel: Int = 0) {
        let indent = Array(repeating: "  ", count: indentLevel).reduce("") { "\($0)\($1)" }
        if indentLevel > 0 {
            Log.d("\(indent)\\")
        }
        for file in tree {
            if Logger.level.isInclude(level: .debug) {
                print("\(indent) --- \(file.name)", terminator: "")
            }
            if !file.isLeaf && file.children.count > 0 {
                Log.d("")
                printTree(tree: file.children, indentLevel: indentLevel + 2)
            }
            Log.d("")
        }
    }
}

extension Array where Element: File {
    
    subscript(fileUrl: URL) -> File? {
        return first { file in
            file.url == fileUrl
        }
    }
}
