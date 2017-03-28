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
          eventID: Int) {
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
    }
    
    func toAnyObject() -> Any {
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
            "eventID": eventID
        ]
    }
}
