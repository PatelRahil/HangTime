//
//  AddFriendsVC.swift
//  LE
//
//  Created by Rahil Patel on 5/16/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Firebase
import FirebaseStorage

//for shrinking the size of the magnifying glass image
extension UIImage {
    
    func imageResize (sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
}

class AddFriendsVC: UIViewController , UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Users")
    let storageRef = FIRStorage.storage().reference()

    var TableArray = [""]
    var allUserID = [String]()
    var profilePicArray = [UIImage]()
    //uses index path to identify which userID was selected
    var index = 0;
    
    var currentUser:User? = nil
    
    
    @IBOutlet weak var UserNotFoundLbl: UILabel!
    @IBOutlet weak var OpenSideBar: UIButton!
    
    @IBOutlet weak var AddFriendListTblView: UITableView!
    @IBOutlet weak var SearchBar: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUser()
        self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
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
        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
    }
    
    func loadUser() {
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
        let cell = AddFriendListTblView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as! CustomTableViewCell
        cell.AddFriendBtn.removeTarget(nil, action: nil, for: .allEvents)
        
        layoutProfilePics(with: cell)
        
        cell.ProfileImg.image = profilePicArray[indexPath.row]
        
        cell.UsernameLbl.text = TableArray[indexPath.row + 1]
        
        index = indexPath.row
        if (isAlreadyFriend(userID: allUserID[indexPath.row])) {
            cell.AddFriendBtn.setTitle("Added", for: .normal)
            cell.AddFriendBtn.setTitleColor(UIColor.darkGray, for: .normal)
        }
        else {
            cell.AddFriendBtn.setTitle("Add", for: .normal)
            cell.AddFriendBtn.setTitleColor(UIColor.blue, for: .normal)
            cell.AddFriendBtn.tag = indexPath.row
            cell.AddFriendBtn.addTarget(self, action: #selector(addFriend(_:)), for: .touchUpInside)
        }
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    func isAlreadyFriend(userID:String) -> Bool {
        var isFriend = false
        
        for friend in (currentUser?.friends)! {
            if (friend == userID) {
                isFriend = true
            }
        }
        return isFriend
    }
    
    func addFriend(_ sender:UIButton) {
        let pickedUserID = allUserID[sender.tag]
        if (!isAlreadyFriend(userID: pickedUserID)) {
        currentUser?.addFriend(uid: pickedUserID)
        let userRef = self.childRef.child("User: \(currentUser!.userID)")
        userRef.setValue(currentUser!.toAnyObject())
        AddFriendListTblView.reloadData()
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
                    var uidStr = uid.replacingOccurrences(of: "User: ", with: "")
                    let uidStrArr:[String] = uidStr.characters.split{$0 == ","}.map(String.init)
                    let dataDic:Dictionary<String,Any> = data as! Dictionary<String,Any>
                    for _ in uidStrArr {
                        self.profilePicArray.append(#imageLiteral(resourceName: "DefaultProfileImg"))
                    }
                    if dataDic["username"] as? String != self.currentUser?.username {
                        self.TableArray.append(dataDic["username"] as! String)
                    }
                    if let link = dataDic["profilePicture"] as? String {
                        if link != self.currentUser?.profilePicDownloadLink {
                        
                        var profilePic:UIImage = #imageLiteral(resourceName: "DefaultProfileImg")
                        let photoIndex = self.allUserID.count

                            let filePath = "Users/User: \(dataDic["UserID"]!)/profilePicture"
                            self.storageRef.child(filePath).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
                                if error == nil {
                                    let userPhoto = UIImage(data: data!)
                                    profilePic = userPhoto!
                                }
                                else {
                                    profilePic = #imageLiteral(resourceName: "DefaultProfileImg")
                                }
                                self.profilePicArray[photoIndex] = profilePic
                                self.AddFriendListTblView.reloadData()
                            })
                            
                        }
                    }
                    for str in uidStrArr {
                        if str != self.currentUser!.userID {
                            self.allUserID.append(str)
                        }
                    }
                    //eventually use the local data variable to create another dictionary
                    //and interate through that to find profile pic
                    //and make an array of the images to iterate through
                }
                print(self.allUserID)
                
                self.AddFriendListTblView.beginUpdates()
                self.AddFriendListTblView.reloadData()
                for (index,_) in self.allUserID.enumerated() {
                    print(index)
                    self.AddFriendListTblView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    print(index)
                }
                self.AddFriendListTblView.endUpdates()
            }
            
            
        }, withCancel: { (error) in
            
            // An error occurred
        })
        self.view.endEditing(true)
        return true
    }
    
    private func layoutProfilePics(with cell:CustomTableViewCell) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: cell.ProfileImg.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(ovalIn: cell.ProfileImg.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        
        cell.ProfileImg.layoutIfNeeded()
        cell.ProfileImg.clipsToBounds = true
        cell.ProfileImg.layer.masksToBounds = true
        cell.ProfileImg.layer.cornerRadius = cell.ProfileImg.bounds.size.width/2.0
        cell.ProfileImg.layer.addSublayer(gradient)
        
    }
    
}

class CustomTableViewCell: UITableViewCell {
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
