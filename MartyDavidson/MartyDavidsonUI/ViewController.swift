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
    @IBOutlet weak var enableDisableButton: NSButtonCell!
    
    
    @IBAction func enableDisableAction(_ sender: Any) {
        /*
        var name = nameField.stringValue
        
        if name.isEmpty {
            name = "World"
        }
        
        let greeting = "Hello \(name)!"
        helloLabel.stringValue = greeting*/
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        defaults = UserDefaults.standard
        
        observeKeys.forEach {
            path in defaults.addObserver(self, forKeyPath: path, options: .new, context: nil)
        }
        
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

