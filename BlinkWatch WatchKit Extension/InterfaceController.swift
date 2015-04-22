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
    
    // Attributes
    var oldOutput = NSString()
    var oldRandomNumber = 1
    var buttonIsActive = true
    var showLightning = false
    
    var wormhole = MMWormhole(applicationGroupIdentifier: "group.bosch.cmpjmi", optionalDirectory: "theWatch")
    
    
    @IBOutlet weak var buttonLabel: WKInterfaceButton!
    
    @IBAction func tappedButton() {
        
        // App is paused
        if (buttonIsActive != false) {
            
            getDataFromIphone()
            buttonLabel.setTitle("PLAY")
            buttonIsActive = false
        }
        // App is running
        else if (buttonIsActive != true) {
            
            buttonIsActive = true
            buttonLabel.setTitle("PAUSE")
        }
        // shouldn't land here
        else {
            
            println("no state here")
        }
    }
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // initialize variables
        buttonIsActive = true
        buttonLabel.setTitle("PAUSE")
        
        getDataFromIphone()
        
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
        //println("LUME with index: \(index)")
        
        if(buttonIsActive != false) {
          buttonLabel.setBackgroundColor(farbPalette[index])
        }
        else {
            println("No color change")
        }
        
    }
    
    // MARK: - Wormhole Listener (Receiver)
    func getDataFromIphone() {
        
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
                    else {
                        randomNumber -= 1
                    }
                }
                self.changeBackgroundColor(output, index: randomNumber)
                self.oldRandomNumber = randomNumber
                self.oldOutput = output
                
                // for debugging - will be deleted
                //println(output)
                //self.buttonLabel.setTitle(output)
            }
        })
    }
    
}
