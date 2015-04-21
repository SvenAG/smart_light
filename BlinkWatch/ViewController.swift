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
    
    // MARK: - BeatDetection
    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        dispatch_async(dispatch_get_main_queue(), {
            
            self.audioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
            if(abs(buffer[0][0]) > 0.01){
                
                var superbuffer = [Double]()
                
                self.bufferCounter++
                
                for( var i = 0; i<511; i++){
                    
                    superbuffer.append(Double(buffer[0][i]))
                }
                
                //find max in self.fft
                let fftArray = self.fft(superbuffer)
                
                var lowerbound = 1
                var upperbound = 3
                
                var fftEnergy = fftArray[lowerbound...upperbound].reduce(0, +)

                
                //let fftMax = fftArray[9...20].reduce(fftArray[9], { max($0, $1) })
                
                
                println((fftEnergy - self.oldEnergy))
                
                if fftEnergy - self.oldEnergy > 0.05 {
                    var beat_c = self.bufferCounter
                    
                    if(beat_c - self.lastBeat)>25{
                        //BEAT
                        if self.beat.hidden == true {
                            
                            //self.beat.hidden = false
                            //self.audioPlot.backgroundColor = UIColor.whiteColor()
                            
                            //wormhole.passMessageObject("test", identifier: "mess")
                            self.wormhole.passMessageObject("BOOM \(NSDate())", identifier: "mess")
                            
                        } else {
                            
                            //self.beat.hidden = true
                            //self.audioPlot.backgroundColor = UIColor.blackColor()
                            
                            //wormhole.passMessageObject("test", identifier: "mess")
                            self.wormhole.passMessageObject("BOOM \(NSDate())", identifier: "mess")
                            
                        }
                        self.lastBeat = beat_c
                    }
                }
                
                //Save old Energy
                
                self.oldEnergy = fftEnergy
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
    
    func sqrt(x: [Double]) -> [Double] {
        var results = [Double](count:x.count, repeatedValue:0.0)
        vvsqrt(&results, x, [Int32(x.count)])
        return results
    }
    
    let fft_weights: FFTSetupD = vDSP_create_fftsetupD(vDSP_Length(log2(Float(511))), FFTRadix(kFFTRadix2))
}

