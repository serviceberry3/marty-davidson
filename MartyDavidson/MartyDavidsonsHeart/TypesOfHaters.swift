//
//  Entities.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

//Codable is a typealias that combines two protocols: Encodable and Decodable
//Helps pre-generate much of code needed to encode and decode data to/from a serialized format like JSON, then can just call JSONEncoder().encode(codable)


public protocol RecipientEntity: Codable {
    //the recipient's handle
    var handle: String {
        //getter and setter skeleton
        get
        set
    }
}


public protocol SenderEntity: Codable {
    //the sender's handle
    var handle: String {
        //getter and setter skeleton
        get
        set
    }
    
    //the sender's given name/contact name
    var givenName: String? {
        //getter and setter skeleton
        get
        set
    }
}

// This represents an entity which could either be a person or a group
// Use this if you have a handle but don't know what type it is.
// If you know the type, please construct a group or person directly.
public struct AbstractRecipient: RecipientEntity, Codable, Equatable { //equatable protocol means this obj can be evaluated for equality/inequality
    public var handle: String
    
    public init(handle: String) {
        self.handle = handle
    }
    
    
    //get this abstract recipient as a Person entity or a Group entity
    public func getSpecificEntity() -> RecipientEntity {
        if handle.contains(";-;") {
            return Group(name: nil, handle: handle, participants: [])
        }
        
        else {
            return Person(handle: handle)
        }
    }
}

public struct Person: SenderEntity, RecipientEntity, Codable, Equatable {
    public var givenName: String?
    public var handle: String
    
    //bool indicating whether the person is owner of the iMessage acct that Marty is currently serving
    public var isMe: Bool = false
    
    //a mapping that Codable can use to convert JSON names into properties for our struct
    enum CodingKeys : String, CodingKey { //CodingKey is type that can be used as key for coding and decoding to/from JSON
        //property names that will map onto JSON names
        case handle
        case givenName
        case isMe
    }
    
    //set handle on init
    public init(handle: String) {
        self.handle = handle
    }
    
    //alternate init fxn to also accept a "given name" and isme checker
    public init(givenName: String?, handle: String, isMe: Bool?) {
        self.givenName = givenName
        self.handle = handle
        self.isMe = isMe ?? false
    }
    
    
    //define how Persons are to be equated
    public static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.givenName == rhs.givenName &&
            lhs.handle == rhs.handle &&
            lhs.isMe == rhs.isMe
    }
}


public struct Group: RecipientEntity, Codable, Equatable {
    public var name: String?
    public var handle: String
    public var participants: [Person]
    
    public init(name: String?, handle: String, participants: [Person]) {
        self.name = name
        self.handle = handle
        self.participants = participants
    }
    
    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.name == rhs.name &&
            lhs.handle == rhs.handle &&
            lhs.participants == rhs.participants
    }
}
