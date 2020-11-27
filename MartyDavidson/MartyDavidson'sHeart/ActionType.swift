//
//  ActionType.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

public enum ActionType: String {
    case like = "like"
    case dislike = "dislike"
    case love = "love"
    case laugh = "laugh"
    case exclaim = "exclaim"
    case question = "question"
    case unknown = "unknown"
    
    public init(fromActionTypeInt actionTypeInt: Int) {
        if let configurationMapping = Configuration.shared.parameters?.actionType[actionTypeInt] {
            self.init(rawValue: configurationMapping)!
        } else {
            self = .unknown
        }
    }
}
