//
//  ViewController.swift
//  MyGallery
//
//  Created by Никита Суровцев on 15.08.23.
//

import UIKit
import Lottie
import LocalAuthentication

class MainLoginViewController: UIViewController {
    
    private let animationView: LottieAnimationView = {
      let lottieAnimationView = LottieAnimationView(name: "animation_llciamgl")
      lottieAnimationView.backgroundColor = UIColor(red: 52/255, green: 144/255, blue: 220/255, alpha: 1.0)
      return lottieAnimationView
    }()

    @IBOutlet weak var passwordLabel: UILabel!
    
    @IBOutlet var passwordNumbers: [UIButton]!
    
    @IBOutlet weak var removeNumber: UIButton!
    
    @IBOutlet weak var faceID: UIButton!
    
    var enteredPassword = "" {
        didSet {
            updatePasswordLabel()
        }
    }
    var correctPassword = "1234"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLottieLaunchScreen()

        updatePasswordLabel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enteredPassword = ""
        
    }
    

    func setupLottieLaunchScreen() {
          view.addSubview(animationView)

          animationView.frame = view.bounds
          animationView.center = view.center
          animationView.alpha = 1

          animationView.play { _ in
            UIView.animate(withDuration: 0.3, animations: {
              self.animationView.alpha = 0
            }, completion: { _ in
              self.animationView.isHidden = true
              self.animationView.removeFromSuperview()
            })
          }
    }
    
    func updatePasswordLabel() {
        guard enteredPassword.count > 0 else {
            passwordLabel.text = "Enter Password"
            return
        }
        passwordLabel.text = enteredPassword
        
        if enteredPassword == correctPassword {
            confirmPassword()
        }
    }

    func confirmPassword() {
        
        let destination = GalleryViewController()
        destination.modalPresentationStyle = .fullScreen
        present(destination, animated: true)
        
    }
    
    
    @IBAction func enterNumToPassword(_ sender: UIButton) {
        enteredPassword.append("\(sender.tag)")
    }
    
    @IBAction func removeNumber(_ sender: Any) {
        enteredPassword.removeLast()
    }
    
    @IBAction func faceID(_ sender: Any) {
        
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in

                DispatchQueue.main.async {
                    if success {
                        self?.confirmPassword()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }

}

