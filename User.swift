//
//  User.swift
//  
//
//  Created by Rahil Patel on 5/15/17.
//
//

import Foundation
import FirebaseDatabase

struct User {
    var userID:String
    
    init(uid:String) {
        self.userID = uid;
    }
}
