//
//  AppDelegate.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Cocoa

@NSApplicationMain //main entry pt of app
class AppDelegate: NSObject, NSApplicationDelegate {

    var sender: Marty
    var databaseHelper: DatabaseHandler!
    
    override init() {
        //set initial userdefaults - Marty is initially enabled
        UserDefaults.standard.register(defaults: [
            MartyConstants.martyIsDisabled: false,
            ])
        
        
        //intanstiate a new marty
        sender = Marty()

        super.init()
    }

    //code to launch app
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let messageDatabaseURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Messages").appendingPathComponent("chat.db")
        let viewController = NSApplication.shared.keyWindow?.contentViewController as? ViewController
        
        //instantiate the DataBaseHandler
        databaseHelper = DatabaseHandler(databaseLocation: messageDatabaseURL)
    }

    
    //code to tear down application
    func applicationWillTerminate(_ aNotification: Notification) {
        
    }


}

