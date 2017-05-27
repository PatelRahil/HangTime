//
//  UserData.swift
//  LE
//
//  Created by Rahil Patel on 5/15/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct UserData {
    var userID:String
    
    init(uid:String) {
        self.userID = uid;
    }
    
    
}
