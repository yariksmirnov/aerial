//
//  DDAerialLogger.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 03/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import UIKit
import ObjectMapper

extension LogMessage {
    
    convenience init(ddLogMessage: DDLogMessage) {
        self.init()
        self.message = ddLogMessage.message;
        switch ddLogMessage.flag {
        case DDLogFlag.error: level = .error
        case DDLogFlag.warning: level = .warning
        case DDLogFlag.info: level = .info
        case DDLogFlag.debug: level = .debug
        case DDLogFlag.verbose: level = .verbose
        default: level = .off
        }
        self.file = ddLogMessage.file
        self.function = ddLogMessage.function
        self.line = Int(ddLogMessage.line)
        self.timestamp = ddLogMessage.timestamp
    }
    
}

class DDAerialLogger: DDAbstractLogger, CorkLogger {
    
    var socket: Socket? {
        didSet {
            if socket != nil {
                logs.forEach { logEntry in
                    socket?.send(event: .log, withData: logEntry.toJSON())
                }
            }
        }
    }
    
    var logs = [LogMessage]()
    
    override func log(message logMessage: DDLogMessage!) {
        let logEntry = LogMessage(ddLogMessage: logMessage)
        logs.append(logEntry)
        socket?.send(event: .log, withData: logEntry.toJSON())
    }
}
