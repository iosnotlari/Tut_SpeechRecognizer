import UIKit

class ViewController: UIViewController, SpeechRecognitionModalDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var micButton: UIButton!
    let speechObject: SpeechRecognitionModal = SpeechRecognitionModal()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechObject.delegate = self
        speechObject.customInit()
    }
    
    @IBAction func micButtonPressed(_ sender: UIButton) {
        speechObject.micButtonPressedFunc()
    }
    
    func didPrepareSpeech(finalString: String, isMicButtonEnabled: Bool) {
        self.titleLabel.text = finalString
        self.micButton.isEnabled = isMicButtonEnabled
        
        if   isMicButtonEnabled { self.view.backgroundColor = UIColor.lightGray }
        else { self.view.backgroundColor = UIColor.green }
    }
    
}
