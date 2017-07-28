//
//  User.swift
//  LE
//
//  Created by Rahil Patel on 5/15/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Firebase

class User {

    var userID:String
    var friends:[String]
    var username:String
    var createdEvents:[String]
    var profilePicDownloadLink:String
    var invitedEvents:[String:Int] = [String:Int]()
    
    var profilePic:UIImage? = #imageLiteral(resourceName: "DefaultProfileImg")
    
    init(uid:String, username:String) {
        self.userID = uid
        self.username = username
        self.friends = []
        self.createdEvents = []
        self.profilePicDownloadLink = ""
        self.invitedEvents = [String:Int]()
    }
    
    init (snapshot: FIRDataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject]
        username = snapshotValue["username"] as! String
        userID = snapshotValue["UserID"] as! String
        
        let friendsStringRep = snapshotValue["friends"] as! String
        friends = friendsStringRep.characters.split{$0 == ","}.map(String.init)
        let eventsStringRep = snapshotValue["createdEvents"] as! String
        createdEvents = eventsStringRep.characters.split{$0 == ","}.map(String.init)
        profilePicDownloadLink = snapshotValue["profilePicture"] as! String
        
        if let invitedEvents = snapshotValue["invitedEvents"] as? [String:Int] {
            self.invitedEvents = invitedEvents
        }
        
    }
    
    init (data:UserData) {
        userID = data._userID!
        friends = data._friends!
        username = data._username!
        createdEvents = data._createdEvents!
        profilePicDownloadLink = data._profilePicDownloadLink!
        profilePic = data._profilePic!
        invitedEvents = data._invitedEvents!
    }
    
    func addFriend(uid:String) {
        self.friends.append(uid)
    }
    func removeFriend(uid:String) {
        for (index,friend) in self.friends.enumerated() {
            if friend == uid {
                friends.remove(at: index)
            }
        }
    }
    func stillFriends(with uid:String) -> Bool {
        for friend in self.friends {
            if friend == uid {
                return true
            }
        }
        
        return false
    }
    func changeUsername(username: String) {
        self.username = username
    }
    func addEvent(eventID:String) {
        self.createdEvents.append(eventID)
    }
    func getUserID() -> String {
        return userID
    }
    
    func toAnyObject() -> Any {
        let friendsStringRep = friends.joined(separator: ",")
        let createdEventsStringRep = createdEvents.joined(separator: ",")
        
        return [
            "UserID":userID,
            "friends":friendsStringRep,
            "username":username,
            "createdEvents": createdEventsStringRep,
            "profilePicture": profilePicDownloadLink,
            "invitedEvents": invitedEvents
        ]
    }
}



struct UserData {
    static var userID:String? = nil
    static var friends:[String]? = nil
    static var username:String? = nil
    static var createdEvents:[String]? = nil
    static var profilePicDownloadLink:String? = nil
    static var profilePic:UIImage? = #imageLiteral(resourceName: "DefaultProfileImg")
    static var invitedEvents:[String:Int]? = nil
    
    var _userID:String? = nil
    var _friends:[String]? = nil
    var _username:String? = nil
    var _createdEvents:[String]? = nil
    var _profilePicDownloadLink:String? = nil
    var _profilePic:UIImage? = #imageLiteral(resourceName: "DefaultProfileImg")
    var _invitedEvents:[String:Int]? = nil
    ///Want to set or change profile picture
    static func updateData(withUser user:User) {
        userID = user.userID
        friends = user.friends
        username = user.username
        createdEvents = user.createdEvents
        profilePicDownloadLink = user.profilePicDownloadLink
        invitedEvents = user.invitedEvents
    }
    
    ///Profile picture does not need to change
    static func updateData(withUser user:User, profilePic image:UIImage) {
        userID = user.userID
        friends = user.friends
        username = user.username
        createdEvents = user.createdEvents
        profilePicDownloadLink = user.profilePicDownloadLink
        profilePic = image
        invitedEvents = user.invitedEvents
    }
    
    init() {
        _userID = UserData.userID
        _friends = UserData.friends
        _username = UserData.username
        _createdEvents = UserData.createdEvents
        _profilePicDownloadLink = UserData.profilePicDownloadLink
        _profilePic = UserData.profilePic
        _invitedEvents = UserData.invitedEvents
        
    }
}
