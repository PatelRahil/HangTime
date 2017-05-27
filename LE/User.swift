//
//  User.swift
//  LE
//
//  Created by Rahil Patel on 5/15/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct User {
    var userID:String
    var friends:[String]
    var username:String
    
    init(uid:String, username:String) {
        self.userID = uid
        self.username = username
        self.friends = []
    }
    
    init (snapshot: FIRDataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject]
        username = snapshotValue["username"] as! String
        userID = snapshotValue["UserID"] as! String
        let friendsStringRep = snapshotValue["friends"] as! String
        /*for (var i = 0; i < friendsStringRep.characters.count; i += 1) {
            if ()
        } */
        friends = friendsStringRep.characters.split{$0 == ","}.map(String.init)
    }
    
    mutating func addFriend(uid:String) {
        friends.append(uid)
    }
    mutating func changeUsername(username: String) {
        self.username = username
    }
    
    func getUserID() -> String {
        return userID
    }
    
    func toAnyObject() -> Any {
        let friendsStringRep = friends.joined(separator: ",")
        
        return [
            "UserID":userID,
            "friends":friendsStringRep,
            "username":username
        ]
    }
}

class Global {
    
    //Global.sharedGlobal is a singleton
    static let sharedGlobal = Global()
    
    var member:User = User(uid: "", username: "")
    
}
