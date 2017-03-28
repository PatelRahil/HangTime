//
//  NewAccountController.swift
//  LE
//
//  Created by Rahil Patel on 11/12/16.
//  Copyright © 2016 Rahil. All rights reserved.
//

import UIKit
import Firebase

class NewAccountController: UIViewController, UITextFieldDelegate {
    var isTrue = true
    
    @IBAction func CreateAccountButton(_ sender: Any, forEvent event: UIEvent) {
        
        let email = EmailTextBox.text
        let password = PasswordTextbox.text
        FIRAuth.auth()?.createUser(withEmail: email!, password: password!) { (user, error) in
            // ...
            
        }
        
        
        
        if (isTrue) {
            performSegue(withIdentifier: "CreateAccountSegue", sender: sender)
        }
        else {
            
        }
    }
    
    @IBOutlet weak var EmailTextBox: UITextField!
    @IBOutlet weak var UsernameTextBox: UITextField!
    @IBOutlet weak var PasswordTextbox: UITextField!
    @IBOutlet weak var ConfirmPasswordTextBox: UITextField!
    
    @IBOutlet weak var emailButton: UILabel!
    
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
}
