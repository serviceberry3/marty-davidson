//
//  Buddy.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 30/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

enum State {
    case initial
}

class Buddy {
    
    public var timer: Double
    public var name: String?
    public var state: State
    
    
    init (name: String?, handle: String?, state: State) {
        self.name = name
        self.timer = 0
        self.state = state
    }
    
    

}
