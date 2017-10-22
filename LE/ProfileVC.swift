//
//  ProfileVC.swift
//  LE
//
//  Created by Rahil Patel on 5/21/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import UIKit

class ProfileVC: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Users")
    let storageRef = FIRStorage.storage().reference()
    let dimmedBackground = UIView()
    var dimmedBackgroundIsVisible = false
    var currentUser:User? = nil
    var tableArray = [" ", "Username", "Email"]
    var userInfoArray = [" ", " "]
    var profilePic: UIImage? = #imageLiteral(resourceName: "DefaultProfileImg")
    
    
    @IBOutlet weak var OpenSideBar: UIButton!
    @IBOutlet weak var ProfileTableView: UITableView!
    
    @objc func changeProfilePicture(tapGestureRecognizer: UITapGestureRecognizer) {
        //let tappedImage = tapGestureRecognizer.view as! UIImageView
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { (action) in
            self.showPicker(withType: .camera)
        }))
        ac.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { (action) in
            self.showPicker(withType: .photoLibrary)
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //this happens if the user is on an ipad
        if let popoverController = ac.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: 15*view.bounds.height/16, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
            addDimmedBackground()
            popoverController.delegate = self
        }
        
        self.present(ac, animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        loadUser()
        ProfileTableView.dataSource = self
        ProfileTableView.delegate = self
        self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())

        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
        
        self.view.layoutIfNeeded()
        print(OpenSideBar.frame.width)
        let pos = OpenSideBar.frame.origin
        OpenSideBar.frame = CGRect(origin: pos, size: CGSize(width: 44, height: 44))
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = ProfileTableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! CustomProfilePicCell
            
            layoutProfilePic(with: cell)
            
            
            cell.selectionStyle = UITableViewCellSelectionStyle.none

            return cell
        }
        else if indexPath.row == 2 {
            let cell = ProfileTableView.dequeueReusableCell(withIdentifier: "DetailsCell", for: indexPath) as! CustomProfileInfoCell
            let email = FIRAuth.auth()?.currentUser?.email
            cell.EditableInfoField.isEnabled = false
            cell.EditableInfoField.textAlignment = .right
            cell.EditableInfoField.text = email
            cell.EditableInfoField.textColor = UIColor.lightGray
            
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = "Email"
            return cell
        }
        else {
            let cell = ProfileTableView.dequeueReusableCell(withIdentifier: "DetailsCell", for: indexPath) as! CustomProfileInfoCell
            cell.textLabel?.text = tableArray[indexPath.row]
            cell.EditableInfoField.delegate = self
            cell.EditableInfoField.textAlignment = NSTextAlignment.right
            cell.EditableInfoField.tag = indexPath.row
            cell.EditableInfoField.returnKeyType = UIReturnKeyType.done
            cell.EditableInfoField.text = userInfoArray[indexPath.row]
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        }

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //Following determines what occurs when someone taps return after editing any of the profile data
        updateProfile(cellRow: textField.tag, textField: textField)
        
        
        self.view.endEditing(true)
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    func updateProfile(cellRow:Int, textField: UITextField) {
        //Profile Picture
        if (cellRow == 0) {
        }
        //Username
        else if (cellRow == 1) {
            
            if let _username = textField.text {
                var username = _username
                username = username.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if username == "" {
                    textField.text = currentUser!.username
                }
                else {
                    var isTaken = false
                    _ = self.rootRef.child("Users").queryOrdered(byChild: "username").queryEqual(toValue:username).observeSingleEvent(of: .value, with:{ (snapshot) in
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
                    
                        if !isTaken {
                            if username.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil {
                                self.currentUser?.changeUsername(username: username)
                                UserData.updateData(withUser: self.currentUser!)
                                let userRef = self.childRef.child("User: \(self.currentUser!.userID)")
                                userRef.setValue(self.currentUser!.toAnyObject())
                                textField.text = self.currentUser?.username
                            }
                            else {
                                let alertController = UIAlertController(title: "Invalid Username", message:
                                    "Usernames can only contain letters and digits", preferredStyle: UIAlertControllerStyle.alert)
                                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
                                self.present(alertController, animated: true, completion: nil)
                                textField.text = self.currentUser?.username
                            }
                        }
                        else {
                            print("USERNAME IS ALREADY TAKEN")
                            let alertController = UIAlertController(title: "That username is already taken", message:
                            "", preferredStyle: UIAlertControllerStyle.alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                            textField.text = self.currentUser?.username
                        }
                    })
                }
                
                
                //ProfileTableView.reloadData()
            }
            else {
                textField.text = currentUser?.username
                ProfileTableView.reloadData()
            }
        }
        //...
        else if (cellRow == 2) {
            
        }
        
        UserData.updateData(withUser: currentUser!)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return 150
        }
        else {
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableArray.count
    }

    
    func loadUser() {
        
        currentUser = User(data: UserData())
        profilePic = currentUser!.profilePic
        var counter = 0
        for (key,str) in currentUser!.toAnyObject() as! Dictionary<String,Any> {
            if (key != "friends" && key != "UserID" && key != "createdEvents" && key != "profilePicture" && key != "invitedEvents" && key != "addedYouFriends" && key != "pushTokens") {
                counter += 1
                self.userInfoArray[counter] = str as! String
            }
            else if key == "profilePicture" {
                self.userInfoArray[0] = str as! String
            }
        }
    }
    
    func showPicker(withType sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true
        self.present(picker, animated: true, completion: nil)
        
        //removeDimmedBackground()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        if let profilePic = info[UIImagePickerControllerEditedImage] as? UIImage {
            var data = NSData()
            data = UIImageJPEGRepresentation(profilePic, 0.8)! as NSData
            let filePath = "Users/User: \(currentUser!.getUserID())/\("profilePicture")"
            let metaData = FIRStorageMetadata()
            metaData.contentType = "image/jpg"
            self.storageRef.child(filePath).put(data as Data, metadata: metaData){(metaData,error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }else{
                    //store downloadURL
                    let downloadURL = metaData!.downloadURL()!.absoluteString
                    //store downloadURL at database
                    self.rootRef.child("Users").child("User: \(self.currentUser!.getUserID())").updateChildValues(["profilePicture": downloadURL])
                }
            }
            
            self.profilePic = profilePic
            let cell = ProfileTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! CustomProfilePicCell
            cell.ProfilePicture.image = profilePic
            ProfileTableView.reloadData()
        }
        else {
            //not a UIImage or for some reason profilePic is nil
            print(info)
            profilePic = #imageLiteral(resourceName: "DefaultProfileImg")
            let cell = ProfileTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! CustomProfilePicCell
            cell.ProfilePicture.image = profilePic
            ProfileTableView.reloadData()
        }
        
        UserData.updateData(withUser: currentUser!, profilePic: profilePic!)
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        removeDimmedBackground()
    }
    
    private func layoutProfilePic(with cell:CustomProfilePicCell) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: cell.ProfilePicture.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        let shape = CAShapeLayer()
        shape.lineWidth = 6
        shape.path = UIBezierPath(ovalIn: cell.ProfilePicture.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(changeProfilePicture(tapGestureRecognizer:)))
        
        cell.ProfilePicture.isUserInteractionEnabled = true
        cell.ProfilePicture.addGestureRecognizer(tapGestureRecognizer)
        cell.ProfilePicture.image = profilePic
        cell.ProfilePicture.layoutIfNeeded()
        cell.ProfilePicture.clipsToBounds = true
        cell.ProfilePicture.layer.masksToBounds = true
        cell.ProfilePicture.layer.cornerRadius = cell.ProfilePicture.bounds.size.width/2.0
        cell.ProfilePicture.layer.addSublayer(gradient)
        
    }
    
    private func addDimmedBackground() {
        dimmedBackgroundIsVisible = true
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        dimmedBackground.frame = frame
        dimmedBackground.backgroundColor = UIColor.init(r: 0, g: 0, b: 0, a: 0.5)
        view.addSubview(dimmedBackground)
    }
    
    @objc private func removeDimmedBackground() {
        if dimmedBackgroundIsVisible {
            dimmedBackground.removeFromSuperview()
            dimmedBackgroundIsVisible = false
        }
    }
    
    func respondToErrors(error: Error) {
        
    }
    
}

class CustomProfilePicCell: UITableViewCell {
    @IBOutlet weak var ProfilePicture: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()

    }
    
}

class CustomProfileInfoCell: UITableViewCell {
    @IBOutlet weak var EditableInfoField: UITextField!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var frame: CGRect = (self.textLabel?.frame)!
        let frameHeight = frame.height
        frame.size = CGSize(width: 100, height: frameHeight)
        self.textLabel?.frame = frame
    }
    
}

//for email and password
class CustomSecureProfileInfoCell: UITableViewCell {
    
    
}
