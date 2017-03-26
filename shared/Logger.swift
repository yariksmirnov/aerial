//
//  Logging.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 08/03/2017.
//  Copyright © 2017 Yaroslav Smirnov. All rights reserved.
//

import Foundation

public enum Level: Int {
    case error
    case warning
    case info
    case debug
    case verbose

    func isInclude(level: Level) -> Bool {
        return rawValue >= level.rawValue
    }
}

protocol LevelLogging {

    func error(_ msg: String)
    func warning(_ msg: String)
    func info(_ msg: String)
    func debug(_ msg: String)
    func verbose(_ msg: String)

}

internal let Log = Logger()

public final class Logger: LevelLogging {

    public static var level: Level = .debug

    func error(_ msg: String) {
        log(msg, level: .error)
    }
    func warning(_ msg: String) {
        log(msg, level: .warning)
    }
    func info(_ msg: String) {
        log(msg, level: .info)
    }
    func debug(_ msg: String) {
        log(msg, level: .debug)
    }
    func verbose(_ msg: String) {
        log(msg, level: .verbose)
    }

    private func log(_ msg: String, level: Level) {
        if Logger.level.isInclude(level: level) {
            print(msg)
        }
    }
}

extension Logger {

    func e(_ msg: String) {
        error(msg)
    }
    func w(_ msg: String) {
        warning(msg)
    }
    func i(_ msg: String) {
        info(msg)
    }
    func d(_ msg: String) {
        debug(msg)
    }
    func v(_ msg: String) {
        verbose(msg)
    }
}

