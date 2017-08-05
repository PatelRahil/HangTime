//
//  ProfileInfo.swift
//  LE
//
//  Created by Rahil Patel on 7/25/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class ProfileInfo {
    
    static var newView:UIView = UIView()
    static var greyView:UIView = UIView()
    static var cancelBtn:UIButton = UIButton()
    static var addFriendBtn:UIButton = UIButton()
    static var btnSeparator:UIView = UIView()
    static var secondBtnSeparator:UIView = UIView()
    static var profilePic:UIImageView = UIImageView(image: #imageLiteral(resourceName: "DefaultProfileImg"))
    static var usernameLbl:UILabel = UILabel()
    
    static var pickedUser:User? = nil
    static var isFriends:Bool? = nil
    static var isVisible = false
    
    static var scrollingWasEnabled:Bool = true
    static var tableView:UITableView = UITableView()
    static var currentUser:User? = nil
    
    static func profileInfoView(uid:String, superViewFrame viewFrame:CGRect) -> UIView {
        let newView: UIView = UIView()
        
        setupProfileInfoFrame(view: newView, superViewFrame: viewFrame)
        setupButtons(on: newView)
        setupProfilePic(on: newView, withUID: uid)
        setupUsernameLabel(on: newView, withUID: uid)
        
        newView.backgroundColor = UIColor.white
        newView.layer.cornerRadius = 15
        
        return newView
    }
    
    static private func setupProfileInfoFrame(view:UIView, superViewFrame:CGRect) {
        
        let statusBarHeight:CGFloat = 22.0
        let navigationBarHeight:CGFloat = 44.0
        let const:CGFloat = 8.0
        let xPos:CGFloat = superViewFrame.width/const
        let yPos:CGFloat = navigationBarHeight + statusBarHeight + xPos/2
        let origin = CGPoint(x: xPos, y: yPos)
        let size = CGSize(width: superViewFrame.width - 2 * xPos, height: superViewFrame.height - 4 * yPos)
        let frame = CGRect(origin: origin, size: size)
        
        view.frame = frame
    }
    
    static private func setupButtons(on view:UIView) {
        //const determines the two button's heights
        let const:CGFloat = 6
        let yPos:CGFloat = view.frame.height - view.frame.height/const
        let cancelFrame:CGRect = CGRect(x: 0, y: yPos, width: view.frame.width, height: view.frame.height/const)
        cancelBtn = UIButton(frame: cancelFrame)
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.backgroundColor = Colors.cinnabar
        cancelBtn.roundCorners([.bottomLeft,.bottomRight], radius: 12)
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        let addFriendOrigin:CGPoint = CGPoint(x: 0, y: view.frame.height - 2 * cancelBtn.frame.height)
        let addFriendFrame:CGRect = CGRect(origin: addFriendOrigin, size: cancelBtn.frame.size)
        addFriendBtn = UIButton(frame: addFriendFrame)
        configureFriendBtn()
        addFriendBtn.addTarget(self, action: #selector(addFriendTapped), for: .touchUpInside)
        
        let separatorFrame = CGRect(origin: cancelFrame.origin, size: CGSize(width: cancelFrame.width, height: 1))
        btnSeparator = UIView(frame: separatorFrame)
        btnSeparator.backgroundColor = UIColor.black
        let secondSeparatorFrame = CGRect(origin: addFriendFrame.origin, size: CGSize(width: addFriendFrame.width, height: 1))
        secondBtnSeparator = UIView(frame: secondSeparatorFrame)
        secondBtnSeparator.backgroundColor = Colors.blueGreen
        
        view.addSubview(secondBtnSeparator)
        view.addSubview(addFriendBtn)
        view.addSubview(btnSeparator)
        view.addSubview(cancelBtn)
        
        view.bringSubview(toFront: btnSeparator)
        view.bringSubview(toFront: secondBtnSeparator)
    }
    
    static private func setupProfilePic(on view:UIView, withUID uid:String) {
        let topOffset:CGFloat = 10
        let profilePicWidth:CGFloat = view.frame.width/2
        let xPos:CGFloat = view.frame.width/4
        profilePic.frame = CGRect(x: xPos, y: topOffset, width: profilePicWidth, height: profilePicWidth)
        profilePic.layer.cornerRadius = profilePicWidth/2
        profilePic.layer.masksToBounds = true
        
        layoutProfilePicBorder(forPicture: profilePic)
        
        let picRef = FIRStorage.storage().reference(withPath: "Users/User: \(uid)/profilePicture")
        
        picRef.data(withMaxSize: 10*1024*1024, completion: { (data, error) in
            if error == nil {
                let profilePicture = UIImage(data: data!)
                self.profilePic.image = profilePicture
            }
        })
        
        view.addSubview(profilePic)
    }
    
    static private func layoutProfilePicBorder(forPicture profilePic:UIImageView) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: profilePic.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(ovalIn: profilePic.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor // causing lag when scrolling
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        
        
        
        profilePic.layoutIfNeeded()
        profilePic.clipsToBounds = true
        profilePic.layer.masksToBounds = true
        profilePic.layer.cornerRadius = profilePic.bounds.size.width/2.0
        profilePic.layer.addSublayer(gradient)
    }
    
    static private func setupUsernameLabel(on view:UIView, withUID uid:String) {
        
        usernameLbl.frame = CGRect(x: 0, y: profilePic.frame.maxY, width: view.frame.width, height: 40)
        usernameLbl.textAlignment = .center
        usernameLbl.text = pickedUser!.username
        
        view.addSubview(usernameLbl)
    }
    
    static private func configureFriendBtn() {
        if isFriends! {
            addFriendBtn.setTitle("Remove", for: .normal)
            addFriendBtn.backgroundColor = UIColor.white
            addFriendBtn.setTitleColor(Colors.blueGreen, for: .normal)
        }
        else {
            addFriendBtn.setTitle("Add", for: .normal)
            addFriendBtn.backgroundColor = Colors.blueGreen
            addFriendBtn.setTitleColor(UIColor.white, for: .normal)
        }
        
    }
    
    @objc static func cancelTapped() {
        print("CANCEL TAPPED")
        isVisible = false
        tableView.isUserInteractionEnabled = true
        tableView.isScrollEnabled = scrollingWasEnabled
        tableView.reloadData()
        newView.removeFromSuperview()
        greyView.removeFromSuperview()
    }
    
    @objc static private func addFriendTapped() {
        if isFriends! {
            currentUser?.removeFriend(uid: pickedUser!.userID)
            UserData.friends = currentUser?.friends
        }
        else {
            currentUser?.addFriend(uid: pickedUser!.userID)
            UserData.friends = currentUser?.friends
        }
        print(currentUser!.friends)
        let userRef = FIRDatabase.database().reference(withPath: "Users/User: \(currentUser!.userID)")
        userRef.setValue(currentUser?.toAnyObject())
        
        isFriends = !isFriends!
        configureFriendBtn()
        
        
        tableView.reloadData()
        
    }
}

//REMEMBER TO UPDATE currentUser() IN ONE OF THE TABLEVIEW DELEGATE METHODS WHENEVER THIS IS USED
extension ProfileInfo {
    static func presentOnTableView(tableView:UITableView, userID uid:String, superViewFrame viewFrame:CGRect, currentUser:User) {
        self.isVisible = true
        self.profilePic.image = #imageLiteral(resourceName: "DefaultProfileImg")
        self.currentUser = currentUser
        let userRef = FIRDatabase.database().reference(withPath: "Users/User: \(uid)")
        
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            pickedUser = User(snapshot: snapshot)
            isFriends = currentUser.friends.contains(pickedUser!.userID)
            
            newView =  self.profileInfoView(uid: uid, superViewFrame: viewFrame)
            
            greyView.frame = viewFrame
            greyView.backgroundColor = UIColor.darkGray
            greyView.alpha = 0.8
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
            greyView.addGestureRecognizer(tapGesture)
            
            scrollingWasEnabled = tableView.isScrollEnabled
            self.tableView = tableView
            
            tableView.isScrollEnabled = false
            tableView.isUserInteractionEnabled = false
            tableView.superview?.superview?.addSubview(greyView)
            tableView.superview?.superview?.addSubview(newView)
            tableView.bringSubview(toFront: newView)
        })
    }
    
    static func presentOnTableView(tableView:UITableView, userID uid:String, superViewFrame viewFrame:CGRect, currentUser:User, profilePic:UIImage) {
        self.profilePic.image = profilePic
        self.currentUser = currentUser
        let userRef = FIRDatabase.database().reference(withPath: "Users/User: \(uid)")
        
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            pickedUser = User(snapshot: snapshot)
            isFriends = currentUser.friends.contains(pickedUser!.userID)
            
            newView =  self.profileInfoView(uid: uid, superViewFrame: viewFrame)
            
            greyView.frame = viewFrame
            greyView.backgroundColor = UIColor.darkGray
            greyView.alpha = 0.8
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
            greyView.addGestureRecognizer(tapGesture)
            
            scrollingWasEnabled = tableView.isScrollEnabled
            self.tableView = tableView
            
            
            
            tableView.isScrollEnabled = false
            tableView.isUserInteractionEnabled = false
            tableView.superview?.superview?.addSubview(greyView)
            tableView.superview?.superview?.addSubview(newView)
            tableView.bringSubview(toFront: newView)
        })
    }

}
