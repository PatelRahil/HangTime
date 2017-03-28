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

class DataViewController: UIViewController {
    var isTrue = true
    let locationManager = CLLocationManager()


    @IBOutlet weak var passwordTextBox: UITextField!
    @IBOutlet weak var usernameTextBox: UITextField!

    
    @IBAction func LoginButton(_ sender: Any, forEvent event: UIEvent) {
        FIRAuth.auth()?.signIn(withEmail: usernameTextBox.text!, password: passwordTextBox.text!) { (user, error) in
            if error == nil {
                self.performSegue(withIdentifier: "LoginSegue", sender: sender)
            }
            else {
                print(error!)
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
        
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.dataLabel!.text = dataObject
    }


}

