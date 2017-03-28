//
//  AddEventController.swift
//  LE
//
//  Created by Rahil Patel on 11/13/16.
//  Copyright © 2016 Rahil. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import FirebaseDatabase

class AddEventController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var DescriptionTextbox: UITextField!
    @IBOutlet weak var HourTextbox: UITextField!
    @IBOutlet weak var MinuteTextbox: UITextField!
    @IBOutlet weak var DayTextbox: UITextField!
    @IBOutlet weak var YearTextbox: UITextField!
    @IBOutlet weak var MonthTextbox: UITextField!
    @IBOutlet weak var AddressTextbox:
    UITextField!
    
    @IBOutlet weak var AddressInvalid: UILabel!
    @IBOutlet weak var DateInvalid: UILabel!
    @IBOutlet weak var TimeInvalid: UILabel!
    
    
    lazy var geocoder = CLGeocoder()
    
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Events")

    var validEntries = false
    
    @IBAction func CreateEventButton(_ sender: Any, forEvent event: UIEvent) {
        validEntries = false

        let date = NSDate()
        let calendar = NSCalendar.current
        let day = calendar.component(.day, from: date as Date)
        let month = calendar.component(.month, from: date as Date)
        let year = calendar.component(.year, from: date as Date)
        
        if (AddressTextbox.text?.isEmpty)! {
            AddressInvalid.text = "Please enter a valid address"
        }
        if ((HourTextbox.text?.isEmpty)! || (MinuteTextbox.text?.isEmpty)!) {
            TimeInvalid.text = "Please enter a valid time"
        }
        if ((MonthTextbox.text?.isEmpty)! || (DayTextbox.text?.isEmpty)! || (YearTextbox.text?.isEmpty)!) {
            DateInvalid.text = "Please enter a valid date"
        }
        if (!(AddressTextbox.text?.isEmpty)! && !(HourTextbox.text?.isEmpty)! && !(MinuteTextbox.text?.isEmpty)! && !(DayTextbox.text?.isEmpty)! && !(MonthTextbox.text?.isEmpty)! && !(YearTextbox.text?.isEmpty)!) {
            var everythingIsFine = true
            var validMin = true
            var validHour = true
            var validDay = true
            var validMonth = true
            var validYear = true
            if Int(MinuteTextbox.text!)! >= 60 {
                TimeInvalid.text = "Please enter a valid time"
                everythingIsFine = false
                validMin = false
            }
            if Int(HourTextbox.text!)! > 12{
                TimeInvalid.text = "Please enter a valid time"
                everythingIsFine = false
                validHour = false
            }
            if (Int(DayTextbox.text!)! < day) && (Int(MonthTextbox.text!)! == month) && (Int(YearTextbox.text!)! == year) {
                DateInvalid.text = "Please enter a valid date"
                everythingIsFine = false
                validDay = false
            }
            if (Int(MonthTextbox.text!)! > 12 || (Int(MonthTextbox.text!)! < month && Int(YearTextbox.text!)! == year)) {
                DateInvalid.text = "Please enter a valid date"
                everythingIsFine = false
                validMonth = false
            }
            if Int(YearTextbox.text!)! < year {
                DateInvalid.text = "Please enter a valid date"
                everythingIsFine = false
                validYear = false
            }
            if validMin && validHour {
                TimeInvalid.text = ""
            }
            if validDay && validMonth && validYear {
                DateInvalid.text = ""
            }
            
            if everythingIsFine {
            validEntries = true
            AddressInvalid.text = ""
            TimeInvalid.text = ""
            DateInvalid.text = ""
            }
        }
        if (validEntries==true) {
            EventVariables.eventIsCreated = true
            let address = AddressTextbox.text
            var tempDesc = DescriptionTextbox.text
            if (tempDesc == " ") {
                tempDesc = ""
            }
            EventVariables.description = tempDesc!
            EventVariables.dateDay = Int(DayTextbox.text!)!
            EventVariables.dateMonth = Int(MonthTextbox.text!)!
            EventVariables.dateYear = Int(YearTextbox.text!)!
            EventVariables.timeHr = Int(HourTextbox.text!)!
            EventVariables.timeMin = Int(MinuteTextbox.text!)!
            EventVariables.address = address!
        

        
            geocoder.geocodeAddressString(address!) { (placemarks, error) in
                // Process Response
                self.processResponse(withPlacemarks: placemarks, error: error, sender: sender)
            }
        }
        
    }
    
    private func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?, sender: Any) {
        // Update View

        if let error = error {
            print("Unable to Forward Geocode Address (\(error))")
            
        } else {
            var location: CLLocation?
            
            if let placemarks = placemarks, placemarks.count > 0 {
                location = placemarks.first?.location
            }
            
            if let location = location {
                let coordinate = location.coordinate
                EventVariables.latitude = Double(coordinate.latitude)
                EventVariables.longitude = Double(coordinate.longitude)
                print(coordinate.latitude)
            } else {
            }
        }
        
        calculateID(sender:sender)
        
        /*let event = Event(description: DescriptionTextbox.text!,
            day: DayTextbox.text!,
            month: MonthTextbox.text!,
            year: YearTextbox.text!,
            hour: HourTextbox.text!,
            minute: MinuteTextbox.text!,
            address: AddressTextbox.text!,
            latitude: EventVariables.latitude,
            longitude: EventVariables.longitude,
            eventID: Int(calculateID())//eventID
            
        )
        
                
        let eventRef = self.childRef.child("Event ID: " + String(calculateID()/*eventID*/))
        eventRef.setValue(event.toAnyObject())
        
        performSegue(withIdentifier: "CreateEventSegue", sender: sender)
         */
    }
    
    func createEvent(sender: Any, eventID: Int) {
        let event = Event(description: DescriptionTextbox.text!,
                          day: DayTextbox.text!,
                          month: MonthTextbox.text!,
                          year: YearTextbox.text!,
                          hour: HourTextbox.text!,
                          minute: MinuteTextbox.text!,
                          address: AddressTextbox.text!,
                          latitude: EventVariables.latitude,
                          longitude: EventVariables.longitude,
                          eventID: eventID
            
        )
        
        
        let eventRef = self.childRef.child("Event ID: " + String(eventID))
        eventRef.setValue(event.toAnyObject())
        
        performSegue(withIdentifier: "CreateEventSegue", sender: sender)
    }
    
    func calculateID(sender:Any) {
        childRef.observeSingleEvent(of:.value, with: { (snapshot: FIRDataSnapshot!) in
            var eventID = 0;
            for item in snapshot.children {
                let event = Event(snapshot: item as! FIRDataSnapshot)
                if event.eventID >= eventID {
                    eventID = event.eventID + 1
                    print(eventID)
                }
            }
            
            
            self.createEvent(sender: sender, eventID: Int(eventID))
            
        })
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "CreateEventSegue" {
            if validEntries {
                return true
            }
            else {
                return false
            }
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.dataLabel!.text = dataObject
    }
}
