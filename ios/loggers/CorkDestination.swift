//
//  CorkDestination.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 14/02/2017.
//  Copyright © 2017 Yaroslav Smirnov. All rights reserved.
//

import Foundation
import XCGLogger

extension LogMessage {

    convenience init(logDetails: LogDetails) {
        self.init()
        self.message = logDetails.message;
        switch logDetails.level {
        case .error: level = .error
        case .warning: level = .warning
        case .info: level = .info
        case .debug: level = .debug
        case .verbose: level = .verbose
        default: level = .off
        }
        self.file = logDetails.fileName
        self.function = logDetails.functionName
        self.line = logDetails.lineNumber
        self.timestamp = logDetails.date
    }

}

public class CorkDestination: BaseDestination, CorkLogger {

    private var service: ConnectionService? {
        didSet {
            if service != nil {
                service?.send(event: .log, withData: logs.toJSON())
            }
        }
    }
    public var device: Device? {
        didSet {
            service = device?.service
        }
    }

    var logs = [LogMessage]()

    open override func output(logDetails: LogDetails, message: String) {
        var logDetails = logDetails
        var message = message

        if self.shouldExclude(logDetails: &logDetails, message: &message) {
            return
        }
        self.applyFormatters(logDetails: &logDetails, message: &message)

        let logEntry = LogMessage(logDetails: logDetails)
        logs.append(logEntry)
        service?.send(event: .log, withData: [logEntry].toJSON())
    }

}
