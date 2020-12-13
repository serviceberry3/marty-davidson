//
//  Logger.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 12/12/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation

//code for logging dbug statements to a log file, appending using FileManager for each statement
class Logger {
    
    static var logFile: URL? {
        //get Documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let fileName = "martysexylog.log"
        
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    static func log(_ message: String) {
        guard let logFile = logFile else {
            return
        }
        
        //create date timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        
        //create the full log statement string
        guard let data = (timestamp + ": " + message + "\n").data(using: String.Encoding.utf8) else { return }
        
        //seek to end of file and write the string
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
        
        
        else {
            try? data.write(to: logFile, options: .atomicWrite)
        }
    }
}
