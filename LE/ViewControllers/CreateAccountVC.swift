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
    let backButton:UIButton = UIButton()
    
    //User data
    var username:String = ""
    var userID:String = ""
    
    //Profile Picture stuff
    var imgView:UIImageView = UIImageView(image: #imageLiteral(resourceName: "DefaultProfileImg"))
    
    //Other
    var uiLaidOut = false
    let passwordInfoLbl:UILabel = UILabel()
    let usernameInfoLbl:UILabel = UILabel()
    let agreementView:UITextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutBackground()
        layoutUIElements()
        configureButtons()
        layoutAgreement()
        
        view.addSubview(emailTxtField)
        view.addSubview(usernameTxtField)
        view.addSubview(passwordTxtField)
        view.addSubview(confirmPasswordTxtField)
        view.addSubview(passwordInfoLbl)
        view.addSubview(usernameInfoLbl)
        view.addSubview(nextBtn)
        view.addSubview(agreementView)
        view.addSubview(createAccountBtn)
        view.addSubview(takePictureBtn)
        view.addSubview(photoAlbumBtn)
        view.addSubview(backButton)
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
        
        let passwordInfoLblYPos:CGFloat = view.frame.height - (fieldHeight/2)
        let passwordInfoLblFrame:CGRect = CGRect(x: view.frame.width/4, y: passwordInfoLblYPos, width: view.frame.width/2, height: (fieldHeight/2))
        passwordInfoLbl.frame = passwordInfoLblFrame
        
        let usernameInfoLblYPos:CGFloat = view.frame.height - (2*(fieldHeight/2))
        let usernameInfoLblFrame:CGRect = CGRect(x: view.frame.width/4, y: usernameInfoLblYPos, width: view.frame.width/2, height: (fieldHeight/2))
        usernameInfoLbl.frame = usernameInfoLblFrame
        
        passwordInfoLbl.adjustsFontSizeToFitWidth = true
        usernameInfoLbl.adjustsFontSizeToFitWidth = true
        passwordInfoLbl.text = "**Password must be 6 or more characters"
        usernameInfoLbl.text = "*Username can only contain letters and numbers"
        passwordInfoLbl.textAlignment = .center
        usernameInfoLbl.textAlignment = .center
        
        emailTxtField.adjustsFontSizeToFitWidth = true
        emailTxtField.clearButtonMode = .whileEditing
        emailTxtField.textAlignment = .center
        emailTxtField.placeholder = "Email"
        emailTxtField.delegate = self
        addBorder(textField: emailTxtField)
        
        usernameTxtField.clearButtonMode = .whileEditing
        usernameTxtField.textAlignment = .center
        usernameTxtField.placeholder = "Username*"
        usernameTxtField.delegate = self
        addBorder(textField: usernameTxtField)
        
        passwordTxtField.clearButtonMode = .whileEditing
        passwordTxtField.textAlignment = .center
        passwordTxtField.placeholder = "Password**"
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
        
        backButton.frame = CGRect(x: 5, y: 28, width: 50, height: 30)
        backButton.backgroundColor = Colors.darkMintGreen
        backButton.layer.cornerRadius = 5
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.setTitle("Back", for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        backButton.showsTouchWhenHighlighted = true
        backButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        backButton.layer.shadowOpacity = 0.5
        backButton.layer.shadowRadius = 2
        backButton.addTarget(self, action: #selector(backTapped(sender:)), for: .touchUpInside)
        
        nextBtn.backgroundColor = Colors.blueGreen
        nextBtn.layer.cornerRadius = 8
        nextBtn.tag = 0
        nextBtn.setTitle("Create Account", for: .normal)
        nextBtn.layer.shadowOffset = CGSize(width: 1, height: 1)
        nextBtn.layer.shadowOpacity = 0.5
        nextBtn.layer.shadowRadius = 2
        nextBtn.addTarget(self, action: #selector(nextTapped(sender:)), for: .touchUpInside)
        
        createAccountBtn.backgroundColor = Colors.blueGreen
        createAccountBtn.layer.cornerRadius = 8
        createAccountBtn.setTitle("Skip", for: .normal)
        createAccountBtn.layer.shadowOffset = CGSize(width: 1, height: 1)
        createAccountBtn.layer.shadowOpacity = 0.5
        createAccountBtn.layer.shadowRadius = 2
        createAccountBtn.addTarget(self, action: #selector(createAccountTapped(sender:)), for: .touchUpInside)
        
        takePictureBtn.backgroundColor = Colors.blueGreen
        takePictureBtn.layer.cornerRadius = 8
        takePictureBtn.setTitle("Take Picture", for: .normal)
        takePictureBtn.layer.shadowOffset = CGSize(width: 1, height: 1)
        takePictureBtn.layer.shadowOpacity = 0.5
        takePictureBtn.layer.shadowRadius = 2
        takePictureBtn.addTarget(self, action: #selector(takePhoto(sender:)), for: .touchUpInside)
        
        photoAlbumBtn.backgroundColor = Colors.blueGreen
        photoAlbumBtn.layer.cornerRadius = 8
        photoAlbumBtn.setTitle("Choose Photo", for: .normal)
        photoAlbumBtn.layer.shadowOffset = CGSize(width: 1, height: 1)
        photoAlbumBtn.layer.shadowOpacity = 0.5
        photoAlbumBtn.layer.shadowRadius = 2
        photoAlbumBtn.addTarget(self, action: #selector(choosePhoto(sender:)), for: .touchUpInside)
    }
    
    private func layoutAgreement() {
        let xPos:CGFloat = 0
        let yPos:CGFloat = nextBtn.frame.maxY
        let width:CGFloat = view.frame.width
        let height:CGFloat = nextBtn.frame.height
        let frame:CGRect = CGRect(x: xPos, y: yPos, width: width, height: height)
        agreementView.frame = frame
        
        let agreementText = "By creating an account, you agree to the Terms and Conditions and the Privacy Policy"
        let termsAndConditionsRange:NSRange = NSMakeRange(41, 20) //agreementText.range(of: "Terms and Conditions")
        let privacyPolicyRange:NSRange = NSMakeRange(70, 14)//agreementText.range(of: "Privacy Policy")
        
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .center
        
        let attributedAgreementText = NSMutableAttributedString(string: agreementText, attributes: [NSAttributedStringKey.paragraphStyle: paragraphStyle])
        
        attributedAgreementText.addAttribute(NSAttributedStringKey.link, value: "https://www.invyteapp.com/tc", range: termsAndConditionsRange)
        //attributedAgreementText.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(value:1), range: termsAndConditionsRange)
        //attributedAgreementText.addAttribute(NSUnderlineColorAttributeName, value: UIColor.orange, range: termsAndConditionsRange)
        attributedAgreementText.addAttribute(NSAttributedStringKey.link, value: /*"www.invyteapp.com/privacy"*/"https://www.invyteapp.com/privacy", range: privacyPolicyRange)
        //attributedAgreementText.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(value:1), range: privacyPolicyRange)
        //attributedAgreementText.addAttribute(NSUnderlineColorAttributeName, value: UIColor.orange, range: privacyPolicyRange)

        agreementView.textAlignment = .center
        agreementView.attributedText = attributedAgreementText
        agreementView.backgroundColor = UIColor.clear
        agreementView.dataDetectorTypes = .link
        agreementView.isEditable = false
        agreementView.isSelectable = true
        agreementView.delegate = self
        
        
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
            presentAlert(alert: "Invalid Email" , message: "Please enter and email.")
            completion(false)
            return
        }
        guard case let _username = username, _username != "" else {
            print("Username is empty")
            presentAlert(alert: "Invalid Username", message: "Please enter a username.")
            completion(false)
            return
        }
        if username.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil {
            print("Invalid username")
            presentAlert(alert: "Invalid Username", message: "The username can only contain letters and numbers.")
            completion(false)
            return
        }
        guard case let tempPassword = password, tempPassword != "" else {
            print("Password is empty")
            presentAlert(alert: "Invalid password", message: "Please enter a password.")
            completion(false)
            return
        }
        guard case let _confirmPassword = confirmPassword, _confirmPassword != "" else {
            print("confirm password is empty")
            presentAlert(alert: "Please confirm your password", message: "")
            completion(false)
            return
        }
        guard case let _password = tempPassword, _password == _confirmPassword else {
            print("passwords don't match")
            presentAlert(alert: "Password mismatch", message: "Your passwords do not match.")
            completion(false)
            return
        }
        print(username)
        FIRDatabase.database().reference(withPath: "Users").queryOrdered(byChild: "username").queryEqual(toValue: username).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                print("Username is taken :(")
                self.presentAlert(alert: "Invalid Username", message: "This username is already in use.")
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
    
    private func handleError(error: Error) {
        print(error.localizedDescription)
        presentAlert(alert: "Weak password", message: error.localizedDescription)
    }
    
    private func presentAlert(alert: String, message: String) {
        let alertController = UIAlertController(title: alert, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
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
                    self.passwordInfoLbl.isHidden = true
                    self.usernameInfoLbl.isHidden = true
                    self.agreementView.isHidden = true
                    //show profile picture stuff
                    self.createAccountBtn.isHidden = false
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
    
    @objc private func backTapped(sender:UIButton) {
        performSegue(withIdentifier: "BackToLoginSegue", sender: sender)
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

extension CreateAccountVC:UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print("Interacting with link")
        return true
    }
}
