//
//  CreateAccountVC.swift
//  LE
//
//  Created by Rahil Patel on 8/4/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class CreateAccountVC:UIViewController {

    //Textfields
    let emailTxtField:UITextField = UITextField()             //button tag = 0
    let usernameTxtField:UITextField = UITextField()          //button tag = 1
    let passwordTxtField:UITextField = UITextField()          //button tag = 2
    let confirmPasswordTxtField:UITextField = UITextField()   //button tag = 2
    
    //Buttons
    let createAccountBtn:UIButton = UIButton()
    let nextBtn:UIButton = UIButton()
    let takePictureBtn:UIButton = UIButton()
    let photoAlbumBtn:UIButton = UIButton()
    
    //User data
    var username:String = ""
    var userID:String = ""
    
    //Profile Picture stuff
    var imgView:UIImageView = UIImageView(image: #imageLiteral(resourceName: "DefaultProfileImg"))
    
    //Other
    var uiLaidOut = false
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutBackground()
        layoutUIElements()
        configureButtons()
        
        view.addSubview(emailTxtField)
        view.addSubview(usernameTxtField)
        view.addSubview(passwordTxtField)
        view.addSubview(confirmPasswordTxtField)
        view.addSubview(nextBtn)
        view.addSubview(createAccountBtn)
        view.addSubview(takePictureBtn)
        view.addSubview(photoAlbumBtn)
        view.addSubview(imgView)
        
        createAccountBtn.isHidden = true
        imgView.isHidden = true
        takePictureBtn.isHidden = true
        photoAlbumBtn.isHidden = true
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
    
    private func layoutUIElements() {
        let fieldWidth:CGFloat = view.frame.width / 2
        let fieldHeight:CGFloat = 40
        let fieldXPos:CGFloat = view.frame.width / 4
        let fieldYPos:CGFloat = view.frame.height / 2 - fieldHeight
        let fieldFrame:CGRect = CGRect(x: fieldXPos, y: fieldYPos, width: fieldWidth, height: fieldHeight)
        passwordTxtField.frame = fieldFrame
        
        let gap:CGFloat = 10
        let confirmPassYPos:CGFloat = view.frame.height / 2 + gap
        let confirmPassFrame:CGRect = CGRect(x: fieldXPos, y: confirmPassYPos, width: fieldWidth, height: fieldHeight)
        confirmPasswordTxtField.frame = confirmPassFrame
        
        let usernameFieldYPos:CGFloat = fieldYPos - fieldHeight - gap
        let usernameFieldFrame:CGRect = CGRect(x: fieldXPos, y: usernameFieldYPos, width: fieldWidth, height: fieldHeight)
        usernameTxtField.frame = usernameFieldFrame
        
        let emailFieldYPos:CGFloat = usernameFieldYPos - fieldHeight - gap
        let emailFieldFrame:CGRect = CGRect(x: fieldXPos, y: emailFieldYPos, width: fieldWidth, height: fieldHeight)
        emailTxtField.frame = emailFieldFrame
        
        let imgViewYPos:CGFloat = fieldYPos - fieldWidth - gap
        let imgViewFrame:CGRect = CGRect(x: fieldXPos, y: imgViewYPos, width: fieldWidth, height: fieldWidth)
        imgView.frame = imgViewFrame
        
        emailTxtField.adjustsFontSizeToFitWidth = true
        emailTxtField.clearButtonMode = .whileEditing
        emailTxtField.textAlignment = .center
        emailTxtField.placeholder = "Email"
        emailTxtField.delegate = self
        addBorder(textField: emailTxtField)
        
        usernameTxtField.clearButtonMode = .whileEditing
        usernameTxtField.textAlignment = .center
        usernameTxtField.placeholder = "Username"
        usernameTxtField.delegate = self
        addBorder(textField: usernameTxtField)
        
        passwordTxtField.clearButtonMode = .whileEditing
        passwordTxtField.textAlignment = .center
        passwordTxtField.placeholder = "Password"
        passwordTxtField.delegate = self
        passwordTxtField.isSecureTextEntry = true
        addBorder(textField: passwordTxtField)
        
        confirmPasswordTxtField.clearButtonMode = .whileEditing
        confirmPasswordTxtField.textAlignment = .center
        confirmPasswordTxtField.placeholder = "Confirm Password"
        confirmPasswordTxtField.delegate = self
        confirmPasswordTxtField.isSecureTextEntry = true
        addBorder(textField: confirmPasswordTxtField)
        
        imgView.layer.cornerRadius = imgView.frame.width/2
        imgView.layer.masksToBounds = true
        
    }
    
    private func configureButtons() {
        let gap:CGFloat = 10
        let buttonWidth:CGFloat = view.frame.width/2
        let buttonHeight:CGFloat = 40
        let buttonXPos:CGFloat = view.frame.width/4
        let buttonYPos:CGFloat = confirmPasswordTxtField.frame.maxY + gap
        let buttonFrame:CGRect = CGRect(x: buttonXPos, y: buttonYPos, width: buttonWidth, height: buttonHeight)
        
        createAccountBtn.frame = buttonFrame
        nextBtn.frame = buttonFrame
        
        let takePictureBtnWidth:CGFloat = 3 * buttonWidth/4
        let takePictureBtnXPos:CGFloat = view.frame.width/2 + gap/2
        let takePictureFrame:CGRect = CGRect(x: takePictureBtnXPos, y: confirmPasswordTxtField.frame.minY, width: takePictureBtnWidth, height: buttonHeight)
        takePictureBtn.frame = takePictureFrame
        
        let photoAlbumXPos:CGFloat = view.frame.width/2 - gap/2 - takePictureBtnWidth
        let photoAlbumFrame:CGRect = CGRect(x: photoAlbumXPos, y: confirmPasswordTxtField.frame.minY, width: takePictureBtnWidth, height: buttonHeight)
        photoAlbumBtn.frame = photoAlbumFrame
        
        
        nextBtn.backgroundColor = Colors.blueGreen
        nextBtn.layer.cornerRadius = 8
        nextBtn.tag = 0
        nextBtn.setTitle("Create Account", for: .normal)
        nextBtn.addTarget(self, action: #selector(nextTapped(sender:)), for: .touchUpInside)
        
        createAccountBtn.backgroundColor = Colors.blueGreen
        createAccountBtn.layer.cornerRadius = 8
        createAccountBtn.setTitle("Skip", for: .normal)
        createAccountBtn.addTarget(self, action: #selector(createAccountTapped(sender:)), for: .touchUpInside)
        
        takePictureBtn.backgroundColor = Colors.blueGreen
        takePictureBtn.layer.cornerRadius = 8
        takePictureBtn.setTitle("Take Picture", for: .normal)
        takePictureBtn.addTarget(self, action: #selector(takePhoto(sender:)), for: .touchUpInside)
        
        photoAlbumBtn.backgroundColor = Colors.blueGreen
        photoAlbumBtn.layer.cornerRadius = 8
        photoAlbumBtn.setTitle("Choose Photo", for: .normal)
        photoAlbumBtn.addTarget(self, action: #selector(choosePhoto(sender:)), for: .touchUpInside)
    }
    
    private func addBorder(textField:UITextField) {
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.darkGray.cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
    }
    
    private func createUser(completion: @escaping (_ success:Bool) -> Void) {
        print("Creating user...")
        let email = (emailTxtField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!
        let password = (passwordTxtField.text)!
        let confirmPassword = (confirmPasswordTxtField.text)!
        let username = (usernameTxtField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!
        
        guard case let _email = email, _email != "" else {
            print("Email is empty")
            completion(false)
            return
        }
        guard case let _username = username, _username != "" else {
            print("Username is empty")
            completion(false)
            return
        }
        if username.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil {
            print("Invalid username")
            completion(false)
            return
        }
        guard case let tempPassword = password, tempPassword != "" else {
            print("Password is empty")
            completion(false)
            return
        }
        guard case let _confirmPassword = confirmPassword, _confirmPassword != "" else {
            print("confirm password is empty")
            completion(false)
            return
        }
        guard case let _password = tempPassword, _password == _confirmPassword else {
            print("passwords don't match")
            completion(false)
            return
        }
        print(username)
        FIRDatabase.database().reference(withPath: "Users").queryOrdered(byChild: "username").queryEqual(toValue: username).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                print("Username is taken :(")
                completion(false)
            }
            else {
                print("Username is not taken!")
                self.username = username
                FIRAuth.auth()?.createUser(withEmail: _email, password: _password, completion: { (user, error) in
                    if let invalidError = error {
                        self.handleError(error: invalidError)
                        completion(false)
                    }
                    else {
                        completion(true)
                    }
                })
            }
            
        })
        
    }
    
    private func handleError(error:Error) {
        print(error)
    }
    
    func showPicker(withType sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true
        self.present(picker, animated: true, completion: nil)
    }
    
    @objc private func nextTapped(sender:UIButton) {
        if let user = FIRAuth.auth()?.currentUser {
            print("LOGGED IN")
            print(user.uid)
        }
        print(sender.tag)
        switch sender.tag {
        case 0:
            createUser(completion: { (success) in
                if success {
                    self.emailTxtField.isHidden = true
                    self.passwordTxtField.isHidden = true
                    self.confirmPasswordTxtField.isHidden = true
                    self.usernameTxtField.isHidden = true
                    self.nextBtn.isHidden = true
                    self.createAccountBtn.isHidden = false
                    //show profile picture stuff
                    self.imgView.isHidden = false
                    self.photoAlbumBtn.isHidden = false
                    self.takePictureBtn.isHidden = false
                    //create user in database
                    let user = FIRAuth.auth()?.currentUser
                    self.userID = (user?.uid)!
                    let userRef = FIRDatabase.database().reference(withPath: "Users/User: \(self.userID)")
                    let currentUser:User = User(uid: self.userID, username: self.username)
                    currentUser.addToken(token: AppData.token)
                    
                    userRef.setValue(currentUser.toAnyObject())
                    UserData.updateData(withUser: currentUser)
                    sender.tag = sender.tag + 1
                }
                
            })
            
            
        case 1:
            //hide profile picture stuff in case there is a step after setting up you profile picture
            
            sender.tag = sender.tag + 1
        default:
            return
        }
    }
    
    @objc private func createAccountTapped(sender:UIButton) {
        print("create acount")
        self.performSegue(withIdentifier: "CreateEventSegue", sender: nil)
    }
    
    @objc private func takePhoto(sender:UIButton) {
        showPicker(withType: .camera)
    }
    
    @objc private func choosePhoto(sender:UIButton) {
        showPicker(withType: .photoLibrary)
    }
}

extension CreateAccountVC:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension CreateAccountVC:UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let storageRef = FIRStorage.storage().reference()

        dismiss(animated: true, completion: nil)
        if let profilePic = info[UIImagePickerControllerEditedImage] as? UIImage {
            let user:User = User(data: UserData())
            var data = NSData()
            data = UIImageJPEGRepresentation(profilePic, 0.8)! as NSData
            let filePath = "Users/User: \(UserData.userID!)/profilePicture"
            let metaData = FIRStorageMetadata()
            metaData.contentType = "image/jpg"
            storageRef.child(filePath).put(data as Data, metadata: metaData){(metaData,error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }else{
                    //store downloadURL
                    let downloadURL = metaData!.downloadURL()!.absoluteString
                    //store downloadURL at database
                    FIRDatabase.database().reference().child("Users").child("User: \(UserData.userID!)").updateChildValues(["profilePicture": downloadURL])
                    user.profilePicDownloadLink = downloadURL
                    
                }
            }
            
            self.imgView.image = profilePic
            UserData.updateData(withUser: user, profilePic: profilePic)
            createAccountBtn.setTitle("Finish", for: .normal)
        }
        else {
            //not a UIImage or for some reason profilePic is nil
            print(info)
        }
    }
}
