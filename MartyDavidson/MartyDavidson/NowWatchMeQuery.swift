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
    """ //the question mark is a placeholder which later gets replaced using sqlite_bind_text
    private static let maxRecordIDQuery = "SELECT MAX(rowID) FROM message"
    
    var db: OpaquePointer?
    var querySinceID: String?
    var shouldExitThread = false
    var refreshSeconds = 5.0
    
    //the sqlite statement
    var statement: OpaquePointer? = nil
    var ourMarty: RavenSender?
    var parser: Parser? = nil
    
    
    init(databaseLocation: URL, ourMarty: RavenSender?) {
        guard let ourMartyReceived = ourMarty else {
            return
        }
        
        self.ourMarty = ourMartyReceived
        
        
    
        let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("martysexylog.txt")
        
        
        
        //open the database using sqlite3
        if sqlite3_open(databaseLocation.path, &db) != SQLITE_OK {
            print("Error opening SQLite database. Likely a \"Full disk access\" error, or some other bullshit perms. Bleep.")
            let str = "Error opening SQLite database. Likely a \"Full disk access\" error, or some other bullshit perms. Bleep."
            Logger.log(str)
            
            //TODO: disk access for newer MacOS?
            
            
            return
        }
        else {
            let str = "Succeeded in opening SQLite db. Also fuk Noa Rosincuntz"
            Logger.log(str)
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
        
        
        //used to bind parameters (wildcards) in SQL statements.
        //The idea of binding parameters is that a statement has only to be parsed once (using sqlite3_prepare) and can be used multiple times (using sqlite3_step). The sqlite3_bind calls are used to pass the values for the statement.
            //A statement must be reset (sqlite3_reset) when it has been executed through sqlite3_step.
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
    
    
    //return info about a single column of the current result row of the query
    private func unwrapStringColumn(for sqlStatement: OpaquePointer?, at column: Int32) -> String? { //the querying statement, and the index of col
        if let cString = sqlite3_column_text(sqlStatement, column) {
            //return the value of the requested column as string
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
        //get the current date/time
        let start = Date()
        
        //ensure statement is set to null when the current scope closes
        defer { statement = nil }
        
        
        
        //compiles the sqlite statement.
        //Compile SQL text into byte-code that will do the work of querying or updating the database. The constructor for sqlite3_stmt
        if sqlite3_prepare_v2(db, //sqlite3* - a pointer to the sqlite database we want to query
                            QueryMinion.newRecordquery, //const char* - the SQlite statement as UTF-8 encoded string
                              -1,           //max length of the sqlite statement in bytes
                            &statement,   //sqlite3_stmt** - OUT: ptr to the compiled output statement
                            nil)          //const char** - OUT: ptr to unused portion of the passed statement
            != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            let prepare_str = "Error compiling sqlite statement: \(errmsg)"
            print(prepare_str)
            Logger.log(prepare_str)
            
        }
        else {
            Logger.log("queryNewRecords: compiled sqlite statement OK")
        }
        
        //Store application data into parameters of the original SQL
        //used to bind parameters (wildcards) in SQL statements.
        //The idea of binding parameters is that a statement has only to be parsed once (using sqlite3_prepare) and can be used multiple times (using sqlite3_step). The sqlite3_bind_* calls are used to pass the values for the statement.
           // A statement must be reset (sqlite3_reset) when it has been executed through sqlite3_step.
        if sqlite3_bind_text(statement, //pointer to the sqlite3_stmt object returned from sqlite3_prepare_v2()
                             1,  //index of the parameter to be set
                             querySinceID ?? "1000000000", //value to bind to the parameter
                             -1,               //num of bytes in the parameter
                             SQLITE_TRANSIENT) //Destrutor used to dispose of the passed string once sqlite is done with it. SQLITE_TRANSIENT means SQLite makes its own private copy of the data immediately, before the sqlite3_bind_*() routine returns.
            
            != SQLITE_OK {
            
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            let bind_string = "Failure binding: \(errmsg)"
            
            //print and log the error
            print(bind_string)
            Logger.log(bind_string)
        }
        else {
            Logger.log("queryNewRecords: sqlite3_bind_text OK")
        }
        
        //evaluating the statement
        while sqlite3_step(statement) == SQLITE_ROW { //returned only if a result row is available
            print("BIGBOI")
            Logger.log("sqlite3_step: got incoming meessage row OK")
            
            //get various datas as strings, requested as certain column indexes of the current row of this query
            
            //handle of the message's sender
            var senderHandleOptional = unwrapStringColumn(for: statement, at: 0)
            
            //text of the message
            let textOptional = unwrapStringColumn(for: statement, at: 1)
            
            Logger.log("Message text is " + textOptional! + ", sender is " + senderHandleOptional!)
            
            //row ID of the message
            let rowID = unwrapStringColumn(for: statement, at: 2)
            
            
            let roomName = unwrapStringColumn(for: statement, at: 3)
            
            //whether the message was sent by me
            let isFromMe = sqlite3_column_int(statement, 4) == 1
            
            //message destination
            let destinationOptional = unwrapStringColumn(for: statement, at: 5)
            
            //exact date of the message
            let epochDate = TimeInterval(sqlite3_column_int64(statement, 6))
            
            //whether the message contains an attachment
            let hasAttachment = sqlite3_column_int(statement, 7) == 1
            
            //some other datas
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
            
            //make sure the sender handle, text, and destination are non-null
            guard let senderHandle = senderHandleOptional, let text = textOptional, let destination = destinationOptional else {
                break
            }
            
            //name of the sending buddy
            let buddyName = ContactHelper.RetreiveContact(handle: senderHandle)?.givenName
            
            //my name
            let myName = ContactHelper.RetreiveContact(handle: destination)?.givenName
            
            //declare some vars
            let sender: Person
            let recipient: RecipientEntity
            
            //get the group info
            let group = retrieveGroupInfo(chatID: roomName)
            
            
            if (isFromMe) {
                //return NSDate().timeIntervalSince(start)
                sender = Person(givenName: myName, handle: destination, isMe: true)
                recipient = group ?? Person(givenName: buddyName, handle: senderHandle, isMe: false)
            }
            
                
            //
            else {
                sender = Person(givenName: buddyName, handle: senderHandle, isMe: false)
                
                //I am the recipient
                recipient = group ?? Person(givenName: myName, handle: destination, isMe: true)
            }
            
            //create the received message
            let message = Scroll(body: TextBody(text), date: Date(timeIntervalSince1970: epochDate), sender: sender, recipient: recipient, guid: guid, attachments: hasAttachment ? retrieveAttachments(forMessage: rowID ?? "") : [],
                                  sendStyle: sendStyle, associatedMessageType: Int(associatedMessageType), associatedMessageGUID: associatedMessageGUID)
            
            
            print("Parsing incoming message...")
            
            if (!isFromMe) {
                Logger.log("Incoming message is not from me, now parsing message...")
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
