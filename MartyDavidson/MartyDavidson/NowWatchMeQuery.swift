//
//  NowWatchMeQuery.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

import SQLite3

class QueryMinion {
    private static let groupQuery = """
        SELECT handle.id, display_name, chat.guid
            FROM chat_handle_join INNER JOIN handle ON chat_handle_join.handle_id = handle.ROWID
            INNER JOIN chat ON chat_handle_join.chat_id = chat.ROWID
            WHERE chat.chat_identifier = ?
    """
    private static let attachmentQuery = """
    SELECT ROWID,
    filename,
    mime_type,
    transfer_name,
    is_sticker
    FROM attachment
    INNER JOIN message_attachment_join
    ON attachment.ROWID = message_attachment_join.attachment_id
    WHERE message_id = ?
    """
    
    
    private static let newRecordquery = """
        SELECT handle.id, message.text, message.ROWID, message.cache_roomnames, message.is_from_me, message.destination_caller_id,
            message.date/1000000000 + strftime("%s", "2001-01-01"),
            message.cache_has_attachments,
            message.expressive_send_style_id,
            message.associated_message_type,
            message.associated_message_guid, message.guid, destination_caller_id
            FROM message LEFT JOIN handle
            ON message.handle_id = handle.ROWID
            WHERE message.ROWID > ? ORDER BY message.ROWID ASC
    """
    private static let maxRecordIDQuery = "SELECT MAX(rowID) FROM message"
    
    var db: OpaquePointer?
    var querySinceID: String?
    var shouldExitThread = false
    var refreshSeconds = 5.0
    var statement: OpaquePointer? = nil
    var ourMarty: RavenSender?
    var parser: Parser? = nil
    
    
    init(databaseLocation: URL, ourMarty: RavenSender?) {
        guard let ourMartyReceived = ourMarty else {
            return
        }
        
        self.ourMarty = ourMartyReceived
        
        
        //open the database using sqlite3
        if sqlite3_open(databaseLocation.path, &db) != SQLITE_OK {
            print("Error opening SQLite database. Likely a \"Full disk access\" error. Bleep.")
    
            //TODO: disk access for newer MacOS?
            
            
            return
        }
        else {
            print("SUCCESS")
        }

        
        querySinceID = getCurrentMaxRecordID()
        
        parser = Parser(ourMarty: ourMarty)
        
        //start querying the database on background thread
        start()
    }
    
    //destructor
    deinit {
        //join the backgnd querying thread
        shouldExitThread = true
        
        //close the sqlite databse
        if sqlite3_close(db) != SQLITE_OK {
            print("There was an error closing the sqlite database")
        }
        
        //set database to null
        db = nil
    }
    
