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
                self.performSegue(withIdentifier: "LoginSegue", sender: sender)
            }
            else {
                if (String(describing: error!) == "Error Domain=FIRAuthErrorDomain Code=17009 \"The password is invalid or the user does not have a password.\" UserInfo={NSLocalizedDescription=The password is invalid or the user does not have a password., error_name=ERROR_WRONG_PASSWORD}") {
                    
                    print("******************\nInvalid Password\n*******************")
                }
                if (String(describing: error!) == "Error Domain=FIRAuthErrorDomain Code=17008 \"The email address is badly formatted.\" UserInfo={NSLocalizedDescription=The email address is badly formatted., error_name=ERROR_INVALID_EMAIL}") {
                    
                    print("******************\nInvalid Email\n*******************")
                }
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

}

