//
//  Action.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

public struct Action: Encodable, Equatable {
    enum CodingKeys : String, CodingKey{
        case type
        case targetGUID
        case event
    }
    public enum ActionEvent: String {
        case placed = "placed"
        case removed = "removed"
    }
    
    public var type: ActionType
    public var event: ActionEvent
    public var targetGUID: String
    
    public init(actionTypeInt: Int, targetGUID: String) {
        if (actionTypeInt >= 3000) {
            event = .removed
            self.type = ActionType(fromActionTypeInt: actionTypeInt - 1000)
        }
        
        
        else {
            event = .placed
            self.type = ActionType(fromActionTypeInt: actionTypeInt)
        }
        
        self.targetGUID = targetGUID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(targetGUID, forKey: .targetGUID)
        try container.encode(event.rawValue, forKey: .event)
    }
}
