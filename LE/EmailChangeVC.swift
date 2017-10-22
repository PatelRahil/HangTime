//
//  EmailChangeVC.swift
//  LE
//
//  Created by Rahil Patel on 10/22/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase

class EmailChangeVC:UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var changeEmailBtn: UIButton!
    @IBOutlet weak var instructionsLbl: UILabel!
    
    var email = ""
    var isAuthenticated = false
    
    override func viewDidLoad() {
        email = (FIRAuth.auth()?.currentUser?.email)!
        emailTextField.textAlignment = .center
        
        changeEmailBtn.backgroundColor = Colors.blueGreen
        changeEmailBtn.layer.cornerRadius = 5
        changeEmailBtn.addTarget(self, action: #selector(reauthenticateAccount), for: .touchUpInside)
    }
    
    private func handleErrors(error:Error) {
        
        print(error.localizedDescription)
        
        
        if error.localizedDescription == "The password is invalid or the user does not have a password." {
            let alertController = UIAlertController(title: "Invalid Password", message:
                "The password you entered does not match our records. Please try again.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            //Change from nil to allow user to reset password
            alertController.addAction(UIAlertAction(title: "Forgot Password?", style: UIAlertActionStyle.cancel, handler: { (alert) in
                self.performSegue(withIdentifier: "ResetPasswordSegue2", sender: nil)
            }))
            
            self.present(alertController, animated: true, completion: nil)
        }
        //badly formatted
        else if (error.localizedDescription == "The email address is badly formatted.") {
            let alertController = UIAlertController(title: "Invalid Email", message:
                "You have entered an invalid email", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
        else if (error.localizedDescription == "The email address is already in use by another account.") {
            let alertController = UIAlertController(title: "Invalid Email", message:
                "That email is already taken by another account.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
        else {
            if isAuthenticated {
                let alertController = UIAlertController(title: "Invalid Email", message:
                    "You have entered an invalid email", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            }
            else {
                let alertController = UIAlertController(title: "Invalid Password", message:
                    "You have entered the incorrect password", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func doAfterAuthenticated() {
        isAuthenticated = true
        emailTextField.text = email
        instructionsLbl.text = "Change Email"
        changeEmailBtn.setTitle("Change", for: .normal)
        changeEmailBtn.removeTarget(nil, action: nil, for: .allEvents)
        changeEmailBtn.addTarget(self, action: #selector(changeEmail), for: .touchUpInside)
    }
    
    @objc private func reauthenticateAccount() {
        let password = emailTextField.text
        if let password = password {
            let credential = FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
            let user = FIRAuth.auth()?.currentUser
            
            user?.reauthenticate(with: credential, completion: { (error) in
                if let error = error {
                    self.handleErrors(error: error)
                }
                else {
                    self.doAfterAuthenticated()
                }
            })
            
        }
        
        
    }
    
    @objc private func changeEmail() {
        let email = emailTextField.text
        
        if let newEmail = email {
            FIRAuth.auth()?.currentUser?.updateEmail(newEmail, completion: { (error) in
                if let error = error {
                    self.handleErrors(error: error)
                }
                else {
                    self.navigationController?.popViewController(animated: true)
                }
            })
        }
    }
}
