//
//  ViewController.swift
//  SpeechToTextDemo
//
//  Created by Dhara Bhuva on 11/11/22.
//

import UIKit
import Speech
import AVKit

class ViewController: UIViewController {
    
    
    //MARK: - IBOutlet Declaration
    @IBOutlet var txtView: UITextView!
    @IBOutlet var lblMsg: UILabel!
    @IBOutlet var btnMic: UIButton!
    
    //MARK: - Variable Declaration
    var speechRecognizer        = SFSpeechRecognizer()
    var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask         : SFSpeechRecognitionTask?
    let audioEngine             = AVAudioEngine()
    var toolBar = UIToolbar()
    var picker  = UIPickerView()
    var arrLan = ["Arabic (Saudi Arabia) - ar-SA",
                  "Chinese (China) - zh-CN",
                  "Chinese (Hong Kong SAR China) - zh-HK",
                  "Chinese (Taiwan) - zh-TW",
                  "Czech (Czech Republic) - cs-CZ",
                  "Danish (Denmark) - da-DK",
                  "Dutch (Belgium) - nl-BE",
                  "Dutch (Netherlands) - nl-NL",
                  "English (Australia) - en-AU",
                  "English (Ireland) - en-IE",
                  "English (South Africa) - en-ZA",
                  "English (United Kingdom) - en-GB",
                  "English (United States) - en-US",
                  "Finnish (Finland) - fi-FI",
                  "French (Canada) - fr-CA",
                  "French (France) - fr-FR",
                  "German (Germany) - de-DE",
                  "Greek (Greece) - el-GR",
                  "Hebrew (Israel) - he-IL",
                  "Hindi (India) - hi-IN",
                  "Hungarian (Hungary) - hu-HU",
                  "Indonesian (Indonesia) - id-ID",
                  "Italian (Italy) - it-IT",
                  "Japanese (Japan) - ja-JP",
                  "Korean (South Korea) - ko-KR",
                  "Norwegian (Norway) - no-NO",
                  "Polish (Poland) - pl-PL",
                  "Portuguese (Brazil) - pt-BR",
                  "Portuguese (Portugal) - pt-PT",
                  "Romanian (Romania) - ro-RO",
                  "Russian (Russia) - ru-RU",
                  "Slovak (Slovakia) - sk-SK",
                  "Spanish (Mexico) - es-MX",
                  "Spanish (Spain) - es-ES",
                  "Swedish (Sweden) - sv-SE",
                  "Thai (Thailand) - th-TH",
                  "Turkish (Turkey) - tr-TR"]
    var arrAccent = ["ar-SA",
                  "zh-CN",
                  "zh-HK",
                  "zh-TW",
                  "cs-CZ",
                  "da-DK",
                  "nl-BE",
                  "nl-NL",
                  "en-AU",
                  "en-IE",
                  "en-ZA",
                  "en-GB",
                  "en-US",
                  "fi-FI",
                  "fr-CA",
                  "fr-FR",
                  "de-DE",
                  "el-GR",
                  "he-IL",
                  "hi-IN",
                  "hu-HU",
                  "id-ID",
                  "it-IT",
                  "ja-JP",
                  "ko-KR",
                  "no-NO",
                  "pl-PL",
                  "pt-BR",
                  "pt-PT",
                  "ro-RO",
                  "ru-RU",
                  "sk-SK",
                  "es-MX",
                  "es-ES",
                  "sv-SE",
                  "th-TH",
                  "tr-TR"]
    var selectedIndx = 12
    
    //MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.doInitialSettings()
    }

    //MARK: - IBAction Methods
    @IBAction func btnMicPressed(_ sender: Any) {
        if audioEngine.isRunning {
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.btnMic.isEnabled = false
            self.btnMic.setImage(UIImage(systemName: "mic"), for: .normal)
            if txtView.text.lowercased() == self.lblMsg.text?.lowercased(){
                print("Equal")
                self.showAlert(msg: "Equal")
            }else {
                print("not Equal")
                self.showAlert(msg: "not Equal")
            }
        } else {
            self.startRecording()
            self.btnMic.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        }
        
    }
    
    @IBAction func btnSettingsPressed(_ sender: Any) {
        picker = UIPickerView.init()
           picker.delegate = self
           picker.dataSource = self
           picker.backgroundColor = UIColor.white
        
           picker.setValue(UIColor.black, forKey: "textColor")
           picker.autoresizingMask = .flexibleWidth
           picker.contentMode = .center
           picker.frame = CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
           self.view.addSubview(picker)
                   
           toolBar = UIToolbar.init(frame: CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 50))
           toolBar.barStyle = .blackTranslucent
        toolBar.items = [UIBarButtonItem.init(title: "Cancel", style: .plain, target: self, action: #selector(onCancelButtonTapped)), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem.init(title: "Done", style: .done, target: self, action: #selector(onDoneButtonTapped))]
           self.view.addSubview(toolBar)
    }
    
    @objc func onCancelButtonTapped() {
        toolBar.removeFromSuperview()
        picker.removeFromSuperview()
    }
    
    @objc func onDoneButtonTapped() {
        toolBar.removeFromSuperview()
        picker.removeFromSuperview()
        self.setupSpeech()
    }
    
    //MARK: - Custom Class Methods
    func doInitialSettings(){
        self.setupSpeech()
    }

    func setupSpeech() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: self.arrAccent[selectedIndx]))
        self.btnMic.isEnabled = false
        self.speechRecognizer?.delegate = self

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
            @unknown default:
                fatalError()
            }

            OperationQueue.main.addOperation() {
                self.btnMic.isEnabled = isButtonEnabled
            }
        }
    }

    //------------------------------------------------------------------------------

    func startRecording() {

        // Clear all previous session data and cancel task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Create instance of audio session to record voice
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false

            if result != nil {

                self.lblMsg.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }

            if error != nil || isFinal {

                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.btnMic.isEnabled = true
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        self.audioEngine.prepare()

        do {
            try self.audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

        self.lblMsg.text = "Say something, I'm listening!"
    }

    func showAlert(msg: String){
        let alert = UIAlertController(title: "", message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true)
    }
}
//MARK: - SFSpeechRecognizerDelegate Methods
extension ViewController: SFSpeechRecognizerDelegate {

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.btnMic.isEnabled = true
        } else {
            self.btnMic.isEnabled = false
        }
    }
}
//MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
        
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return arrLan.count
    }
        
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return arrLan[row]
    }
        
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(arrLan[row])
        self.selectedIndx = row
    }
    
}
