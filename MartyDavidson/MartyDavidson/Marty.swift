//
//  Marty.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

public class Marty: RavenSender {
    public func send(_ message: Message) {
        
    }
    
    //get the queue of work
    let queue = OperationQueue()
    
    init() {
        queue.maxConcurrentOperationCount = 1
    }
    
    public func send(_ body: String, to recipient: RecipientEntity?) {
        //
    }
}
