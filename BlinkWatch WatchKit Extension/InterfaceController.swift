//
//  InterfaceController.swift
//  BlinkWatch WatchKit Extension
//
//  Created by Bosch on 4/14/15.
//  Copyright (c) 2015 Bosch. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    var black = true
    @IBOutlet weak var background: WKInterfaceGroup!
    
    
    var wormhole = MMWormhole(applicationGroupIdentifier: "group.bosch.cmpjmi", optionalDirectory: "theWatch")
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        
        
        
        wormhole.listenForMessageWithIdentifier("mess", listener: { (String) -> Void in
            
            if self.black == true {
                
                self.background.setBackgroundColor(UIColor.whiteColor())
                self.black = false
                
            } else {
                
                self.background.setBackgroundColor(UIColor.blackColor())
                self.black = true
                
            }
            
        })
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}
