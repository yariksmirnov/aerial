//
//  DebugItem.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 05/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import ObjectMapper

enum SocketEvent: String {
    case unknown
    case log
    case containerTree
    case loadFile
    case inspector
}

class SocketEventWrapper: Mappable {
    
    var name: SocketEvent = .unknown
    var data: Any?
    
    init() {
        
    }
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        name <- map["name"]
        data <- (map["data"], TransformOf(fromJSON: { (json: Any?) -> Any? in
            return json
        }, toJSON: { (object: Any?) -> Any? in
            return object
        }) )
    }
}

extension Mappable {
    
    static func from(data: Data) -> Self? {
        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return Mapper<Self>().map(JSON: dict)
            }
        } catch (let error) {
            Log.error("Failed to deserilalize \(Self.self): \(error)")
        }
        return nil
    }
    
    func data() -> Data? {
        let json = self.toJSON()
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            return data
        } catch (let error) {
            Log.error("Failed to serialize \(Self.self): \(error)")
        }
        return nil
    }
    
}

extension Array where Element: Mappable {
    
    func jsonData() -> Data {
        let jsonArray = Mapper().toJSONArray(self)
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
            return data
        } catch (let error) {
            Log.error("Failed to serialize array of \(Element.self): \(error)")
            fatalError()
        }
    }
    
}

extension Data  {
    
    func jsonArray() -> [[String: Any]] {
        do {
            let obj = try JSONSerialization.jsonObject(with: self, options: []) as! [[String: Any]]
            return obj
        } catch (let error) {
            Log.error("Failed to deserialize json: \(error)")
            fatalError()
        }
    }
    
    func deserializeArray<T: Mappable>() -> [T] {
        return Mapper<T>().mapArray(JSONArray: jsonArray())!
    }
    
}


