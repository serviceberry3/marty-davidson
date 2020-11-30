//
//  Parser.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 29/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation



class Parser {
    
    var ourMarty: RavenSender?
    init(ourMarty: RavenSender?) {
        guard let martyReceived = ourMarty else {
            return
        }
        
        self.ourMarty = martyReceived
        
    }
    
    func parse(message: Scroll?) {
        print((message?.body as? TextBody)!.message)
        
        
        ourMarty?.send(message!)
    }
    
    deinit {
        
    }
}
