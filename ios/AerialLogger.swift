//
//  Logging.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 08/03/2017.
//  Copyright © 2017 Yaroslav Smirnov. All rights reserved.
//

import Foundation

public protocol AerialLogging {

    func error(_ msg: String)
    func warn(_ msg: String)
    func info(_ msg: String)
    func debug(_ msg: String)
    func verbose(_ msg: String)

}

final class AerialLogger {

    var log: AerialLogging = PrintLogging()

    func error(_ msg: String) {
        log.error(msg)
    }
    func warn(_ msg: String) {
        log.warn(msg)
    }
    func info(_ msg: String) {
        log.info(msg)
    }
    func debug(_ msg: String) {
        log.debug(msg)
    }
    func verbose(_ msg: String) {
        log.verbose(msg)
    }

}

private final class PrintLogging: AerialLogging {
    func error(_ msg: String) {
        print(msg)
    }
    func warn(_ msg: String) {
        print(msg)
    }
    func info(_ msg: String) {
        print(msg)
    }
    func debug(_ msg: String) {
        print(msg)
    }
    func verbose(_ msg: String) {
        print(msg)
    }
}

