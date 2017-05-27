//
//  NewAccountController.swift
//  LE
//
//  Created by Rahil Patel on 11/12/16.
//  Copyright © 2016 Rahil. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class NewAccountController: UIViewController, UITextFieldDelegate {
    var isTrue = true
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Users")
    
    
    @IBOutlet weak var PasswordMismatchLbl: UILabel!
    @IBOutlet weak var EmailTextBox: UITextField!
    @IBOutlet weak var UsernameTextBox: UITextField!
    @IBOutlet weak var PasswordTextbox: UITextField!
    @IBOutlet weak var ConfirmPasswordTextBox: UITextField!
    
    @IBOutlet weak var usernameTakenLbl: UILabel!
    @IBOutlet weak var emailButton: UILabel!
    
    @IBAction func CreateAccountButton(_ sender: Any, forEvent event: UIEvent) {
        let email = EmailTextBox.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let password = PasswordTextbox.text
        let username = UsernameTextBox.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        var isTaken = false
        _ = self.rootRef.child("Users").queryOrdered(byChild: "username").queryEqual(toValue:username).observeSingleEvent(of: .value, with: { (snapshot) in
            if ( snapshot.value is NSNull ) {
                // No user
            }
            else {
                let user: Dictionary<String,Any> = snapshot.value as! Dictionary<String,Any>
                for (_,data) in user {
                    let dataDic:Dictionary<String,Any> = data as! Dictionary<String,Any>
                    for (key,value) in dataDic {
                        if key == "username" && value as? String == username {
                            isTaken = true
                        }
                    }
                }
            }
            
        if (isTaken || username == "") {
            self.usernameTakenLbl.text = "Sorry, that username is already taken."
            print("#######################")
        }
        else if (username!.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil) {
            let alertController = UIAlertController(title: "Invalid Username", message:
                "Usernames can only contain letters and digits", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        else {
            self.usernameTakenLbl.text = ""
            FIRAuth.auth()?.createUser(withEmail: email!, password: password!) { (user, error) in
                if (error == nil){
                    self.PasswordMismatchLbl.text = ""
                    let userID = FIRAuth.auth()?.currentUser?.uid
                    let currUser:User = User.init(uid: userID!, username: username!)
                    let eventRef = self.childRef.child("User: " + userID!)
                    eventRef.setValue(currUser.toAnyObject())
                
                    self.performSegue(withIdentifier: "CreateAccountSegue", sender: sender)
                }
                else {
                    print("**********************************")
                    print(error!)
                    self.respondToError(error: error!)
                }
            
            }
        }
            
        }, withCancel: { (error) in
            
            // An error occurred
        })
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.PasswordTextbox.delegate = self;
        self.EmailTextBox.delegate = self;
        self.ConfirmPasswordTextBox.delegate = self;
        self.UsernameTextBox.delegate = self;

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func respondToError(error:Error) {
        if (String(describing: error) == "Error Domain=FIRAuthErrorDomain Code=17008 \"The email address is badly formatted.\" UserInfo={NSLocalizedDescription=The email address is badly formatted., error_name=ERROR_INVALID_EMAIL}") {
            
            print("******************\nInvalid Email\n*******************")
            let alertController = UIAlertController(title: "Invalid Email Address", message:
                "Please enter a valid email address.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        else if (String(describing: error) == "Error Domain=FIRAuthErrorDomain Code=17007 \"The email address is already in use by another account.\" UserInfo={NSLocalizedDescription=The email address is already in use by another account., error_name=ERROR_EMAIL_ALREADY_IN_USE}") {
            let alertController = UIAlertController(title: "Email already in use", message: "This email is already in use. Try another one or attempt to recover your password.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            alertController.addAction(UIAlertAction(title: "Reset Password", style: UIAlertActionStyle.cancel,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        else if (String(describing: error) == "Error Domain=FIRAuthErrorDomain Code=17026 \"The password must be 6 characters long or more.\" UserInfo={NSLocalizedDescription=The password must be 6 characters long or more., error_name=ERROR_WEAK_PASSWORD, NSLocalizedFailureReason=Password should be at least 6 characters}") {
            let alertController = UIAlertController(title: "Weak password", message:
                "Password must be 6 or more characters", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        else if (self.PasswordTextbox.text! == "") {
            let alertController = UIAlertController(title: "Please enter a password", message:
                "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        else if (self.PasswordTextbox.text! != self.ConfirmPasswordTextBox.text!) {
            self.PasswordMismatchLbl.text = "Passwords do not match"
        }
    }
}
