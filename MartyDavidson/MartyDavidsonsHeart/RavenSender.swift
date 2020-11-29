//
//  MessageSender.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

//basically like a Java interface. skeleton fxns
public protocol RavenSender {
    func send(_ body: String, to recipient: RecipientEntity?)
    func send(_ message: Scroll)
}
