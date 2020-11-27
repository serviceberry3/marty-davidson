//
//  ViewController.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 26/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Cocoa

class ViewController: NSViewController { //extending NSViewController
    //short for interface builder outlet, this is how you tell storyboard editor that these obj names are
    //avail for linking to a visual obj
    
    //define keys for UserDefaults
    let observeKeys = [MartyConstants.martyIsDisabled]
    
    var defaults: UserDefaults!
    
    
    @IBOutlet weak var martyStatusLabel: NSTextField! //'!' = guaranteed to exist from now on
    @IBOutlet weak var enableDisableUiButton: NSButtonCell!
    @IBOutlet weak var enableDisableButton: NSButton!
    @IBOutlet weak var statusImage: NSImageView!
    
    
    deinit {
        if #available(OSX 10.12.2, *) {
            self.view.window?.unbind(NSBindingName(rawValue: #keyPath(touchBar)))
        }
        
        UserDefaults.standard.removeObserver(self, forKeyPath: MartyConstants.martyIsDisabled)
    }
    
    @IBAction func enableDisableAction(_ sender: Any) {
        /*
        var name = nameField.stringValue
        
        if name.isEmpty {
            name = "World"
        }
        
        let greeting = "Hello \(name)!"
        helloLabel.stringValue = greeting*/
        
        //Marty's currently disabled
        if (self.defaults.bool(forKey: MartyConstants.martyIsDisabled)) {
            self.defaults.set(false, forKey: MartyConstants.martyIsDisabled)
        }
            
        //Marty's currently enabled
        else {
            self.defaults.set(true, forKey: MartyConstants.martyIsDisabled)
        }
        
        //updateButtons()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        
        //basically assert that keyPath is non-null, else return
        guard let keyPathReceived = keyPath else {
            return
        }
        

        //if we care about this KVO key, update the buttons
        if observeKeys.contains(keyPathReceived) {
            updateButtons()
        }
    }
    
    func updateButtons() {
        DispatchQueue.main.async {
        
            //if Marty is currently disabled
            if (self.defaults.bool(forKey: MartyConstants.martyIsDisabled)) {
                self.enableDisableButton.title = "Enable"
                self.enableDisableUiButton.title = "Enable Marty"
                self.martyStatusLabel.stringValue = "Marty is currently disabled"
                self.statusImage.image = NSImage(named: NSImage.statusUnavailableName)
            }
                
            //if Marty IS currently enabled
            else {
                self.enableDisableButton.title = "Disable"
                self.enableDisableUiButton.title = "Disable Marty"
                self.martyStatusLabel.stringValue = "Marty is currently enabled"
                self.statusImage.image = NSImage(named: NSImage.statusAvailableName)
                }
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        defaults = UserDefaults.standard
        
        observeKeys.forEach {
            //add key-value observer for the key "MartyIsDisabled"
            path in defaults.addObserver(self, forKeyPath: path, options: .new, context: nil)
        }
        
        updateButtons()
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

