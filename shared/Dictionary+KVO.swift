//
//  Dictionary+KVO.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 14/12/2016.
//  Copyright © 2016 Yaroslav Smirnov. All rights reserved.
//

import Foundation


extension Dictionary {
    
    var kvoChange: NSKeyValueChange? {
        return NSKeyValueChange(rawValue: (self[NSKeyValueChangeKey.kindKey.rawValue as! Key] as? UInt) ?? 0)
    }
    
    var setted: [Any] {
        if self.kvoChange == NSKeyValueChange.setting {
            return self[NSKeyValueChangeKey.newKey.rawValue as! Key] as? [Any] ?? []
        }
        return []
    }
    
    var inserted: [Any] {
        if self.kvoChange == NSKeyValueChange.insertion {
            return self[NSKeyValueChangeKey.newKey.rawValue as! Key] as? [Any] ?? []
        }
        return []
    }
    
    var replacedNew: [Any] {
        if self.kvoChange == NSKeyValueChange.replacement {
            return self[NSKeyValueChangeKey.newKey.rawValue as! Key] as? [Any] ?? []
        }
        return []
    }
    
    var replacedOld: [Any] {
        if self.kvoChange == NSKeyValueChange.replacement {
            return self[NSKeyValueChangeKey.newKey.rawValue as! Key] as? [Any] ?? []
        }
        return []
    }
    
    var removed: [Any] {
        if self.kvoChange == NSKeyValueChange.removal {
            return self[NSKeyValueChangeKey.oldKey.rawValue as! Key] as? [Any] ?? []
        }
        return []
    }
    
    var indexes: NSIndexSet? {
        return self[NSKeyValueChangeKey.indexesKey.rawValue as! Key] as? NSIndexSet
    }
    
}
