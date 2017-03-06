//
//  LogMessage.swift

//
//  Created by Yaroslav Smirnov on 05/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import ObjectMapper

enum LogLevel: Int, CustomStringConvertible {
    case off
    case fatal
    case error
    case warning
    case info
    case debug
    case verbose
    
    var description: String {
        switch self {
        case .fatal: return "Fatal"
        case .error: return "Error"
        case .warning: return "Warning"
        case .info: return "Info"
        case .debug: return "Debug"
        case .verbose: return "Verbose"
        case .off: return "Off"
        }
    }
    
    init(string: String) {
        switch string {
        case "Fatal": self = .fatal
        case "Error": self = .error
        case "Warning": self = .warning
        case "Info": self = .info
        case "Debug": self = .debug
        case "Verbose": self = .verbose
        default: self = .off
        }
    }
    
    func contains(_ level: LogLevel) -> Bool {
        return level.rawValue >= self.rawValue
    }
    
    static func allLevels() -> [LogLevel] {
        return [.fatal, .error, .warning, .info, .debug, .verbose]
    }
}

class LogMessage: NSObject, Mappable {
    
    var message: String = ""
    var level: LogLevel = .off
    var file: String = ""
    var function: String = ""
    var line: Int = 0
    var timestamp: Date = Date()
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        message <- map["message"]
        level <- map["level"]
        file <- map["file"]
        function <- map["function"]
        line <- map["line"]
        timestamp <- (map["timestamp"], DateTransform())
    }
    
}

extension SocketEventWrapper {
    
    convenience init(_ logMessage: LogMessage) {
        self.init()
        self.data = logMessage.toJSON()
    }
    
    func logMessages() ->  [LogMessage] {
        return []
    }
}

