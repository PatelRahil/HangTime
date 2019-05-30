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

class AddFriendsToEventVC: UIViewController , UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
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
            
            addedFriends.forEach({ (friend) in
                if !currentUser!.friends.contains(friend) {
                    addedFriends = addedFriends.filter{$0 != friend}
                }
            })
            
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
        
        doWhenTextFieldReturns()
    }
    
    func loadUser() {
        currentUser = User(data: UserData())
    }
    
    @objc func removeAllCells() {
        TableArray.removeAll()
        //TableArray.append("")
        allUserID.removeAll()
        AddFriendListTblView.reloadData()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !ProfileInfo.isVisible {
            self.navigationController?.navigationBar.isUserInteractionEnabled = true
        }
        currentUser = User(data: UserData())
        return TableArray.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AddFriendListTblView.dequeueReusableCell(withIdentifier: "eventFriendCell", for: indexPath) as! CustomAddFriendTableViewCell
        print(profilePicArray)
        cell.ProfileImg.image = profilePicArray[indexPath.row]
        cell.UsernameLbl.text = TableArray[indexPath.row]
        index = indexPath.row
        cell.AddFriendBtn.alpha = 1
        print(allUserID)
        if (isAlreadyAdded(userID: allUserID[indexPath.row])) {
            cell.AddFriendBtn.setTitle("Added", for: .normal)
            //cell.AddFriendBtn.setTitleColor(UIColor.darkGray, for: .normal)
            cell.AddFriendBtn.backgroundColor = UIColor.white
            cell.AddFriendBtn.setTitleColor(Colors.blueGreen, for: .normal)
        }
        else {
            cell.AddFriendBtn.setTitle("Add", for: .normal)
            //cell.AddFriendBtn.setTitleColor(UIColor.blue, for: .normal)
            cell.AddFriendBtn.tag = indexPath.row
            cell.AddFriendBtn.addTarget(self, action: #selector(addFriendToEvent(_:)), for: .touchUpInside)
        }
        //if the user for this cell is no longer a friend
        if !currentUser!.friends.contains(allUserID[indexPath.row]) {
            cell.AddFriendBtn.removeTarget(nil, action: nil, for: .allEvents)
            cell.AddFriendBtn.setTitle("Not Friends", for: .normal)
            cell.AddFriendBtn.alpha = 0.6
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        cell.tag = indexPath.row
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        cell.addGestureRecognizer(tapGesture)
        
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
    
    @objc func addFriendToEvent(_ sender:UIButton) {
        let pickedUserID = allUserID[sender.tag]
        if (!isAlreadyAdded(userID: pickedUserID)) {
            addedFriends.append(pickedUserID)
            AddFriendListTblView.reloadData()
            print(addedFriends)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doWhenTextFieldReturns()
        self.view.endEditing(true)
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let tableViewIfButtonIsTapped = touch.view?.superview?.superview?.superview
        if tableViewIfButtonIsTapped == AddFriendListTblView {
            print("Touch in tableview")
            let touchPosition = touch.location(in: AddFriendListTblView)
            let indexPath = AddFriendListTblView.indexPathForRow(at: touchPosition)
            if let indexPath = indexPath {
                let cell:CustomAddFriendTableViewCell = AddFriendListTblView.cellForRow(at: indexPath) as! CustomAddFriendTableViewCell
                if touch.view == cell.AddFriendBtn {
                    print("touch in button")
                    return false
                }
            }
        }
        
        return true
    }
    
    @objc private func cellTapped(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: self.AddFriendListTblView)
        let indexPath = AddFriendListTblView.indexPathForRow(at: tapLocation)
        let cell = AddFriendListTblView.cellForRow(at: indexPath!)
        let uid = allUserID[cell!.tag]
        let profilePic = profilePicArray[cell!.tag]
        
        ProfileInfo.presentOnTableView(tableView: self.AddFriendListTblView, userID: uid, superViewFrame: self.view.frame, currentUser: self.currentUser!, profilePic: profilePic)
        self.navigationController?.navigationBar.isUserInteractionEnabled = false
        
    }
    
    /*
    private func doWhenTextFieldReturns() {
        _ = self.rootRef.child("Users").queryOrdered(byChild: "username").queryStarting(atValue:SearchBar.text!).queryEnding(atValue: "\(SearchBar.text!)~").observeSingleEvent(of: .value, with: { (snapshot) in
            print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\nSHOULD HAPPEN ONCE")
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
                    print(dataDic)
                    print("********************************************************")
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
                                //print("\(link)    array: \(self.profilePicArray)")
                                print("\nLink inside .data: \n\(link)\n")
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
    }
    */
    
    private func doWhenTextFieldReturns() {
        TableArray.removeAll()
        var dataDic:[String:UIImage] = [String:UIImage]()
        var usernameDic:[String:String] = [String:String]()
        guard let friends = currentUser?.friends else {
            return
        }
        print(friends)
        for friend in friends {
            rootRef.child("Users/User: \(friend)").observe(.value, with: { (snapshot) in
                let userInfo = snapshot.value as! [String:Any]
                guard let username = userInfo["username"] as? String else {
                    return
                }
                guard let uid = userInfo["UserID"] as? String else {
                    return
                }
                guard let profilePicDownloadLink = userInfo["profilePicture"] as? String else {
                    return
                }
                
                if username.contains(self.SearchBar.text!) || self.SearchBar.text! == "" {
                    print(username)
                    self.TableArray.append(username)
                    self.allUserID.append(uid)
                    self.profilePicArray.append(#imageLiteral(resourceName: "DefaultProfileImg"))
                    
                    dataDic[uid] = #imageLiteral(resourceName: "DefaultProfileImg")
                    usernameDic[username] = uid
                    
                    self.sortData(dataDic: dataDic, usernameDic)
                    
                    if profilePicDownloadLink != "" {
                        FIRStorage.storage().reference(forURL: profilePicDownloadLink).data(withMaxSize: 10*1024*1024, completion: { [uid] (data, error) in
                            if let error = error {
                                print("Storage photo downlaod error:\n\(error)")
                            }
                            else {
                                let userPhoto = UIImage(data: data!)
                                dataDic[uid] = userPhoto
                            }
                        
                            self.sortData(dataDic: dataDic, usernameDic)
                            self.AddFriendListTblView.reloadData()
                        })
                    }
                    
                    self.AddFriendListTblView.reloadData()
                }
                
            })
        }
        
    }
    
    private func sortData(dataDic:[String:UIImage], _ usernameDic:[String:String]) {

        TableArray = TableArray.sorted{$0.uppercased() < $1.uppercased()}

        //print(profilePicArray)
        //print(TableArray)
        //print(usernameDic)
        //print(dataDic)
        profilePicArray.removeAll()
        allUserID.removeAll()
        for username in TableArray {
            print(username)
            guard let uid = usernameDic[username] else {
                return
            }
            guard let profilePic = dataDic[uid] else {
                return
            }
            //print(uid)
            //print(profilePic)
            allUserID.append(uid)
            profilePicArray.append(profilePic)
        }
        //print(profilePicArray)
    }
}

class CustomAddFriendTableViewCell: UITableViewCell {
    @IBOutlet weak var UsernameLbl: UILabel!
    @IBOutlet weak var ProfileImg: UIImageView!
    @IBOutlet weak var AddFriendBtn: UIButton!
    
    override func prepareForReuse() {
        AddFriendBtn.layer.borderWidth = 1
        AddFriendBtn.layer.borderColor = Colors.blueGreen.cgColor
        AddFriendBtn.layer.cornerRadius = 4
        
        if (AddFriendBtn.titleLabel?.text == "Added") {
            AddFriendBtn.removeTarget(nil, action: nil, for: .allEvents)
        }
        if (AddFriendBtn.titleLabel?.text == "Add") {
            AddFriendBtn.backgroundColor = Colors.blueGreen
            AddFriendBtn.setTitleColor(UIColor.white, for: .normal)
            AddFriendBtn.setTitleColor(UIColor.gray, for: .selected)
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layoutProfilePics(with: self)
    }
    
    private func layoutProfilePics(with cell: CustomAddFriendTableViewCell) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: cell.ProfileImg.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(ovalIn: cell.ProfileImg.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor // causing lag when scrolling
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape

        cell.ProfileImg.layoutIfNeeded()
        cell.ProfileImg.clipsToBounds = true
        cell.ProfileImg.layer.masksToBounds = true
        cell.ProfileImg.layer.cornerRadius = cell.ProfileImg.bounds.size.width/2.0
        cell.ProfileImg.layer.addSublayer(gradient)
    }
}
