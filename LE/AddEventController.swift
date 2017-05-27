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
    @IBOutlet weak var AddressTextbox:
    UITextField!
    @IBOutlet weak var myDatePicker: UIDatePicker!
    
    @IBOutlet weak var AddressInvalid: UILabel!
    @IBOutlet weak var DateInvalid: UILabel!
    @IBOutlet weak var TimeInvalid: UILabel!
    
    
    lazy var geocoder = CLGeocoder()
    
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Events")

    var validEntries = false
    var day = 0
    var month = 0
    var year = 0
    var minute = 0
    var hour = 0
    

    @IBAction func CancelButton(_ sender: Any) {
        segueRightToLeft(storyboardIdentifier: "RevealViewController")
    }
    @IBAction func datePicker(_ sender: Any) {
        let components = myDatePicker.calendar.dateComponents([.year, .month, .day, .minute, .hour], from: myDatePicker.date)

        day = components.day!
        month = components.month!
        year = components.year!
        minute = components.minute!
        hour = components.hour!
    }
    @IBAction func CreateEventButton(_ sender: Any, forEvent event: UIEvent) {
        validEntries = false

        if (AddressTextbox.text?.isEmpty)! {
            AddressInvalid.text = "Please enter a valid address"
        }

        //makes sure there isn't an empty textbox for address
        if (!(AddressTextbox.text?.isEmpty)!) {
            validEntries = true
            AddressInvalid.text = ""
        }
        if (validEntries==true) {
            EventVariables.eventIsCreated = true
            let address = AddressTextbox.text
            var tempDesc = DescriptionTextbox.text
            if (tempDesc == " ") {
                tempDesc = ""
            }
            EventVariables.description = tempDesc!
            EventVariables.dateDay = day
            EventVariables.dateMonth = month
            EventVariables.dateYear = year
            EventVariables.timeHr = hour
            EventVariables.timeMin = minute
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

    }
    
    func createEvent(sender: Any, eventID: Int) {
        let event = Event(description: DescriptionTextbox.text!,
                          day: String(day),
                          month: String(month),
                          year: String(year),
                          hour: String(hour),
                          minute: String(minute),
                          address: AddressTextbox.text!,
                          latitude: EventVariables.latitude,
                          longitude: EventVariables.longitude,
                          eventID: eventID
            
        )
        
        
        let eventRef = self.childRef.child("Event ID: " + String(eventID))
        eventRef.setValue(event.toAnyObject())
        
        //performSegue(withIdentifier: "CreateEventSegue", sender: sender)
        segueRightToLeft(storyboardIdentifier: "RevealViewController")
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func segueRightToLeft(storyboardIdentifier: String) {
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        view.window!.layer.add(transition, forKey: kCATransition)
        let secVC = self.storyboard?.instantiateViewController(withIdentifier: "\(storyboardIdentifier)") as! SWRevealViewController
        present(secVC, animated: false, completion: nil)
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
        let minDate:Date = Date()
        print(minDate)
        myDatePicker.minimumDate = minDate
        
        self.AddressTextbox.delegate = self;
        self.DescriptionTextbox.delegate = self;
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
