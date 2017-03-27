//
//  DeviceViewController.swift
//  Aerial-Mac
//
//  Created by Yaroslav Smirnov on 02/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Cocoa

class LogTransformer : ValueTransformer {
    
    override open class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let log = value as? LogMessage else { return nil }
        
        return "\(log.timestamp) \(log.message)\n"
    }
    
    override open class func allowsReverseTransformation() -> Bool {
        return false
    }
    
}

class DeviceViewController: NSViewController {
    
    dynamic var device: Device? {
        didSet {
            unsubscribe(from: oldValue)
            if let newDevice = device {
                subscribe(to: newDevice)
            }
        }
    }
    
    @IBOutlet var logsTextView: NSTextView!
    
    @IBOutlet var treeController: NSTreeController!
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var outlineView: NSOutlineView!
    @IBOutlet var searchField: NSSearchField!

    @IBOutlet var verticalSplitView: NSSplitView!
    @IBOutlet var horizontalSplitView: NSSplitView!
    @IBOutlet var inspectorView: NSView!
    
    var logLevel: LogLevel = .debug
    
    var colors = [LogLevel : NSColor]()
    
    var logsTransformer: (([LogMessage]) -> NSAttributedString)!
    var logFilter: (([LogMessage]) -> [LogMessage])!
    var logs = [LogMessage]()
    var logsObservationToken: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToPreferences()
        
        logFilter = { logs in
            let filtered = logs.filter {
                $0.level.contains(self.logLevel)
            }
            return filtered
        }
        logsTransformer = { [weak self] logs in
            guard let this = self else { return NSAttributedString() }
            return logs.reduce(NSMutableAttributedString()) { result, entry in
                let string = "\(entry.timestamp)[\(entry.level)] \(entry.message)\n"
                let color = this.colors[entry.level] ?? NSColor.black
                let attributes = [ NSFontAttributeName : NSFont(name: "Menlo-Bold", size: 13)!,
                                   NSForegroundColorAttributeName : color ] as [String: Any]
                let attrubutedString = NSAttributedString(string: string, attributes: attributes)
                result.append(attrubutedString)
                return result
            }
        }
        
        logsTextView.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: NSFontWeightBold)
        outlineView.doubleAction = #selector(onDoubleClick)
    }
    
    func onDoubleClick() {
        if let selectedNode = treeController.selectedNodes.first {
            let file = selectedNode.representedObject as! File
            Log.info("Request file opening: \(file.name)")
            DeviceManager.instance.load(file: file, forDevice: device!) { updatedFile in
                if let url = updatedFile?.inspectorUrl {
                    NSWorkspace.shared().open(url)
                }
            }
        }
    }
    
    @IBAction func onLogLevel(sender: NSPopUpButton!) {
        guard let title = sender.selectedItem?.title else { return }
        logLevel = LogLevel(string: title)
        logsTextView.textStorage?.setAttributedString(logsTransformer(logFilter(logs)))
    }
    
    func updateLogs() {
        logsTextView.textStorage?.setAttributedString(logsTransformer(logFilter(logs)))
    }
    
    func subscribe(to device: Device) {
        logsObservationToken = device.ys_addObserver(forKeyPath: "logs",
                                                     options: [.new, .initial])
        { [weak self] obj, change, observer in
            guard let this = self else { return }
            guard let kind = change?.kvoChange else { return }
            switch kind {
            case .setting:
                guard let newLogs = change?.setted as? [LogMessage] else { return }
                this.logs = newLogs
                this.logsTextView.textStorage?
                    .setAttributedString(this.logsTransformer(this.logFilter(newLogs)))
            case .insertion:
                guard let newLogs = change?.inserted as? [LogMessage] else { return }
                this.logs.append(contentsOf: newLogs)
                this.logsTextView.textStorage?
                    .append(this.logsTransformer(this.logFilter(newLogs)))
            default:
                break
            }
        }
    }
    
    func unsubscribe(from device: Device?) {
        if let token = logsObservationToken {
            device?.ys_removeObserver(token)
        }
    }
    
    func subscribeToPreferences() {
        let defaults = NSUserDefaultsController.shared()
        let keyPaths = LogLevel.allLevels().map { "values.logs.colors.\($0.description.lowercased())" }
        defaults.ys_addObsevers(forKeyPaths: keyPaths, options: [.new, .initial])
        { [weak self] obj, change, key in
            guard let this = self else { return }
            let level = LogLevel(string: key!.components(separatedBy: ".").last!.capitalized)
            if let colorData = defaults.defaults.data(forKey: key!) {
                let transformer = ValueTransformer(forName:
                    NSValueTransformerName.unarchiveFromDataTransformerName)
                guard let color = transformer?.transformedValue(colorData) as? NSColor else {
                    return
                }
                if this.colors[level] != color {
                    this.colors[level] = color
                    this.updateLogs()
                }
            }
        }
    }
}

extension DeviceViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView,
                     viewFor tableColumn: NSTableColumn?,
                     item: Any) -> NSView?
    {
        let result = outlineView.make(withIdentifier: "Cell", owner: self)
        
        if let _ = (item as! NSTreeNode).representedObject as? File {
            (result as? NSTableCellView)?.textField?.isEditable = true
        }
        
        return result
    }
}
