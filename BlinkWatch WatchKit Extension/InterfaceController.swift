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
    
    
    @IBOutlet weak var buttonLabel: WKInterfaceButton!
    
    var oldOutput = NSString()
    var oldRandomNumber = 1
    
    
    var wormhole = MMWormhole(applicationGroupIdentifier: "group.bosch.cmpjmi", optionalDirectory: "theWatch")
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // MARK: - Wormhole Listener (Receiver)
        var listener: Void = wormhole.listenForMessageWithIdentifier("mess", listener: { (String) -> Void in
            
            // setting text of button label
            var output : NSString = self.wormhole.messageWithIdentifier("mess") as NSString!
            
            // checking if new bass-sequence is different from last bass-sequence
            if (output != self.oldOutput) {
                
                var randomNumber = Int(arc4random_uniform(5))
                
                if randomNumber == self.oldRandomNumber {
                    if randomNumber == 0 {
                        randomNumber += 1
                    }
                    else{
                        randomNumber -= 1
                    }
                }
                self.changeBackgroundColor(output, index: randomNumber)
                self.oldRandomNumber = randomNumber
                self.oldOutput = output
                
                // for debugging - will be deleted
                println(output)
                self.buttonLabel.setTitle(output)
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
    
    
    // MARK: - Setting Backgroundcolor
    func changeBackgroundColor(identifyer: String, index: Int) {
        
        var farbPalette = [UIColor]()
        
        farbPalette = [UIColor.blueColor(), UIColor.redColor(), UIColor.magentaColor(), UIColor.greenColor(), UIColor.yellowColor()]
        
        // for debugging - will be deleted
        println("LUME with index: \(index)")
        
        buttonLabel.setBackgroundColor(farbPalette[index])
    }
    
}
