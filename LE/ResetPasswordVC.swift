//
//  ResetPasswordVC.swift
//  LE
//
//  Created by Rahil Patel on 9/10/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase

class ResetPasswordVC:UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var emailTextbox: UITextField!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    
    override func viewDidLoad() {
        
        layoutBackground()
        layoutButtons()
        instructionsLabel.adjustsFontSizeToFitWidth = true
        instructionsLabel.textColor = Colors.cinnabar
        titleLabel.font = UIFont(name: "Copperplate-Light", size: 32)
        
    }
    
    private func layoutBackground() {
        let gradient = CAGradientLayer()
        gradient.frame =  view.frame
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.locations = [0.0,2.0]
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    private func layoutButtons() {
        
        resetButton.backgroundColor = Colors.darkMintGreen
        resetButton.setTitleColor(UIColor.white, for: .normal)
        resetButton.layer.cornerRadius = 5
        resetButton.showsTouchWhenHighlighted = true
        resetButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        resetButton.layer.shadowOpacity = 0.5
        resetButton.layer.shadowRadius = 2
        resetButton.addTarget(self, action: #selector(resetPassword), for: .touchUpInside)
        
        backButton.backgroundColor = Colors.blueGreen
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.showsTouchWhenHighlighted = true
        backButton.layer.cornerRadius = 5
        backButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        backButton.layer.shadowOpacity = 0.5
        backButton.layer.shadowRadius = 2
    }
    
    @objc private func resetPassword() {
        FIRAuth.auth()?.sendPasswordReset(withEmail: emailTextbox.text!, completion: { (error) in
            if error == nil {
                self.instructionsLabel.textColor = UIColor.black
                self.instructionsLabel.text = "An email was sent with a link to reset your password."
                self.resetButton.setTitle("Reset Again", for: .normal)
            }
            else {
                print("\n\(error!.localizedDescription)")
                
                if error!.localizedDescription == "The email address is badly formatted." {
                    self.instructionsLabel.text = "The email address not formatted properly."
                }
                else if error!.localizedDescription == "There is no user record corresponding to this identifier. The user may have been deleted." {
                    self.instructionsLabel.text = "We can't find an account associated with that email. Try again."
                }
                else {
                    self.instructionsLabel.text = "That email is invalid, try again."
                }
                
            }
        })
    }
}
