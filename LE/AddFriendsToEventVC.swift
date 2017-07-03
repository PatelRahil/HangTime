//
//  AddFriendsToEventVC.swift
//  LE
//
//  Created by Rahil Patel on 5/27/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Firebase
import FirebaseStorage

class AddFriendsToEventVC: UIViewController , UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Users")
    let storageRef = FIRStorage.storage().reference()

    var TableArray = [""]
    var allUserID = [String]()
    var addedFriends: [String] = []
    var addedFriendsUsernames: [String] = []
    var profilePicArray = [UIImage]()

    //uses index path to identify which userID was selected
    var index = 0;
    
    var currentUser:User? = nil
    var eventDetailsWasPrevVC = false
    var eventID:String?
    var event:Event?
    
    @IBOutlet weak var UserNotFoundLbl: UILabel!
    @IBOutlet weak var AddFriendListTblView: UITableView!
    @IBOutlet weak var SearchBar: UITextField!

    @IBAction func DoneBtn(_ sender: Any) {
        if eventDetailsWasPrevVC {
            EventVariables.invitedFriends = addedFriends
            
            let vcIndex = self.navigationController?.viewControllers.index(where: { (viewController) -> Bool in
                
                if let _ = viewController as? EventDetailsVC {
                    return true
                }
                return false
            })
            
            let eventDetailsVC = self.navigationController?.viewControllers[vcIndex!] as! EventDetailsVC
            
            let childRef = FIRDatabase.database().reference(withPath: "Events")
            let invFriendsRef = childRef.child(EventVariables.eventID).child("invitedFriends")
            let invitedFriendsStringRep = addedFriends.joined(separator: ",")
            invFriendsRef.setValue(invitedFriendsStringRep)
            self.navigationController?.popToViewController(eventDetailsVC, animated: true)
        }
            
        else {
            let vcIndex = self.navigationController?.viewControllers.index(where: { (viewController) -> Bool in
            
                if let _ = viewController as? AddEventController {
                    return true
                }
                return false
            })
        
            let createEventVC = self.navigationController?.viewControllers[vcIndex!] as! AddEventController
            //createEventVC.invitedFriendsUIDs = addedFriends
        
            self.childRef.observe(.value, with: { snapshot in
                /*
                for child in snapshot.children.allObjects as! [FIRDataSnapshot] {
                    for id in self.addedFriends {
                        if child.key == "User: \(id)" {
                            let dict = child.value as! Dictionary<String,Any>
                            self.addedFriendsUsernames.append(dict["username"] as! String)
                        }
                    }
                }
                 */
                for id in self.addedFriends {
                    for child in snapshot.children.allObjects as! [FIRDataSnapshot] {
                        if child.key == "User: \(id)" {
                            let dict = child.value as! Dictionary<String,Any>
                            self.addedFriendsUsernames.append(dict["username"] as! String)
                        }
                    }
                }
                
                //createEventVC.invitedFriendsUsernames = self.addedFriendsUsernames
                InvitedFriends.invitedFriendsUIDs = self.addedFriends
                InvitedFriends.invitedFriendsUsernames = self.addedFriendsUsernames
                self.navigationController?.popToViewController(createEventVC, animated: true)
            })
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUser()
        print("--------------------------------------------------")
        print(addedFriends)
        let magnifyingGlassAttachment = NSTextAttachment(data: nil, ofType: nil)
        var magnifyingGlassImg = UIImage(named: "MagnifyingGlass")
        magnifyingGlassImg = magnifyingGlassImg?.imageResize(sizeChange: CGSize(width: 14, height: 12))
        magnifyingGlassAttachment.image = magnifyingGlassImg
        
        let magnifyingGlassString = NSAttributedString(attachment:magnifyingGlassAttachment)
        
        let attributedText = NSMutableAttributedString(attributedString: magnifyingGlassString)
        
        let searchString = NSAttributedString(string: " Search by Username")
        
        attributedText.append(searchString)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        SearchBar.attributedPlaceholder = attributedText
        SearchBar.delegate = self
        SearchBar.addTarget(self, action: #selector(removeAllCells), for: .touchDown)
    }
    
    func loadUser() {
        currentUser = User(data: UserData())
    }
    
    func removeAllCells() {
        TableArray.removeAll()
        TableArray.append("")
        allUserID.removeAll()
        AddFriendListTblView.reloadData()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableArray.count - 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AddFriendListTblView.dequeueReusableCell(withIdentifier: "eventFriendCell", for: indexPath) as! CustomAddFriendTableViewCell
        layoutProfilePics(with: cell)
        cell.ProfileImg.image = profilePicArray[indexPath.row]
        cell.UsernameLbl.text = TableArray[indexPath.row + 1]
        index = indexPath.row
        if (isAlreadyAdded(userID: allUserID[indexPath.row])) {
            cell.AddFriendBtn.setTitle("Added", for: .normal)
            cell.AddFriendBtn.setTitleColor(UIColor.darkGray, for: .normal)
        }
        else {
            cell.AddFriendBtn.setTitle("Add", for: .normal)
            cell.AddFriendBtn.setTitleColor(UIColor.blue, for: .normal)
            cell.AddFriendBtn.tag = indexPath.row
            cell.AddFriendBtn.addTarget(self, action: #selector(addFriendToEvent(_:)), for: .touchUpInside)
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    func isAlreadyAdded(userID:String) -> Bool {
        var isAlreadyAdded = false
        
        for friend in addedFriends {
            if (friend == userID) {
                isAlreadyAdded = true
            }
        }
        return isAlreadyAdded
    }
    
    func addFriendToEvent(_ sender:UIButton) {
        let pickedUserID = allUserID[sender.tag]
        if (!isAlreadyAdded(userID: pickedUserID)) {
            addedFriends.append(pickedUserID)
            AddFriendListTblView.reloadData()
            print(addedFriends)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = self.rootRef.child("Users").queryOrdered(byChild: "username").queryStarting(atValue:SearchBar.text!).queryEnding(atValue: "\(SearchBar.text!)~").observeSingleEvent(of: .value, with: { (snapshot) in
            
            //let databaseRefQuery = self.rootRef.child("Users").queryOrdered(byChild: "username").queryEqual(toValue:SearchBar.text!).observeSingleEvent(of: .value, with: { (snapshot) in
            if ( snapshot.value is NSNull ) {
                
                self.UserNotFoundLbl.text = "User Not Found"
                // No user
            } else {
                self.UserNotFoundLbl.text = ""
                
                //All this is to find UserID's that matched the input username and
                //Create an array of all UserID's with that username
                let user: Dictionary<String,Any> = snapshot.value as! Dictionary<String,Any>
                for (uid,data) in user {
                    print("--------------------------------------------------------")
                    var isFriend = false
                    var uidStr = uid.replacingOccurrences(of: "User: ", with: "")
                    let uidStrArr:[String] = uidStr.characters.split{$0 == ","}.map(String.init)
                    
                    //dictionary of the user's information
                    let dataDic:Dictionary<String,Any> = data as! Dictionary<String,Any>
                    for _ in uidStrArr {
                        self.profilePicArray.append(#imageLiteral(resourceName: "DefaultProfileImg"))
                    }
                    for friend in (self.currentUser?.friends)! {
                        if friend == dataDic["UserID"] as! String {
                            isFriend = true
                        }
                    }
                    
                    if dataDic["username"] as? String != self.currentUser?.username && isFriend {
                        self.TableArray.append(dataDic["username"] as! String)
                    }
                    
                    if let link = dataDic["profilePicture"] as? String {
                        print("LINK: \(link)")
                        if link != self.currentUser?.profilePicDownloadLink {
                            
                            var profilePic:UIImage = #imageLiteral(resourceName: "DefaultProfileImg")
                            let photoIndex = self.allUserID.count
                            
                                let filePath = "Users/User: \(dataDic["UserID"]!)/\("profilePicture")"
                                self.storageRef.child(filePath).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
                                    if error == nil {
                                        let userPhoto = UIImage(data: data!)
                                        profilePic = userPhoto!
                                    }
                                    else {
                                        print("ERROR: \(String(describing: error))")
                                        profilePic = #imageLiteral(resourceName: "DefaultProfileImg")
                                    }
                                    self.profilePicArray[photoIndex] = profilePic
                                    print("\(link)    array: \(self.profilePicArray)")
                                    self.AddFriendListTblView.reloadData()
                                })
                            
                        }
                    }
                    
                    //adds the username's corresponding uid to the uid array if it is a friend
                    
                    for str in uidStrArr {
                        if (str != self.currentUser!.userID) && isFriend {
                            self.allUserID.append(str)
                        }
                    }
                    //eventually use the local data variable to create another dictionary
                    //and interate through that to find profile pic
                    //and make an array of the images to iterate through
                }

                //self.AddFriendListTblView.reloadData()
                self.AddFriendListTblView.beginUpdates()
                self.AddFriendListTblView.reloadData()
                for (index,_) in self.allUserID.enumerated() {
                    self.AddFriendListTblView.insertRows(at: [IndexPath(row: /*self.TableArray.count-2+*/index, section: 0)], with: .automatic)
                }
                self.AddFriendListTblView.endUpdates()

            }
            
            
        }, withCancel: { (error) in
            
            // An error occurred
        })
        self.view.endEditing(true)
        return true
    }
    
    private func layoutProfilePics(with cell:CustomAddFriendTableViewCell) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: cell.ProfileImg.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        //shape.path = UIBezierPath(rect: cell.ProfileImg.bounds).cgPath
        shape.path = UIBezierPath(ovalIn: cell.ProfileImg.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        //shape.cornerRadius = cell.ProfileImg.bounds.size.width/2.0
        gradient.mask = shape
        
        cell.ProfileImg.layoutIfNeeded()
        cell.ProfileImg.clipsToBounds = true
        cell.ProfileImg.layer.masksToBounds = true
        cell.ProfileImg.layer.cornerRadius = cell.ProfileImg.bounds.size.width/2.0
        cell.ProfileImg.layer.addSublayer(gradient)

    }
    
}

class CustomAddFriendTableViewCell: UITableViewCell {
    @IBOutlet weak var UsernameLbl: UILabel!
    
    @IBOutlet weak var ProfileImg: UIImageView!
    @IBOutlet weak var AddFriendBtn: UIButton!
    
    
    override func prepareForReuse() {
        if (AddFriendBtn.titleLabel?.text == "Added") {
            AddFriendBtn.removeTarget(nil, action: nil, for: .allEvents)
        }
        if (AddFriendBtn.titleLabel?.text == "Add") {
            AddFriendBtn.setTitleColor(UIColor.blue, for: .normal)
            AddFriendBtn.setTitleColor(UIColor.gray, for: .selected)
        }
    }
}
