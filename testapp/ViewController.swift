//
//  ViewController.swift
//  Aerial-iOS
//
//  Created by Yaroslav Smirnov on 30/11/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import XCGLogger
import KZFileWatchers

class ViewController: UIViewController {
    
    var timer: Timer?
    var aerial: Aerial?
    var watcher: FileWatcher.Local?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFileWatcher()
        
        timer = Timer(timeInterval: 2, target: self, selector: #selector(startLogging), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)

        createFile()
    }

    private func setupFileWatcher() {
        let fm = FileManager.default
        let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        let containerUrl = docUrl!.deletingLastPathComponent()
        watcher = FileWatcher.Local(path: docUrl!.path)
        try! watcher?.start { result in
            switch result {
            case .noChanges:
                break
            case .updated(_):
                break
            }
        }
    }

    private func createFile() {
        let fm = FileManager.default
        let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        try! "Hello World!".write(to: docUrl!.appendingPathComponent("test_file.txt"), atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.deleteFile()
        }
        Container.debugPrint()
    }

    private func deleteFile() {
        let fm = FileManager.default
        let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        try! fm.removeItem(at: docUrl!.appendingPathComponent("test_file.txt"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.createFile()
        }
        Container.debugPrint()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        aerial?.updateDebugInfo {
            ["APNS Token" : UUID().uuidString,
             "User Token" : UUID().uuidString,
             "Account ID" : "KZJDIWNO",
             "Access Token": UUID().uuidString,
             "Account" : [
                "Name" : "Enterprise Wrike",
                "ID" : "KSDIDKD",
                "Role" : "Collaborator"
                ]
            ]
        }
    }

    static var incrementer = 0
    
    func startLogging() {
        TestLog.error("\(ViewController.incrementer)")
        TestLog.warning("\(ViewController.incrementer)")
        TestLog.info("\(ViewController.incrementer)")
        TestLog.debug("\(ViewController.incrementer)")
        TestLog.verbose("\(ViewController.incrementer)")

        ViewController.incrementer = ViewController.incrementer + 1

        aerial?.updateDebugInfo {
            ["APNS Token" : UUID().uuidString,
             "User Token" : UUID().uuidString,
             "Account ID" : "KZJDIWNO",
             "Access Token": UUID().uuidString,
             "Account" : [
                "Name" : "Enterprise Wrike",
                "ID" : "KSDIDKD",
                "Role" : "Collaborator"
                ]
            ]
        }
    }
}



