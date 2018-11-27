
//  Copyright © 2018 Eray Alparslan. All rights reserved.
//

import Foundation
import Speech


protocol SpeechRecognitionModalDelegate {
    func didPrepareSpeech(finalString: String, isMicButtonEnabled: Bool)
}

class SpeechRecognitionModal: NSObject {
    private var finalString = ""
    private var isMicButtonEnabled = true
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var lang: String = Bundle.main.preferredLocalizations.first! as String
    private var timer: Timer?
    
    var delegate: SpeechRecognitionModalDelegate?
    
    
    //kodun geri kalanı
    
    func customInit() {
        isMicButtonEnabled = false
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            self.isMicButtonEnabled = isButtonEnabled
            self.delegate?.didPrepareSpeech(finalString: self.finalString, isMicButtonEnabled: isButtonEnabled)
        }
    }
    
    
    func micButtonPressedFunc() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            isMicButtonEnabled = false
        }
        else {
            startRecording()
        }
        self.delegate?.didPrepareSpeech(finalString: self.finalString, isMicButtonEnabled: self.isMicButtonEnabled)
    }
    
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.finalString = result?.bestTranscription.formattedString ?? ""
                self.delegate?.didPrepareSpeech(finalString: self.finalString, isMicButtonEnabled: self.isMicButtonEnabled)
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isMicButtonEnabled = true
            }
            else if error == nil {
                self.restartSpeechTimer()
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
            self.isMicButtonEnabled = false
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        self.finalString = "Konuş gardaşım..."
    }
    
    func restartSpeechTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { (timer) in
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: self.lang))
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.isMicButtonEnabled = true
            self.delegate?.didPrepareSpeech(finalString: self.finalString, isMicButtonEnabled: self.isMicButtonEnabled)
        })
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.isMicButtonEnabled = true
        }
        else {
            self.isMicButtonEnabled = false
        }
    }
    
    
}



