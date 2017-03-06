//
//  ViewController.swift
//  Aerial-Mac
//
//  Created by Yaroslav Smirnov on 30/11/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Cocoa
import Dollar

class ViewController: NSViewController {
    
    @IBOutlet var sourceListView: NSOutlineView!
    
    @IBOutlet var deviceViewController: DeviceViewController!
    @IBOutlet var treeController: NSTreeController!
    
    dynamic var deviceManager = DeviceManager.instance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        treeController.ys_addObserver(forKeyPath: "selectedObjects") {
            [weak self] obj, change, observer in
            guard let this = self else { return }
            
            if let selectedNode = this.treeController.selectedNodes.first {
                let device = selectedNode.representedObject as! Device
                this.deviceViewController.device = device
            }
        }
    }
    
    override func viewWillAppear() {
        deviceViewController = $.find(childViewControllers) {
            $0.isKind(of: DeviceViewController.self)
        } as! DeviceViewController
    }

}

extension ViewController : NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView,
                     viewFor tableColumn: NSTableColumn?,
                     item: Any) -> NSView?
    {
        let view = outlineView.make(withIdentifier: "DataCell", owner: self)
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
    }
    
}