    //start up the querying minion on background thread
    func start() {
        //instantiate new DispatchQueue
        //object that manages execution of tasks serially or concurrently on app's main thread or on backgnd thread
        let dispatchQueue = DispatchQueue(label: "Marty Querier Background Thread", qos: .background)
        
        //async task
        dispatchQueue.async(execute: self.backgroundAction)
    }
    
    
    private func backgroundAction() {
        while shouldExitThread == false {
            //let defaults = UserDefaults.standard
            
            //Don't do anything if Marty is currently disabled.
            //if !defaults.bool(forKey: MartyConstants.martyIsDisabled) {
                //query the database
                let elapsed = queryNewRecords()
                
                //wait for a certain amt of time (refreshSeconds - [amt of time query took]). this means every 5 sec we run a new query
                Thread.sleep(forTimeInterval: max(0, refreshSeconds - elapsed))
            //}
        }
    }
    
    
    private func getCurrentMaxRecordID() -> String {
        var id: String?
        
        //pointer to the sqlite3 query statement
        var statement: OpaquePointer?
        
        //compile the sqlite3 statement and make sure compilation succeeded
        if sqlite3_prepare_v2(db /*ptr to db*/,
            QueryMinion.maxRecordIDQuery, /*UTF-8 encoded SQL query statment*/
            -1, /*max length of the SQL query statment in bytes*/
            &statement, /*OUT: dbl ptr to the compied query bytecode program*/
            nil) /*OUT: dbl ptr to unused portion of the passed query statement*/
            
            != SQLITE_OK {
            
            //get the sqlite compiler error message
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            
            //print the error message
            print("Error preparing select: \(errmsg)")
        }
        
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idcString = sqlite3_column_text(statement, 0) else {
                break
            }
            
            id = String(cString: idcString)
        }
        
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error finalizing prepared statement: \(errmsg)")
        }
        
        return id ?? "0"
    }
    
    
    private func retrieveGroupInfo(chatID: String?) -> Group? {
        guard let chatHandle = chatID else {
            return nil
        }
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, QueryMinion.groupQuery, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing select: \(errmsg)")
        }
        
        if sqlite3_bind_text(statement, 1, chatID, -1, SQLITE_TRANSIENT) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding foo: \(errmsg)")
        }
        
        var People = [Person]()
        var groupName: String?
        var chatGUID: String?
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idcString = sqlite3_column_text(statement, 0) else {
                break
            }
            groupName = unwrapStringColumn(for: statement, at: 1)
            chatGUID = unwrapStringColumn(for: statement, at: 2)
            
            let handle = String(cString: idcString)
            let contact = ContactHelper.RetreiveContact(handle: handle)
            
            People.append(Person(givenName: contact?.givenName, handle: handle, isMe: false))
        }
        
        return Group(name: groupName, handle: chatGUID ?? chatHandle, participants: People)
    }
    
    
    
    private func unwrapStringColumn(for sqlStatement: OpaquePointer?, at column: Int32) -> String? {
        if let cString = sqlite3_column_text(sqlStatement, column) {
            return String(cString: cString)
        }
        
        else {
            return nil
        }
    }
    
    
    
    private func retrieveAttachments(forMessage messageID: String) -> [Attachment] {
        var attachmentStatement: OpaquePointer? = nil
        
        defer { attachmentStatement = nil }
        
        if sqlite3_prepare_v2(db, QueryMinion.attachmentQuery, -1, &attachmentStatement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing select: \(errmsg)")
        }
        
        if sqlite3_bind_text(attachmentStatement, 1, messageID, -1, SQLITE_TRANSIENT) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding: \(errmsg)")
        }
        
        var attachments = [Attachment]()
        
        while sqlite3_step(attachmentStatement) == SQLITE_ROW {
            guard let rowID = unwrapStringColumn(for: attachmentStatement, at: 0) else { continue }
            guard let fileName = unwrapStringColumn(for: attachmentStatement, at: 1) else { continue }
            guard let mimeType = unwrapStringColumn(for: attachmentStatement, at: 2) else { continue }
            guard let transferName = unwrapStringColumn(for: attachmentStatement, at: 3) else { continue }
            let isSticker = sqlite3_column_int(attachmentStatement, 4) == 1
            
            attachments.append(Attachment(id: Int(rowID)!, filePath: fileName, mimeType: mimeType, fileName: transferName, isSticker: isSticker))
        }
        
        if sqlite3_finalize(attachmentStatement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error finalizing prepared statement: \(errmsg)")
        }
        
        return attachments
    }
    
    //query chat.db for new messages
    private func queryNewRecords() -> Double {
        let start = Date()
        defer { statement = nil }
        
        if sqlite3_prepare_v2(db, QueryMinion.newRecordquery, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing select: \(errmsg)")
        }
        
        if sqlite3_bind_text(statement, 1, querySinceID ?? "1000000000", -1, SQLITE_TRANSIENT) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding: \(errmsg)")
        }
        
        
        while sqlite3_step(statement) == SQLITE_ROW {
            print("BIGBOI")
            var senderHandleOptional = unwrapStringColumn(for: statement, at: 0)
            let textOptional = unwrapStringColumn(for: statement, at: 1)
            let rowID = unwrapStringColumn(for: statement, at: 2)
            let roomName = unwrapStringColumn(for: statement, at: 3)
            let isFromMe = sqlite3_column_int(statement, 4) == 1
            let destinationOptional = unwrapStringColumn(for: statement, at: 5)
            let epochDate = TimeInterval(sqlite3_column_int64(statement, 6))
            let hasAttachment = sqlite3_column_int(statement, 7) == 1
            let sendStyle = unwrapStringColumn(for: statement, at: 8)
            let associatedMessageType = sqlite3_column_int(statement, 9)
            let associatedMessageGUID = unwrapStringColumn(for: statement, at: 10)
            let guid = unwrapStringColumn(for: statement, at: 11)
            let destinationCallerId = unwrapStringColumn(for: statement, at: 12)
            print("Processing \(rowID ?? "unknown")")
            
            querySinceID = rowID;
            
            if (senderHandleOptional == nil && isFromMe == true && roomName != nil) {
                senderHandleOptional = destinationCallerId
            }
            
            guard let senderHandle = senderHandleOptional, let text = textOptional, let destination = destinationOptional else {
                break
            }
            
            let buddyName = ContactHelper.RetreiveContact(handle: senderHandle)?.givenName
            let myName = ContactHelper.RetreiveContact(handle: destination)?.givenName
            let sender: Person
            let recipient: RecipientEntity
            let group = retrieveGroupInfo(chatID: roomName)
            
            if (isFromMe) {
                //return NSDate().timeIntervalSince(start)
                sender = Person(givenName: myName, handle: destination, isMe: true)
                recipient = group ?? Person(givenName: buddyName, handle: senderHandle, isMe: false)
            }
            
            else {
                sender = Person(givenName: buddyName, handle: senderHandle, isMe: false)
                recipient = group ?? Person(givenName: myName, handle: destination, isMe: true)
            }
            
            //create the received message
            let message = Scroll(body: TextBody(text), date: Date(timeIntervalSince1970: epochDate), sender: sender, recipient: recipient, guid: guid, attachments: hasAttachment ? retrieveAttachments(forMessage: rowID ?? "") : [],
                                  sendStyle: sendStyle, associatedMessageType: Int(associatedMessageType), associatedMessageGUID: associatedMessageGUID)
            
            
            print("Parsing incoming message...")
            
            if (!isFromMe) {
            parser?.parse(message: message)
            }
        }
        
        
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error finalizing prepared statement: \(errmsg)")
        }
        
        //return amt of time this run of queryNewRecords() took, as a long
        return NSDate().timeIntervalSince(start)
    }
}
