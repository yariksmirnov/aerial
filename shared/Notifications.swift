//
//  Notifications.swift
//  WTalk
//
//  Created by Yarik Smirnov on 09/03/17.
//  Copyright © 2017 Wrike, Inc. All rights reserved.
//

import Foundation

extension NotificationCenter {

    static func arl_post(name: Notification.Name, object: AnyObject? = nil, userInfo: [String: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
    }
}

var NotificationsObserversKey = "Aerial.NotificationsObserversKey"

extension NSObject {

    func arl_subscribe(_ name: Notification.Name, object: AnyObject? = nil, action: @escaping (Notification) -> Void) {
        var observers = objc_getAssociatedObject(self, &NotificationsObserversKey) as? NSMutableDictionary
        if observers == nil {
            observers = NSMutableDictionary()
            objc_setAssociatedObject(self, &NotificationsObserversKey, observers, .OBJC_ASSOCIATION_RETAIN)
        }
        let observer = NotificationCenter.default.addObserver(
            forName: name,
            object: object,
            queue: OperationQueue.main,
            using: action
        )
        observers?[name.rawValue] = observer
    }

    func arl_subscribe(_ name: Notification.Name, object: AnyObject? = nil, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: object)
    }

    func arl_unsubscribe(_ name: Notification.Name? = nil) {
        guard let name = name else {
            arl_unsubscribeFromAll()
            return
        }
        let observers = objc_getAssociatedObject(self, &NotificationsObserversKey) as? NSMutableDictionary
        if observers != nil {
            if let observer = observers![name.rawValue] {
                NotificationCenter.default.removeObserver(observer)
                observers![name.rawValue] = nil
            }
            if observers!.count == 0 { //swiftlint:disable:this empty_count
                objc_setAssociatedObject(self, NotificationsObserversKey, nil, .OBJC_ASSOCIATION_RETAIN)
            }
        }
        NotificationCenter.default.removeObserver(self, name: name, object: nil)
    }

    private func arl_unsubscribeFromAll() {
        let observers = objc_getAssociatedObject(self, &NotificationsObserversKey) as? NSMutableDictionary
        if observers != nil {
            for observer in observers!.allValues {
                NotificationCenter.default.removeObserver(observer)
            }
            observers?.removeAllObjects()
            objc_setAssociatedObject(self, NotificationsObserversKey, nil, .OBJC_ASSOCIATION_RETAIN)
        }
        NotificationCenter.default.removeObserver(self, name: nil, object: nil)
    }

}
