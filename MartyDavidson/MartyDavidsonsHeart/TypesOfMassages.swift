//
//  TypesOfMassages.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

public protocol ScrollBody: Codable {}

public struct TextBody: ScrollBody, Codable {
    public var message: String
    
    public init(_ message: String) {
        self.message = message
    }
}

public struct Attachment: Codable {
    public var id: Int?
    public var filePath: String
    public var mimeType: String?
    public var fileName: String?
    public var isSticker: Bool?
    
    public init(id: Int, filePath: String, mimeType: String, fileName: String, isSticker: Bool) {
        self.id = id
        self.filePath = filePath
        self.mimeType = mimeType
        self.fileName = fileName
        self.isSticker = isSticker
    }
}
