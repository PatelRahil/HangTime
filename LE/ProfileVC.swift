//
//  ProfileVC.swift
//  LE
//
//  Created by Rahil Patel on 5/21/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase
import UIKit

class ProfileVC: UIViewController , UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Users")
    var currentUser:User? = nil
    var tableArray = [" ", "Username", "Email"]
    var userInfoArray = [" ", " "]
    
    @IBOutlet weak var OpenSideBar: UIButton!
    @IBOutlet weak var ProfileTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUser()
        ProfileTableView.dataSource = self
        ProfileTableView.delegate = self
        self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())

        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = ProfileTableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! CustomProfilePicCell
            cell.selectionStyle = UITableViewCellSelectionStyle.none

            return cell
        }
        else if indexPath.row == 2 {
            let cell = ProfileTableView.dequeueReusableCell(withIdentifier: "EmailCell", for: indexPath)
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
        print(textField.tag)
        
        
        self.view.endEditing(true)
        return false
    }
    
    func updateProfile(cellRow:Int, textField: UITextField) {
        print(cellRow)
        if (cellRow == 0) {
            
        }
        else if (cellRow == 1) {
            if let username = textField.text {
                currentUser?.changeUsername(username: username)
                let userRef = self.childRef.child("User: \(currentUser!.userID)")
                userRef.setValue(currentUser!.toAnyObject())
                //ProfileTableView.reloadData()
            }
            else {
                textField.text = currentUser?.username
                ProfileTableView.reloadData()
            }
        }
        else if (cellRow == 2) {
            
        }
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
        if let currentUser = FIRAuth.auth()?.currentUser {
            let userID = currentUser.uid
            
            self.childRef.observe(.value, with: { snapshot in
                for item in snapshot.children.allObjects as! [FIRDataSnapshot] {
                    let dict = item.value as! Dictionary<String,Any>
                    if (dict["UserID"] as? String == userID) {
                        self.currentUser = User(snapshot: item)
                        var counter = 0;
                        for (key,str) in dict {
                            if (key != "friends" && key != "UserID" && key != "createdEvents") {
                                counter += 1
                                print("~~~~~~~~~~~~~~~~\n\(str)")
                                self.userInfoArray[counter] = str as! String
                            }
                        }
                    }
                }
                self.ProfileTableView.reloadData()
            })
        }
    }
    
    func respondToErrors(error: Error) {
        
    }
    
}

class CustomProfilePicCell: UITableViewCell {
    @IBOutlet weak var ProfilePicButton: UIButton!
    
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

class CustomSecureProfileInfoCell: UITableViewCell {
    
    
}
