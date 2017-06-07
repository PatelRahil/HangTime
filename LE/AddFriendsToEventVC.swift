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

class AddFriendsToEventVC: UIViewController , UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Users")
    var TableArray = [""]
    var allUserID = [String]()
    var addedFriends: [String] = []
    var addedFriendsUsernames: [String] = []
    //uses index path to identify which userID was selected
    var index = 0;
    
    var currentUser:User? = nil
    
    @IBOutlet weak var UserNotFoundLbl: UILabel!
    @IBOutlet weak var AddFriendListTblView: UITableView!
    @IBOutlet weak var SearchBar: UITextField!

    @IBAction func DoneBtn(_ sender: Any) {
        
        let vcIndex = self.navigationController?.viewControllers.index(where: { (viewController) -> Bool in
            
            if let _ = viewController as? AddEventController {
                print("YES")
                return true
            }
            print("NO")
            return false
        })
        
        let createEventVC = self.navigationController?.viewControllers[vcIndex!] as! AddEventController
        //createEventVC.invitedFriendsUIDs = addedFriends
        
        self.childRef.observe(.value, with: { snapshot in
            
            for child in snapshot.children.allObjects as! [FIRDataSnapshot] {
                for id in self.addedFriends {
                    if child.key == "User: \(id)" {
                        let dict = child.value as! Dictionary<String,Any>
                        self.addedFriendsUsernames.append(dict["username"] as! String)
                    }
                }
            }
            //createEventVC.invitedFriendsUsernames = self.addedFriendsUsernames
            InvitedFriends.invitedFriendsUIDs = self.addedFriends
            InvitedFriends.invitedFriendsUsernames = self.addedFriendsUsernames
            print(InvitedFriends())
            self.navigationController?.popToViewController(createEventVC, animated: true)
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUser()
        //self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
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
        //OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
    }
    
    func loadUser() {
        /*
        if let currentUser = FIRAuth.auth()?.currentUser {
            let userID = currentUser.uid
            
            self.childRef.observe(.value, with: { snapshot in
                for item in snapshot.children.allObjects as! [FIRDataSnapshot] {
                    let dict = item.value as! Dictionary<String,Any>
                    if (dict["UserID"] as? String == userID) {
                        self.currentUser = User(snapshot: item)
                    }
                }
            })
        }
        */
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
        print("\(cell)")
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
        print("\(isAlreadyAdded(userID: pickedUserID)) ++++ \(pickedUserID)")
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
                    let dataDic:Dictionary<String,Any> = data as! Dictionary<String,Any>
                    for friend in (self.currentUser?.friends)! {
                        if friend == dataDic["UserID"] as! String {
                            isFriend = true
                        }
                    }
                    for (key,value) in dataDic {
                        //determines if the uid is a friend
                        //adds the username to the table array if the username is not the current user and is a friend
                        if key == "username" && value as? String != self.currentUser?.username && isFriend {
                            self.TableArray.append(value as! String)
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
                print(self.allUserID)
                print(self.TableArray)
                print(self.TableArray.count)
                //self.AddFriendListTblView.reloadData()
                self.AddFriendListTblView.beginUpdates()
                self.AddFriendListTblView.reloadData()
                for (index,_) in self.allUserID.enumerated() {
                    self.AddFriendListTblView.insertRows(at: [IndexPath(row: /*self.TableArray.count-2+*/index, section: 0)], with: .automatic)
                }
                self.AddFriendListTblView.endUpdates()
                print(self.AddFriendListTblView.numberOfRows(inSection: 0))

            }
            
            
        }, withCancel: { (error) in
            
            // An error occurred
        })
        self.view.endEditing(true)
        return true
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
