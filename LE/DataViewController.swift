//
//  DataViewController.swift
//  LE
//
//  Created by Rahil Patel on 11/12/16.
//  Copyright © 2016 Rahil. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps

class DataViewController: UIViewController, UITextFieldDelegate {
    var isTrue = true
    let locationManager = CLLocationManager()
    let childRef = FIRDatabase.database().reference(withPath: "Users")
    
    var currentUser:User? = nil

    @IBOutlet weak var passwordTextBox: UITextField!
    @IBOutlet weak var usernameTextBox: UITextField!

   /*
    @IBAction func LoginButton(_ sender: Any, forEvent event: UIEvent) {
        print("HEY?")
        FIRAuth.auth()?.signIn(withEmail: usernameTextBox.text!, password: passwordTextBox.text!) { (user, error) in
            print("w_orked")
            if error == nil {
                self.performSegue(withIdentifier: "LoginSegue", sender: sender)
                print("worked")
            }
            else {
                print(error!)
            }
        }
        
    } 
    */
    @IBAction func LoginButton(_ sender: Any) {
            FIRAuth.auth()?.signIn(withEmail: usernameTextBox.text!, password: passwordTextBox.text!) { (user, error) in
                if error == nil {
                    //Valid Email and Password
                    let userID = FIRAuth.auth()?.currentUser?.uid
                
                    self.childRef.observe(.value, with: { snapshot in
                        //print(snapshot.value as! Dictionary<String,Any>)
                        for item in snapshot.children.allObjects as! [FIRDataSnapshot] {
                            print("***************************")
                            let dict = item.value as! Dictionary<String,Any>
                            if (dict["UserID"] as? String == userID) {
                                self.currentUser = User(snapshot: item)
                            }
                            //currentUser = User(snapshot: )
                            self.performSegue(withIdentifier: "LoginSegue", sender: sender)
                        }
                    })
                
                }
                else {
                
                    print("###################\n\(error.debugDescription)\n###################")
                    self.respondToError(error: error!)
                }
            }
    }

    @IBAction func newAccountButton(_ sender: UIButton, forEvent event: UIEvent) {
        try! FIRAuth.auth()!.signOut()
        self.performSegue(withIdentifier: "NewAccountSegue", sender: sender)
    }
    
    @IBOutlet weak var dontHaveAccountLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!

    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    
    var dataObject: String = ""


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.passwordTextBox.delegate = self;
        self.usernameTextBox.delegate = self;
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.dataLabel!.text = dataObject
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func respondToError(error:Error) {
        if (String(describing: error) == "Error Domain=FIRAuthErrorDomain Code=17009 \"The password is invalid or the user does not have a password.\" UserInfo={NSLocalizedDescription=The password is invalid or the user does not have a password., error_name=ERROR_WRONG_PASSWORD}" || String(describing: error) == "Error Domain=FIRAuthErrorDomain Code=17011 \"There is no user record corresponding to this identifier. The user may have been deleted.\" UserInfo={NSLocalizedDescription=There is no user record corresponding to this identifier. The user may have been deleted., error_name=ERROR_USER_NOT_FOUND}") {
            
            print("******************\nInvalid Password\n*******************")
            let alertController = UIAlertController(title: "Invalid Password", message:
                "The email and password you entered do not match our records. Please try again.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            //Change from nil to allow user to reset password
            alertController.addAction(UIAlertAction(title: "Forgot password?", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
            
        }
        if (String(describing: error) == "Error Domain=FIRAuthErrorDomain Code=17008 \"The email address is badly formatted.\" UserInfo={NSLocalizedDescription=The email address is badly formatted., error_name=ERROR_INVALID_EMAIL}") {
            
            print("******************\nInvalid Email\n*******************")
            let alertController = UIAlertController(title: "Invalid Email Address", message:
                "Please enter a valid email address.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        else if (self.passwordTextBox.text! == "") {
            let alertController = UIAlertController(title: "Please enter a password", message:
                "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }

}

