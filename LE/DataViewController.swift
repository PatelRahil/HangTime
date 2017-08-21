//
//  DataViewController.swift
//  LE
//
//  Created by Rahil Patel on 11/12/16.
//  Copyright © 2016 Rahil. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import GoogleMaps

class DataViewController: UIViewController, UITextFieldDelegate {
    var isLoading = false
    let locationManager = CLLocationManager()
    var authListener:FIRAuthStateDidChangeListenerHandle?
    var childRef:FIRDatabaseReference?
    var storageRef:FIRStorageReference?
    
    var currentUser:User? = nil

    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var passwordTextBox: UITextField!
    @IBOutlet weak var usernameTextBox: UITextField!
    
    @IBAction func LoginButton(_ sender: Any) {
            FIRAuth.auth()?.signIn(withEmail: usernameTextBox.text!, password: passwordTextBox.text!) { (user, error) in
                if error == nil {
                    //Valid Email and Password
                    self.isLoading = false
                    self.loadUser(sender: sender)
                }
                else {
                
                    self.respondToError(error: error!)
                }
            }
    }

    @IBAction func newAccountButton(_ sender: UIButton, forEvent event: UIEvent) {
        try! FIRAuth.auth()!.signOut()
        self.performSegue(withIdentifier: "CreateAccountSegue", sender: sender)
    }
    
    @IBOutlet weak var dontHaveAccountLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!

    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    
    var dataObject: String = ""


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        checkIfUserIsLoggedIn()
        
        self.passwordTextBox.delegate = self
        self.usernameTextBox.delegate = self
        
        childRef = FIRDatabase.database().reference(withPath: "Users")
        storageRef = FIRStorage.storage().reference()
        
        loginView.layer.cornerRadius = 5
        inputContainerView.layer.cornerRadius = 5
        loginBtn.backgroundColor = Colors.blueGreen
        loginBtn.layer.cornerRadius = 5
        loginBtn.setTitleColor(UIColor.white, for: .normal)
        loginBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(x: 0, y: 0, width: self.view.frame.width, height: loginView.frame.minY)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: loginView.frame.minY/view.frame.maxY)
        gradient.locations = [0.0,2.0]
        view.layer.insertSublayer(gradient, at: 0)
        print("FRAMES")
        print(loginBtn.frame)
        print(inputContainerView.frame)
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
    
    private func respondToError(error:Error) {
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
    
    private func loadUser(sender: Any?) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        if let userID = userID {
        self.childRef?.child("User: \(userID)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                    self.currentUser = User(snapshot: snapshot)
                    self.currentUser?.addToken(token: AppData.token)
                    let currentUserRef = FIRDatabase.database().reference(withPath: "Users/User: \(self.currentUser!.getUserID())")
                    print(AppData.token)
                    currentUserRef.setValue(self.currentUser!.toAnyObject())
                
                    var profilePic:UIImage = #imageLiteral(resourceName: "DefaultProfileImg")
                    if self.currentUser!.profilePicDownloadLink != "" {
                        print("ProfilePicDownloadLink is not nil")
                        let filePath = "Users/User: \(self.currentUser!.getUserID())/\("profilePicture")"
                        self.storageRef!.child(filePath).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
                            if error == nil {
                                let userPhoto = UIImage(data: data!)
                                profilePic = userPhoto!
                            }
                            else {
                                profilePic = #imageLiteral(resourceName: "DefaultProfileImg")
                            }
                            
                            UserData.updateData(withUser: self.currentUser!, profilePic: profilePic)
                            print("ABOUT TO PERFORM SEGUE")
                            self.performSegue(withIdentifier: "LoginSegue", sender: sender)
                        })
                        
                    }
                    else {
                        
                        UserData.updateData(withUser: self.currentUser!, profilePic: profilePic)
                        self.performSegue(withIdentifier: "LoginSegue", sender: sender)
                    }
            }
            else {
                print("TRIED TO LOG IN BUT ACCOUNT HAS NO DATA")
                do {
                try FIRAuth.auth()?.signOut()
                }
                catch {
                    print("user not signed on in the first place")
                }
            }
        })
        /*
        self.childRef!.observeSingleEvent(of: .value, with: { snapshot in
            print("\n\n\n\nLOGGING IN USER\(snapshot.value)\n\n\n\n")
            for item in snapshot.children.allObjects as! [FIRDataSnapshot] {
                let dict = item.value as! Dictionary<String,Any>
                if (dict["UserID"] as? String == userID) {
                    self.currentUser = User(snapshot: item)
                    
                    var profilePic:UIImage = #imageLiteral(resourceName: "DefaultProfileImg")
                    if self.currentUser!.profilePicDownloadLink != "" {
                        print("ProfilePicDownloadLink is not nil")
                        let filePath = "Users/User: \(self.currentUser!.getUserID())/\("profilePicture")"
                        self.storageRef!.child(filePath).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
                            if error == nil {
                                let userPhoto = UIImage(data: data!)
                                profilePic = userPhoto!
                            }
                            else {
                                profilePic = #imageLiteral(resourceName: "DefaultProfileImg")
                            }
                            UserData.updateData(withUser: self.currentUser!, profilePic: profilePic)
                            print("ABOUT TO PERFORM SEGUE")
                            self.performSegue(withIdentifier: "LoginSegue", sender: sender)
                        })
                        
                    }
                    else {
                        
                        UserData.updateData(withUser: self.currentUser!, profilePic: profilePic)
                        self.performSegue(withIdentifier: "LoginSegue", sender: sender)
                    }
                }
                
            }
        })
            */
        }
    }
    
    private func checkIfUserIsLoggedIn() {
            authListener = FIRAuth.auth()?.addStateDidChangeListener { auth, user in
                if let _ = user {
                // User is signed in.
                    if !self.isLoading {
                        self.loadUser(sender: nil)
                        self.isLoading = true
                    }

                } else {
                // No user is signed in.
                    print("USER NOT LOGGED IN")
                    FIRAuth.auth()?.removeStateDidChangeListener(self.authListener!)
                }
            }
    }

    
}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
    }
}
