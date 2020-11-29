//
//  Parser.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 29/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

class Parser {
    init() {
        
    }
    
    func parse(message: Scroll?) {

        
        print((message?.body as? TextBody)!.message)
        print("testing")
    }
    
    deinit {
        
    }
}
