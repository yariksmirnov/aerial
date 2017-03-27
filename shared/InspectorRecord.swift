//
//  InspectorRecord.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 26/03/2017.
//  Copyright © 2017 Yaroslav Smirnov. All rights reserved.
//

import Foundation
import ObjectMapper

class InspectorRecord: NSObject, Mappable {

    var title = ""
    var value = ""

    init(title: String = "Test Title", value: String = "Test Value") {
        self.title = title
        self.value = value
        super.init()
    }

    required init?(map: Map) {
        super.init()
    }

    func mapping(map: Map) {
        title <- map["title"]
        value <- map["value"]
    }

}

extension InspectorRecord {
    public static func ==(lhs: InspectorRecord, rhs: InspectorRecord) -> Bool {
        return lhs.title == rhs.title
    }
}
