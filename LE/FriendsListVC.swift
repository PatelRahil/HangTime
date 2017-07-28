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
    
    
    @IBOutlet weak var OpenSideBar: UIButton!
    @IBOutlet weak var friendsListTableView: UITableView!
    
    
    override func viewDidLoad() {
        currentUser = User(data: UserData())
        friendsListTableView.delegate = self
        friendsListTableView.dataSource = self
        
        
        setupArrays()
        updateTableArray()
        
        
        self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableDic = [Int:[String:String]]()
        profilePicDic = [String:UIImage]()
        currentUser = User(data: UserData())
        setupArrays()
        updateTableArray()
        friendsListTableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !ProfileInfo.isVisible {
            self.navigationController?.navigationBar.isUserInteractionEnabled = true
        }
        currentUser = User(data: UserData())
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
        
        cell.selectionStyle = .none
        
        cell.tag = indexPath.row
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        cell.addGestureRecognizer(tapGesture)
        
        return cell
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer != revealViewController().panGestureRecognizer() {

            let tableViewIfButtonIsTapped = touch.view?.superview?.superview?.superview?.superview
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
            cell.FriendBtn.setTitle("Friends", for: .normal)
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
    
    @objc private func cellTapped(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: self.friendsListTableView)
        let indexPath = friendsListTableView.indexPathForRow(at: tapLocation)
        let cell = friendsListTableView.cellForRow(at: indexPath!)
        let uid = friendsUIDs[cell!.tag]
        let profilePic = profilePicDic[uid]
        
        ProfileInfo.presentOnTableView(tableView: self.friendsListTableView, userID: uid, superViewFrame: self.view.frame, currentUser: self.currentUser!, profilePic: profilePic!)
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
