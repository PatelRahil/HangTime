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

struct User {
    
    var userID:String
    var friends:[String]
    var username:String
    var createdEvents:[String]
    
    init(uid:String, username:String) {
        self.userID = uid
        self.username = username
        self.friends = []
        self.createdEvents = []
    }
    
    init (snapshot: FIRDataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject]
        username = snapshotValue["username"] as! String
        userID = snapshotValue["UserID"] as! String
        
        if let friendsStringRep = snapshotValue["friends"] as? String {
            friends = friendsStringRep.characters.split{$0 == ","}.map(String.init)
            if let eventsStringRep = snapshotValue["createdEvents"] as? String {
                createdEvents = eventsStringRep.characters.split{$0 == ","}.map(String.init)
            }
            else {
                createdEvents = []
                let childRef = FIRDatabase.database().reference(withPath: "Users")
                let userRef = childRef.child("User: \(self.userID)")
                userRef.setValue(self.toAnyObject())
            }
        }
        else {
            friends = []
            let childRef = FIRDatabase.database().reference(withPath: "Users")
            let userRef = childRef.child("User: \(self.userID)")
            if let eventsStringRep = snapshotValue["createdEvents"] as? String {
                createdEvents = eventsStringRep.characters.split{$0 == ","}.map(String.init)
            }
            else {
                createdEvents = []
                let childRef = FIRDatabase.database().reference(withPath: "Users")
                let userRef = childRef.child("User: \(self.userID)")
                userRef.setValue(self.toAnyObject())
            }
            userRef.setValue(self.toAnyObject())
        }
        
    }
    
    mutating func addFriend(uid:String) {
        self.friends.append(uid)
    }
    mutating func changeUsername(username: String) {
        self.username = username
    }
    mutating func addEvent(eventID:String) {
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
            "createdEvents": createdEventsStringRep
        ]
    }
}

class Global {
    
    //Global.sharedGlobal is a singleton
    static let sharedGlobal = Global()
    
    var member:User = User(uid: "", username: "")
    
}
