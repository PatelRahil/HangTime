//
//  FriendsListVC.swift
//  LE
//
//  Created by Rahil Patel on 7/16/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class FriendsListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    var currentUser:User? = nil
    var tableDic:[Int:[String:String]] = [Int:[String:String]]()
    var profilePicDic:[String:UIImage] = [String:UIImage]()
    var friendsUIDs:[String] = [String]()
    
    var addedYouDic:[Int:[String:String]] = [Int:[String:String]]()
    var addedYouProfilePicDic:[String:UIImage] = [String:UIImage]()
    var addedYouUIDs:[String] = [String]()
    
    @IBOutlet weak var OpenSideBar: UIButton!
    @IBOutlet weak var friendsListTableView: UITableView!
    
    
    override func viewDidLoad() {
        currentUser = User(data: UserData())
        friendsListTableView.delegate = self
        friendsListTableView.dataSource = self
        
        
        //setupArrays()
        updateTableArray()
        
        
        self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
        
        self.view.layoutIfNeeded()
        print(OpenSideBar.frame.width)
        let pos = OpenSideBar.frame.origin
        OpenSideBar.frame = CGRect(origin: pos, size: CGSize(width: 44, height: 44))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableDic = [Int:[String:String]]()
        profilePicDic = [String:UIImage]()
        addedYouUIDs = [String]()
        addedYouDic = [Int:[String:String]]()
        currentUser = User(data: UserData())
        setupArrays()
        updateTableArray()
        friendsListTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        for uid in addedYouUIDs {
            if currentUser!.stillFriends(with: uid) {
                currentUser?.removeFromAddFriends(with: uid)
            }
        }
        let userRef = FIRDatabase.database().reference(withPath: "Users/User: \(currentUser!.getUserID())")
        userRef.setValue(currentUser?.toAnyObject())
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("UPDATING NUMBER OF ROWS")
        print(addedYouUIDs)
        print(addedYouDic)
        if section == 0 {
            if addedYouUIDs.count == 0 {
                return 1
            }
            
            else if addedYouUIDs.count > 3 {
                return 3
            }
            
            else {
                return addedYouUIDs.count
            }
        }
        else {
            if !ProfileInfo.isVisible {
                self.navigationController?.navigationBar.isUserInteractionEnabled = true
            }
            currentUser = User(data: UserData())
            return tableDic.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Added You"
        }
        else {
            return "Friends"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell") as! CustomFriendsListCell
        
        var friendUID = ""
        var usernameDic:[String:String] = [String:String]()
        var username = ""
        
        print(addedYouUIDs)
        if indexPath.section == 0 {
            print(addedYouUIDs.count)
            if addedYouUIDs.count == 0 {
                cell.ProfilePic.isHidden = true
                cell.FriendBtn.isHidden = true
                cell.UsernameLbl.textColor = UIColor.gray
                cell.UsernameLbl.textAlignment = .right
                cell.UsernameLbl.text = "No one yet..."
                cell.tag = 0
            }
            else {
                cell.ProfilePic.isHidden = false
                cell.FriendBtn.isHidden = false
                cell.UsernameLbl.textColor = UIColor.black
                cell.UsernameLbl.textAlignment = .left
                
                print("-------------------------------------")
                print(addedYouDic)
                friendUID = addedYouUIDs[indexPath.row]
                usernameDic = addedYouDic[indexPath.row]!
                print(friendUID)
                print(usernameDic)
                username = usernameDic[friendUID]!
                
                cell.ProfilePic.image = addedYouProfilePicDic[friendUID]
                cell.UsernameLbl.text = username
                
                cell.tag = -indexPath.row - 1
            }
            
        }
        else {
            print("--------------------------------------------")
            print(tableDic)
            friendUID = friendsUIDs[indexPath.row]
            usernameDic = tableDic[indexPath.row]!
            username = usernameDic[friendUID]!
            
            cell.ProfilePic.isHidden = false
            cell.FriendBtn.isHidden = false
            cell.UsernameLbl.textColor = UIColor.black
            cell.UsernameLbl.textAlignment = .left
            cell.ProfilePic.image = profilePicDic[friendUID]
            cell.UsernameLbl.text = username
            
            cell.tag = indexPath.row + 1
        }
        
        cell.isFriends = currentUser!.stillFriends(with: friendUID)
        
        cell.selectionStyle = .none
        
        //cleans previous gestures from the cell
        if let gestures = cell.gestureRecognizers {
            for gesture in gestures {
                cell.removeGestureRecognizer(gesture)
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        cell.addGestureRecognizer(tapGesture)
        
        setupFriendBtn(for: cell, indexPath: indexPath, tapGesture: tapGesture)
        
        return cell
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer != revealViewController().panGestureRecognizer() {

            let tableViewIfButtonIsTapped = touch.view?.superview?.superview?.superview
            if tableViewIfButtonIsTapped == friendsListTableView {
                print("Touch in tableview")
                let touchPosition = touch.location(in: friendsListTableView)
                let indexPath = friendsListTableView.indexPathForRow(at: touchPosition)
                if let indexPath = indexPath {
                    let cell:CustomFriendsListCell = friendsListTableView.cellForRow(at: indexPath) as! CustomFriendsListCell
                    if touch.view == cell.FriendBtn {
                        print("touch in button")
                        return false
                    }
                }
            }
        
            return true
        }
        else {
            return true
        }
    }
    
    private func setupArrays() {
        for (index,uid) in currentUser!.friends.enumerated() {
            tableDic[index] = [uid:"Loading..."]
            profilePicDic[uid] = #imageLiteral(resourceName: "DefaultProfileImg")
        }
        
        var count = 0
        print(currentUser!.addedYouFriends)
        for (uid,_) in currentUser!.addedYouFriends {
            addedYouDic[count] = [uid:"Loading..."]
            addedYouProfilePicDic[uid] = #imageLiteral(resourceName: "DefaultProfileImg")
            addedYouUIDs.append(uid)
            count += 1
        }
        
        friendsUIDs = currentUser!.friends
        friendsListTableView.reloadData()
    }
    
    private func updateTableArray() {
        for (index,uid) in currentUser!.friends.enumerated() {
            let userRef = FIRDatabase.database().reference(withPath: "Users").child("User: \(uid)")
            userRef.observeSingleEvent(of: .value, with: { [index,uid](snapshot) in
                let userInfo:[String:Any] = snapshot.value as! [String:Any]
                let username = userInfo["username"] as! String
                self.tableDic[index] = [uid:username]
                self.friendsListTableView.reloadData()
            })
            
            let filePath = "Users/User: \(uid)/profilePicture"
            let profilePicRef = FIRStorage.storage().reference(withPath: filePath)
            profilePicRef.data(withMaxSize: 10*1024*1024, completion: { [uid](data, error) in
                if error == nil {
                    let profilePic:UIImage = UIImage(data: data!)!
                    self.profilePicDic[uid] = profilePic
                }
                self.friendsListTableView.reloadData()
            })
        }
        
        var count = 0
        for (uid,_) in currentUser!.addedYouFriends {
            let userRef = FIRDatabase.database().reference(withPath: "Users").child("User: \(uid)")
            userRef.observeSingleEvent(of: .value, with: { [count,uid](snapshot) in
                let userInfo:[String:Any] = snapshot.value as! [String:Any]
                let username = userInfo["username"] as! String
                self.addedYouDic[count] = [uid:username]
                self.friendsListTableView.reloadData()
            })
            
            let filePath = "Users/User: \(uid)/profilePicture"
            let profilePicRef = FIRStorage.storage().reference(withPath: filePath)
            profilePicRef.data(withMaxSize: 10*1024*1024, completion: { [uid](data, error) in
                if error == nil {
                    let profilePic:UIImage = UIImage(data: data!)!
                    self.addedYouProfilePicDic[uid] = profilePic
                }
                self.friendsListTableView.reloadData()
            })
            count += 1
        }
    }
    
    private func setupFriendBtn(for cell:CustomFriendsListCell, indexPath:IndexPath, tapGesture:UITapGestureRecognizer) {
        if cell.isFriends! {
            if indexPath.section == 1 {
                cell.FriendBtn.setTitle("Friends", for: .normal)
                cell.FriendBtn.setTitleColor(Colors.blueGreen, for: .normal)
                cell.FriendBtn.backgroundColor = UIColor.white
                cell.FriendBtn.layer.borderColor = Colors.blueGreen.cgColor
                cell.FriendBtn.layer.borderWidth = 1
            }
            else {
                cell.FriendBtn.setTitle("Added You Back", for: .normal)
                cell.FriendBtn.setTitleColor(Colors.blueGreen, for: .normal)
                cell.FriendBtn.backgroundColor = UIColor.white
                cell.FriendBtn.isUserInteractionEnabled = false
                cell.FriendBtn.layer.borderWidth = 0
                cell.removeGestureRecognizer(tapGesture)
                
            }
        }
        else {
            cell.FriendBtn.setTitle("Add", for: .normal)
            cell.FriendBtn.setTitleColor(UIColor.white, for: .normal)
            cell.FriendBtn.backgroundColor = Colors.blueGreen
            cell.FriendBtn.layer.borderColor = Colors.blueGreen.cgColor
            cell.FriendBtn.layer.borderWidth = 1
        }
        
        cell.FriendBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: (cell.FriendBtn.titleLabel?.font.pointSize)!)
        cell.FriendBtn.layer.cornerRadius = 4
        cell.FriendBtn.addTarget(self, action: #selector(friendBtnPressed(sender:)), for: .touchUpInside)
    }
    
    @objc private func friendBtnPressed(sender:Any) {
        print("BUTTON TAPPED")
        let cell = (sender as! UIButton).superview?.superview as! CustomFriendsListCell
        if cell.tag == 0 {
            return
        }
        
        let indexPath = friendsListTableView.indexPath(for: cell)
        var userID = ""
        
        var tempDic:[String:String] = [String:String]()
        
        if indexPath?.section == 0 {
            tempDic = addedYouDic[(indexPath?.row)!]!
        }
        else {
            tempDic = tableDic[(indexPath?.row)!]!
        }
        
        for (key,_) in tempDic {
            userID = key
        }
        
        if cell.isFriends! {
            currentUser?.removeFriend(uid: userID)
            UserData.updateData(withUser: currentUser!)
        }
        else {
            currentUser?.addFriend(uid: userID)
            UserData.updateData(withUser: currentUser!)
        }
        
        let userRef = FIRDatabase.database().reference(withPath: "Users").child("User: \(currentUser!.userID)")
        userRef.setValue(currentUser!.toAnyObject())
        
        if indexPath?.section == 0 /*&& cell.isFriends!*/ {
            print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
            print(addedYouUIDs)
            print(addedYouDic)
            let index = addedYouUIDs.index(of: userID)
            print(index!)
            addedYouUIDs.removeAll()
            //addedYouUIDs.remove(at: index!)
            addedYouDic.removeValue(forKey: index!)
            profilePicDic.removeValue(forKey: userID)
            
            setupArrays()
            updateTableArray()
        }
        
        friendsListTableView.reloadData()
        //friendsListTableView.reloadRows(at: [indexPath!], with: .automatic)
    }
    
    @objc private func cellTapped(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: self.friendsListTableView)
        let indexPath = friendsListTableView.indexPathForRow(at: tapLocation)
        let cell = friendsListTableView.cellForRow(at: indexPath!)
        var uid = ""
        var profilePic = #imageLiteral(resourceName: "DefaultProfileImg")
        
        if cell!.tag == 0 {
            return
        }
        else if cell!.tag < 0 {
            //section 0
            uid = addedYouUIDs[-(cell!.tag + 1)]
            profilePic = addedYouProfilePicDic[uid]!
        }
        else {
            //section 1
            uid = friendsUIDs[cell!.tag - 1]
            profilePic = profilePicDic[uid]!
        }
        
        
        ProfileInfo.presentOnTableView(tableView: self.friendsListTableView, userID: uid, superViewFrame: self.view.frame, currentUser: self.currentUser!, profilePic: profilePic)
        self.navigationController?.navigationBar.isUserInteractionEnabled = false
        
    }
}

class CustomFriendsListCell: UITableViewCell {
    @IBOutlet weak var ProfilePic: UIImageView!
    @IBOutlet weak var UsernameLbl: UILabel!
    @IBOutlet weak var FriendBtn: UIButton!
    
    var isFriends:Bool? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layoutProfilePics(with: self)
    }
    
    private func layoutProfilePics(with cell: CustomFriendsListCell) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: cell.ProfilePic.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(ovalIn: cell.ProfilePic.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor // causing lag when scrolling
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        
        
        
        cell.ProfilePic.layoutIfNeeded()
        cell.ProfilePic.clipsToBounds = true
        cell.ProfilePic.layer.masksToBounds = true
        cell.ProfilePic.layer.cornerRadius = cell.ProfilePic.bounds.size.width/2.0
        cell.ProfilePic.layer.addSublayer(gradient)
    }
}
