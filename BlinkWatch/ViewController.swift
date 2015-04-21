//
//  ViewController.swift
//  BlinkWatch
//
//  Created by Bosch on 4/14/15.
//  Copyright (c) 2015 Bosch. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation
import GLKit
import Accelerate

class ViewController: UIViewController, EZMicrophoneDelegate {
    
    
    // MARK: - UI Objects
    @IBOutlet weak var audioPlot: EZAudioPlotGL!
    @IBOutlet weak var beat: UILabel!
    
    
    // MARK: - Attributes
    var microphone: EZMicrophone!
    var appendedBuffer = [Double]()
    var appendedFft = [Double]()
    var fftCounter = 0
    var oldEnergy = 0 as Double
    var bufferCounter = 0
    var lastBeat = -10
    var energyArray = [0.0]
    
    
    // Tunnel for data exchange
    var wormhole = MMWormhole(applicationGroupIdentifier: "group.bosch.cmpjmi", optionalDirectory: "theWatch")
    
    
    // MARK: - official SWIFT
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // initialize UI iphone
        self.microphone = EZMicrophone(microphoneDelegate: self)
        self.audioPlot.backgroundColor = UIColor.blackColor()
        self.audioPlot.color = UIColor.orangeColor()
        self.audioPlot.plotType = EZPlotType.Rolling
        self.audioPlot.shouldFill = false
        self.audioPlot.shouldMirror = false
        
        // start recording via internal microphone
        self.microphone.startFetchingAudio()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var supersuperbuffer = [Double]()
    var bigBufferCounter = 1
    
    // MARK: - BeatDetection
    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        dispatch_async(dispatch_get_main_queue(), {
            
            
            
            
            self.audioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
            if(abs(buffer[0][0]) > 0.01){
                
                var superbuffer = [Double]()
                
                self.bufferCounter++
                
                for( var i = 0; i<512; i++){
                    
                    superbuffer.append(Double(buffer[0][i]))
                }
                
                self.supersuperbuffer = self.supersuperbuffer + superbuffer
                self.bigBufferCounter++
                if self.bigBufferCounter == 3 {
                    
                    
                    let fftArray = self.fft(self.supersuperbuffer)
                    
                    
                    
                    self.supersuperbuffer = []
                    self.bigBufferCounter = 1
                    
                    var lowerbound = 1
                    var upperbound = 64
                    var fftEnergy = fftArray[lowerbound...upperbound].reduce(0, +)
                    
                    self.energyArray.append(fftEnergy)
                    
                    if self.energyArray.count > 43 {
                        
                   self.energyArray.removeAtIndex(0)
                    }
                    //Calculate average
                    
                    var averageEnergy = Double(self.energyArray.reduce(0, +)) / Double(self.energyArray.count)
                    
                    //Define Constant C for Energy Comparison
                    var C = 1.0
                    
                    
                    
                    //Compare fftEnergy and averageEnergy -> Beat
                    
                    if fftEnergy > (C * averageEnergy) {
                        var beat_c = self.bufferCounter
                        
                        if(beat_c - self.lastBeat)>10{
                            //BEAT
                            if self.beat.hidden == true {
                                
                                self.beat.hidden = false
                                self.audioPlot.backgroundColor = UIColor.whiteColor()
                                
                                self.wormhole.passMessageObject("BOOM\(NSDate())", identifier: "mess")
                                
                                
                                
                            } else {
                                
                                self.beat.hidden = true
                                self.audioPlot.backgroundColor = UIColor.blackColor()
                                
                                self.wormhole.passMessageObject("BOOM\(NSDate())", identifier: "mess")
                                
                                
                            }
                            self.lastBeat = beat_c
                        }
                        
                    }
                    
                    
                    
                }
                
                
                
                
                
            }
            
        })
        
        
        
    }
        
        
        
        
        
        
        func microphone(microphone: EZMicrophone!, hasAudioStreamBasicDescription audioStreamBasicDescription: AudioStreamBasicDescription) {
            EZAudio.printASBD(audioStreamBasicDescription)
        }
        
        func microphone(microphone: EZMicrophone!, hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
            //println(bufferList[0])
        }
        // MARK: - FFT
        func fft(input: [Double]) -> [Double] {
            var real = [Double](input)
            var imaginary = [Double](count: input.count, repeatedValue: 0.0)
            var splitComplex = DSPDoubleSplitComplex(realp: &real, imagp: &imaginary)
            
            let length = vDSP_Length(floor(log2(Float(input.count))))
            let radix = FFTRadix(kFFTRadix2)
            let weights = vDSP_create_fftsetupD(length, radix)
            vDSP_fft_zipD(weights, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))
            
            var magnitudes = [Double](count: input.count, repeatedValue: 0.0)
            vDSP_zvmagsD(&splitComplex, 1, &magnitudes, 1, vDSP_Length(input.count))
            
            var normalizedMagnitudes = [Double](count: input.count, repeatedValue: 0.0)
            vDSP_vsmulD(sqrt(magnitudes), 1, [2.0 / Double(input.count)], &normalizedMagnitudes, 1, vDSP_Length(input.count))
            
            vDSP_destroy_fftsetupD(weights)
            
            return normalizedMagnitudes
        }
        
        func sqrt(x: [Double]) -> [Double] {
            var results = [Double](count:x.count, repeatedValue:0.0)
            vvsqrt(&results, x, [Int32(x.count)])
            return results
        }
        
}

