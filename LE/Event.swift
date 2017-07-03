//
//  Event.swift
//  LE
//
//  Created by Rahil Patel on 1/28/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Event {
    var description: String
    var day: String
    var month: String
    var year: String
    var hour: String
    var minute: String
    var address: String
    var latitude: Double
    var longitude: Double
    let ref: FIRDatabaseReference?
    var isPublic: Bool
    var invitedFriends: [String]
    var createdByUID: String
    
    //now obsolete; need to delete it and all references to it
    var eventID: Int

    
    init (description: String,
          day: String,
          month: String,
          year: String,
          hour: String,
          minute: String,
          address: String,
          latitude: Double,
          longitude: Double,
          eventID: Int,
          isPublic: Bool,
          invitedFriends: [String],
          createdByUID: String) {
        self.description = description
        self.day = day
        self.month = month
        self.year = year
        self.hour = hour
        self.minute = minute
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.ref = nil
        self.eventID = eventID
        self.isPublic = isPublic
        self.invitedFriends = invitedFriends
        self.createdByUID = createdByUID
    }
    
    init (snapshot: FIRDataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject]
        description = snapshotValue["description"] as! String
        day = snapshotValue["day"] as! String
        month = snapshotValue["month"] as! String
        year = snapshotValue["year"] as! String
        hour = snapshotValue["hour"] as! String
        minute = snapshotValue["minute"] as! String
        address = snapshotValue["address"] as! String
        latitude = snapshotValue["latitude"] as! Double
        longitude = snapshotValue["longitude"] as! Double
        eventID = snapshotValue["eventID"] as! Int
        ref = snapshot.ref
        isPublic = snapshotValue["isPublic"] as! Bool
        let invitedFriendsStringRep = snapshotValue["invitedFriends"] as! String
        invitedFriends = invitedFriendsStringRep.characters.split{$0 == ","}.map(String.init)
        createdByUID = snapshotValue["createdByUID"] as! String
    }
    
    mutating func addFriendToEvent(withID: String) {
        invitedFriends.append(withID)
    }
    
    func toAnyObject() -> Any {
        let invitedFriendsStringRep = invitedFriends.joined(separator: ",")
        return [
            "description": description,
            "day": day,
            "month": month,
            "year": year,
            "hour": hour,
            "minute": minute,
            "address": address,
            "latitude": latitude,
            "longitude": longitude,
            "eventID": eventID,
            "isPublic": isPublic,
            "invitedFriends": invitedFriendsStringRep,
            "createdByUID": createdByUID
        ]
    }
}
