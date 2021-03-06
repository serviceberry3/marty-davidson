//
//  Marty.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

public class Marty: RavenSender {
    //get the queue of work
    let queue = OperationQueue()
    
    //max number of queued operations that can execute at the same time
    //intialize the work queue so that it can only do one thread/job at a time
    init() {
        print("Marty init")
        
        queue.maxConcurrentOperationCount = 1
    }
    
    public func send(_ body: String, to recipient: RecipientEntity?) { //? means can be null
        
        //make sure recipient is non-null
        guard var recipientReceived = recipient else {//guard is like assert and has to have a return/exit statement within block that follows
            return
        }
        
        //attempt downcast to 'AbstractRecipient' (subclass of RecipientEntity), returning an Optional (and possibly null on failure)
        if let abstract = recipientReceived as? AbstractRecipient {//if let is like (if __ != null) then do something
            //get the specific entity (Group or Person) from the abstract
            recipientReceived = abstract.getSpecificEntity()
        }
        
        //intialize self as a person
        let me = Person(givenName: nil, handle: "", isMe: true)
        
        //create the message with the given text, date, sender, recipient, and attachments
        let message = Scroll(body: TextBody(body), date: Date(), sender: me, recipient: recipientReceived, attachments: [])
        
        //send the message
        send(message)
    }
    
    //another version of send which takes a pre-made Scroll
    public func send(_ message: Scroll) {
        NSLog("Attemping to send message: \(message)")
        
        let defaults = UserDefaults.standard
        
        //Don't send the message if Marty is currently disabled.
        guard !defaults.bool(forKey: MartyConstants.martyIsDisabled) else {
            return
        }
        
        let recipient = message.recipient.handle
        let sender = message.sender.handle
        
        //make sure cast is successful
        if let textBody = message.body as? TextBody {
            var scriptPath: String?
            let body = textBody.message
            
            //group?
            if message.recipient.handle.contains(";+;") {
                scriptPath = Bundle.main.url(forResource: "SendText", withExtension: "scpt")?.path
            }
            
            //default
            else {
                print("SENDING VIA SINGLE BUDDY SCPT")
                Logger.log("Marty: sending message " + body + " using osascript..." )
                scriptPath = Bundle.main.url(forResource: "SendTextSingleBuddy", withExtension: "scpt")?.path
                
                //scriptPath = "/Users/noah/Documents/Marty/marty-davidson/MartyDavidson/MartyDavidson/SendTextSingleBuddy.scpt"
                print(scriptPath)
                Logger.log("Found scripPath: " + scriptPath!)
            }
            
            //add a job to the work queue (allow for multithreading)
            queue.addOperation {
                print("Adding operation to queue")
                Logger.log("Adding osascript to queue")
                self.executeScript(scriptPath: scriptPath, body: body, recipient: sender)
            }
        }
        
        /*
        if let attachments = message.attachments {
            print("ATTACHMENT")
            
            var scriptPath: String?
            
            if message.recipient.handle.contains(";+;") {
                scriptPath = Bundle.main.url(forResource: "SendImage", withExtension: "scpt")?.path
            }
            
            else {
                scriptPath = Bundle.main.url(forResource: "SendImageSingleBuddy", withExtension: "scpt")?.path
            }
            
            attachments.forEach {
                attachment in
                queue.addOperation {
                    self.executeScript(scriptPath: scriptPath, body: attachment.filePath, recipient: recipient)
                }
            }
        }*/
    }
    
    
    //function to run an AppleScript scpt file
    private func executeScript(scriptPath: String?, body: String?, recipient: String?) {
        //null checking
        guard (scriptPath != nil && body != nil && recipient != nil) else {
            return
        }
        
        print("Recipient is", recipient)
        
        
        //instantiate a new Process
        let task = Process()
        
        //run shell script as 'osascript [path to script] [text body] [recipient]'
        task.launchPath = "/usr/bin/osascript"
        task.arguments = [scriptPath!, body!, recipient!]
        task.launch()
        
        //wait for the shell cmd to finish running
        task.waitUntilExit()
    }
    
    //run shell script
    @discardableResult
    public static func shell(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
}
