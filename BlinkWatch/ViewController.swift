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

var wormhole = MMWormhole(applicationGroupIdentifier: "group.bosch.cmpjmi", optionalDirectory: "theWatch")


class ViewController: UIViewController, EZMicrophoneDelegate {
    
    @IBOutlet weak var printButton: UIButton!
    @IBOutlet weak var audioPlot: EZAudioPlotGL!
    @IBOutlet weak var beat: UILabel!
    
    
    var microphone: EZMicrophone!
    
    var appendedBuffer = [Double]()
    var appendedFft = [Double]()
    
    var fftCounter = 0
    var oldEnergy = 0 as Double
    var bufferCounter = 0
    var lastBeat = -10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        
        self.microphone = EZMicrophone(microphoneDelegate: self)
        
        
        
        
        self.audioPlot.backgroundColor = UIColor.blackColor()
        self.audioPlot.color = UIColor.orangeColor()
        self.audioPlot.plotType = EZPlotType.Rolling
        self.audioPlot.shouldFill = false
        self.audioPlot.shouldMirror = false
        
        self.microphone.startFetchingAudio()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    var supersuperbuffer = [Double]()
    var bigBufferCounter = 1
    
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
                if self.bigBufferCounter == 4 {
                    
                    
                    let fftArray = self.fft(self.supersuperbuffer)
                    
                    
                    self.supersuperbuffer = []
                    self.bigBufferCounter = 1
                    
                    
                    
                    var lowerbound = 1
                    var upperbound = 20
                    
                    var fftEnergy = fftArray[lowerbound...upperbound].reduce(0, +)
                    println(fftEnergy)
                    
                    
                    
                    
                    
                    
                    //let fftMax = fftArray[9...20].reduce(fftArray[9], { max($0, $1) })
                    
                    
                    //println((fftEnergy - self.oldEnergy))
                    
                    
                    
                    if fftEnergy - self.oldEnergy > 0.01 {
                        var beat_c = self.bufferCounter
                        
                        if(beat_c - self.lastBeat)>10{
                            //BEAT
                            if self.beat.hidden == true {
                                
                                self.beat.hidden = false
                                self.audioPlot.backgroundColor = UIColor.whiteColor()
                                
                                wormhole.passMessageObject("test", identifier: "mess")
                                
                                
                                
                            } else {
                                
                                self.beat.hidden = true
                                self.audioPlot.backgroundColor = UIColor.blackColor()
                                
                                wormhole.passMessageObject("test", identifier: "mess")
                                
                                
                            }
                            self.lastBeat = beat_c
                        }
                        
                    }
                    
                    
                    //Save old Energy
                    
                    self.oldEnergy = fftEnergy
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
    
    func sqrt(x: [Double]) -> [Double] {
        var results = [Double](count:x.count, repeatedValue:0.0)
        vvsqrt(&results, x, [Int32(x.count)])
        return results
    }
    
    
    let fft_weights: FFTSetupD = vDSP_create_fftsetupD(vDSP_Length(log2(Float(512))), FFTRadix(kFFTRadix2))
    
    func fft(var inputArray:[Double]) -> [Double] {
        var fftMagnitudes = [Double](count:inputArray.count, repeatedValue:0.0)
        var zeroArray = [Double](count:inputArray.count, repeatedValue:0.0)
        var splitComplexInput = DSPDoubleSplitComplex(realp: &inputArray, imagp: &zeroArray)
        
        vDSP_fft_zipD(fft_weights, &splitComplexInput, 1, vDSP_Length(log2(CDouble(inputArray.count))), FFTDirection(FFT_FORWARD));
        vDSP_zvmagsD(&splitComplexInput, 1, &fftMagnitudes, 1, vDSP_Length(inputArray.count));
        
        let roots = sqrt(fftMagnitudes) // vDSP_zvmagsD returns squares of the FFT magnitudes, so take the root here
        var normalizedValues = [Double](count:inputArray.count, repeatedValue:0.0)
        
        vDSP_vsmulD(roots, vDSP_Stride(1), [2.0 / Double(inputArray.count)], &normalizedValues, vDSP_Stride(1), vDSP_Length(inputArray.count))
        return normalizedValues
    }
    
    @IBAction func printButton(sender: AnyObject) {
        
        println(self.appendedBuffer)
        println("----------------------------------------------------")
        println(self.appendedFft)
        
        
        
    }
}

