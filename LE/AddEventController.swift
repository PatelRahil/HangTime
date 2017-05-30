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
import Firebase

//For limiting the length of a textfield
private var __maxLengths = [UITextField: Int]()
extension UITextField {
    @IBInspectable var maxLength: Int {
        get {
            guard let l = __maxLengths[self] else {
                return 150 // (global default-limit. or just, Int.max)
            }
            return l
        }
        set {
            __maxLengths[self] = newValue
            addTarget(self, action: #selector(fix), for: .editingChanged)
        }
    }
    func fix(textField: UITextField) {
        let t = textField.text
        textField.text = t?.safelyLimitedTo(length: maxLength)
    }
}

extension String
{
    func safelyLimitedTo(length n: Int)->String {
        let c = self.characters
        if (c.count <= n) { return self }
        return String( Array(c).prefix(upTo: n) )
    }
}

class AddEventController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var DescriptionTextbox: UITextField!
    @IBOutlet weak var AddressTextbox:
    UITextField!
    @IBOutlet weak var myDatePicker: UIDatePicker!
    
    @IBOutlet weak var AddressInvalid: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var AnyoneCanViewLbl: UILabel!
    @IBOutlet weak var FriendsLbl: UILabel!
    @IBOutlet weak var DetailsBtn: UIButton!
    @IBOutlet weak var AddFriendsBtn: UIButton!

    
    lazy var geocoder = CLGeocoder()
    
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Events")
    let userRef = FIRDatabase.database().reference(withPath: "Users")

    var currentUser: User? = nil
    
    var validEntries = false
    var day = 0
    var month = 0
    var year = 0
    var minute = 0
    var hour = 0
    
    var invitedFriendsUIDs:[String] = []
    var invitedFriendsUsernames:[String] = []
    var isPublic:Bool = true
    
    /*
    @IBAction func CancelButton(_ sender: Any) {
        segueRightToLeft(storyboardIdentifier: "RevealViewController")
    }
     */
    
    @IBAction func datePicker(_ sender: Any) {
        let components = myDatePicker.calendar.dateComponents([.year, .month, .day, .minute, .hour], from: myDatePicker.date)

        day = components.day!
        month = components.month!
        year = components.year!
        minute = components.minute!
        hour = components.hour!
    }
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        print("Switched to: \(segmentedControl.selectedSegmentIndex)")
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            DetailsBtn.isHidden = true
            AddFriendsBtn.isHidden = true
            FriendsLbl.isHidden = true
            AnyoneCanViewLbl.isHidden = false
            isPublic = true
        case 1:
            DetailsBtn.isHidden = false
            AddFriendsBtn.isHidden = false
            FriendsLbl.isHidden = false
            AnyoneCanViewLbl.isHidden = true
            isPublic = false
        default:
            break
        }
        print("IS PUBLIC \(isPublic)")
    }
    @IBAction func viewDetails(_ sender: Any) {
    }
    @IBAction func addFriendsToEvent(_ sender: Any) {
        //self.performSegue(withIdentifier: "AddFriendsToEventSegue", sender: sender)
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
        

            print("ADDRESS:::::::::::::::\(address)")
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
                print("**********Latitude: \(coordinate.latitude)")
            } else {
            }
        }
        
        calculateID(sender:sender)

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
    
    func createEvent(sender: Any, eventID: Int) {
        if isPublic {
            print(AddressTextbox.text ?? "OOPS")
            let event = Event(description: DescriptionTextbox.text!,
                              day: String(day),
                              month: String(month),
                              year: String(year),
                              hour: String(hour),
                              minute: String(minute),
                              address: AddressTextbox.text!,
                              latitude: EventVariables.latitude,
                              longitude: EventVariables.longitude,
                              eventID: eventID,
                              isPublic: isPublic,
                              invitedFriends: []
                
            )
            print("HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH")
            print(event)
            print(isPublic)
            print(EventVariables())
            let eventRefID = childRef.childByAutoId()
            currentUser?.addEvent(eventID: eventRefID.key)
            let userRef = self.userRef.child("User: \(currentUser!.userID)")
            userRef.setValue(currentUser!.toAnyObject())
            
            eventRefID.setValue(event.toAnyObject())
        }
        else {
            let event = Event(description: DescriptionTextbox.text!,
                              day: String(day),
                              month: String(month),
                              year: String(year),
                              hour: String(hour),
                              minute: String(minute),
                              address: AddressTextbox.text!,
                              latitude: EventVariables.latitude,
                              longitude: EventVariables.longitude,
                              eventID: eventID,
                              isPublic: isPublic,
                              invitedFriends: invitedFriendsUIDs
            
            )
            let eventRefID = childRef.childByAutoId()
            currentUser?.addEvent(eventID: eventRefID.key)
            let userRef = self.userRef.child("User: \(currentUser!.userID)")
            userRef.setValue(currentUser!.toAnyObject())
            
            eventRefID.setValue(event.toAnyObject())
        }

        segueRightToLeft(storyboardIdentifier: "RevealViewController")
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
    
    func loadUser() {
        if let currentUser = FIRAuth.auth()?.currentUser {
            let userID = currentUser.uid
            let userRef = FIRDatabase.database().reference(withPath: "Users")
            userRef.observe(.value, with: { snapshot in
                for item in snapshot.children.allObjects as! [FIRDataSnapshot] {
                    let dict = item.value as! Dictionary<String,Any>
                    if (dict["UserID"] as? String == userID) {
                        self.currentUser = User(snapshot: item)
                    }
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUser()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.isNavigationBarHidden = false

        let minDate:Date = Date()
        print(minDate)
        myDatePicker.minimumDate = minDate
        
        self.AddressTextbox.delegate = self
        self.DescriptionTextbox.delegate = self
        
        DetailsBtn.isHidden = true
        AddFriendsBtn.isHidden = true
        FriendsLbl.isHidden = true
        AnyoneCanViewLbl.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddFriendsToEventSegue" {
            let nextController = (segue.destination as! AddFriendsToEventVC)
            nextController.addedFriends = invitedFriendsUIDs
            
            let backItem = UIBarButtonItem()
            backItem.title = "Cancel"
            navigationItem.backBarButtonItem = backItem
        }
        if segue.identifier == "DetailsSegue" {
            let nextController = (segue.destination as! EventFriendListVC)
            nextController.invitedFriendsUIDs = invitedFriendsUIDs
            nextController.invitedFriendsUsernames = invitedFriendsUsernames
            nextController.currentUser = currentUser
            
            let backItem = UIBarButtonItem()
            backItem.title = "Create Event"
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("$$$$$$$$$$$$$$$$$$$$$$$$\n\(invitedFriendsUsernames)")
        invitedFriendsUsernames = InvitedFriends.invitedFriendsUsernames
        invitedFriendsUIDs = InvitedFriends.invitedFriendsUIDs
        let invitedFriendsStringRep:String = invitedFriendsUsernames.joined(separator: ", ")
        if invitedFriendsUIDs.count == 0 {
            FriendsLbl.text = "You haven't added any friends yet"
        }
        else {
            FriendsLbl.textColor = UIColor.black
            FriendsLbl.text = invitedFriendsStringRep
        }
    }
}


