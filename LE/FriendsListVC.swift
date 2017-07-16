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

class FriendsListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var currentUser:User? = nil
    var tableDic:[Int:[String:String]] = [Int:[String:String]]()
    var profilePicDic:[String:UIImage] = [String:UIImage]()
    var friendsUIDs:[String] = [String]()
    
    
    @IBOutlet weak var OpenSideBar: UIButton!
    @IBOutlet weak var friendsListTableView: UITableView!
    
    
    override func viewDidLoad() {
        currentUser = User(data: UserData())
        friendsListTableView.delegate = self
        friendsListTableView.dataSource = self
        
        
        setupArrays()
        updateTableArray()
        
        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        currentUser = User(data: UserData())
        updateTableArray()
        friendsListTableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("refreshed \(tableDic.count)")
        return tableDic.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell") as! CustomFriendsListCell
        
        let friendUID = friendsUIDs[indexPath.row]
        let usernameDic = tableDic[indexPath.row]!
        let username = usernameDic[friendUID]
        
        cell.isFriends = currentUser!.stillFriends(with: friendUID)
        cell.UsernameLbl.text = username
        cell.ProfilePic.image = profilePicDic[friendUID]
        setupFriendBtn(for: cell)
        layoutProfilePics(for: cell)
        
        cell.selectionStyle = .none
        return cell
    }
    
    private func setupArrays() {
        for (index,uid) in currentUser!.friends.enumerated() {
            tableDic[index] = [uid:"Loading..."]
            profilePicDic[uid] = #imageLiteral(resourceName: "DefaultProfileImg")
        }
        friendsUIDs = currentUser!.friends
        friendsListTableView.reloadData()
    }
    
    private func updateTableArray() {
        for (index,uid) in currentUser!.friends.enumerated() {
            let userRef = FIRDatabase.database().reference(withPath: "Users").child("User: \(uid)")
            userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                let userInfo:[String:Any] = snapshot.value as! [String:Any]
                let username = userInfo["username"] as! String
                self.tableDic[index] = [uid:username]
                self.friendsListTableView.reloadData()
            })
            
            let filePath = "Users/User: \(uid)/profilePicture"
            let profilePicRef = FIRStorage.storage().reference(withPath: filePath)
            profilePicRef.data(withMaxSize: 10*1024*1024, completion: { (data, error) in
                if error == nil {
                    let profilePic:UIImage = UIImage(data: data!)!
                    self.profilePicDic[uid] = profilePic
                }
                self.friendsListTableView.reloadData()
            })
        }
    }
    
    private func setupFriendBtn(for cell:CustomFriendsListCell) {
        if cell.isFriends! {
            cell.FriendBtn.setTitle("Friend", for: .normal)
            cell.FriendBtn.setTitleColor(Colors.blueGreen, for: .normal)
            cell.FriendBtn.backgroundColor = UIColor.white
        }
        else {
            cell.FriendBtn.setTitle("Add", for: .normal)
            cell.FriendBtn.setTitleColor(UIColor.white, for: .normal)
            cell.FriendBtn.backgroundColor = Colors.blueGreen
        }
        
        cell.FriendBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: (cell.FriendBtn.titleLabel?.font.pointSize)!)
        cell.FriendBtn.layer.borderColor = Colors.blueGreen.cgColor
        cell.FriendBtn.layer.borderWidth = 1
        cell.FriendBtn.layer.cornerRadius = 4
        cell.FriendBtn.addTarget(self, action: #selector(friendBtnPressed(sender:)), for: .touchUpInside)
    }
    
    private func layoutProfilePics(for cell:CustomFriendsListCell) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: cell.ProfilePic.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(ovalIn: cell.ProfilePic.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        
        cell.ProfilePic.layoutIfNeeded()
        cell.ProfilePic.clipsToBounds = true
        cell.ProfilePic.layer.masksToBounds = true
        cell.ProfilePic.layer.cornerRadius = cell.ProfilePic.bounds.size.width/2.0
        cell.ProfilePic.layer.addSublayer(gradient)
        
    }
    
    @objc private func friendBtnPressed(sender:Any) {
        let cell = (sender as! UIButton).superview?.superview as! CustomFriendsListCell
        let row = friendsListTableView.indexPath(for: cell)?.row
        var userID = ""
        let tempDic = tableDic[row!]
        for (key,_) in tempDic! {
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
        
        friendsListTableView.reloadData()
    }
}

class CustomFriendsListCell: UITableViewCell {
    @IBOutlet weak var ProfilePic: UIImageView!
    @IBOutlet weak var UsernameLbl: UILabel!
    @IBOutlet weak var FriendBtn: UIButton!
    
    var isFriends:Bool? = nil
    
    
}
