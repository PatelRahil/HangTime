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
    let storageRef = FIRStorage.storage().reference()

    var userID:String
    var friends:[String]
    var username:String
    var createdEvents:[String]
    var profilePicDownloadLink:String
    
    init(uid:String, username:String) {
        self.userID = uid
        self.username = username
        self.friends = []
        self.createdEvents = []
        self.profilePicDownloadLink = ""
    }
    
    init (snapshot: FIRDataSnapshot, completionHandler: () -> Void) {
        let snapshotValue = snapshot.value as! [String: AnyObject]
        username = snapshotValue["username"] as! String
        userID = snapshotValue["UserID"] as! String
        if let friendsStringRep = snapshotValue["friends"] as? String {
            
            friends = friendsStringRep.characters.split{$0 == ","}.map(String.init)
            if let eventsStringRep = snapshotValue["createdEvents"] as? String {
                createdEvents = eventsStringRep.characters.split{$0 == ","}.map(String.init)
                let childRef = FIRDatabase.database().reference(withPath: "Users")
                let userRef = childRef.child("User: \(self.userID)")
                if let profilePicLink = snapshotValue["profilePicture"] as? String {
                    profilePicDownloadLink = profilePicLink
                }
                else {
                    profilePicDownloadLink = ""
                }
                userRef.setValue(self.toAnyObject())
            }
            else {
                createdEvents = []
                let childRef = FIRDatabase.database().reference(withPath: "Users")
                let userRef = childRef.child("User: \(self.userID)")
                if let profilePicLink = snapshotValue["profilePicture"] as? String {
                    profilePicDownloadLink = profilePicLink
                }
                else {
                    profilePicDownloadLink = ""
                }
                userRef.setValue(self.toAnyObject())
            }
        }
        else {
            friends = []
            let childRef = FIRDatabase.database().reference(withPath: "Users")
            let userRef = childRef.child("User: \(self.userID)")
            if let eventsStringRep = snapshotValue["createdEvents"] as? String {
                createdEvents = eventsStringRep.characters.split{$0 == ","}.map(String.init)
                if let profilePicLink = snapshotValue["profilePicture"] as? String {
                    profilePicDownloadLink = profilePicLink
                }
                else {
                    profilePicDownloadLink = ""
                }
                userRef.setValue(self.toAnyObject())
            }
            else {
                createdEvents = []
                let childRef = FIRDatabase.database().reference(withPath: "Users")
                let userRef = childRef.child("User: \(self.userID)")
                if let profilePicLink = snapshotValue["profilePicture"] as? String {
                    profilePicDownloadLink = profilePicLink
                }
                else {
                    profilePicDownloadLink = ""
                }
            }
            userRef.setValue(self.toAnyObject())
        }
        
    }
    
    func addFriend(uid:String) {
        self.friends.append(uid)
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
            "profilePicture": profilePicDownloadLink
        ]
    }
}
