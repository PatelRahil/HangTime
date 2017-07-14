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
    @IBOutlet weak var InvitedFriendsLbl: UILabel!
    
    @IBOutlet weak var AddressInvalid: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var AnyoneCanViewLbl: UILabel!
    @IBOutlet weak var FriendsLbl: UILabel!
    @IBOutlet weak var DetailsBtn: UIButton!
    @IBOutlet weak var AddFriendsBtn: UIButton!
    @IBOutlet weak var CreateEventBtn: UIButton!
    
    lazy var geocoder = CLGeocoder()
    
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Events")
    let userRef = FIRDatabase.database().reference(withPath: "Users")

    var currentUser: User? = nil
    
    var validEntries = false
    var validAddress = false
    
    var address = ""
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
            InvitedFriendsLbl.isHidden = true
            isPublic = true
        case 1:
            DetailsBtn.isHidden = false
            AddFriendsBtn.isHidden = false
            FriendsLbl.isHidden = false
            AnyoneCanViewLbl.isHidden = true
            InvitedFriendsLbl.isHidden = false
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
        if validEntries {
            EventVariables.eventIsCreated = true
            let address = AddressTextbox.text
            var tempDesc = DescriptionTextbox.text
            if (tempDesc == " ") {
                tempDesc = ""
            }
            
            //following conditional is for if the user didn't interact with the date picker at all
            if year == 0 {
                let minDate:Date = Date()
                let calendar = Calendar.current
                day = calendar.component(.day, from: minDate)
                month = calendar.component(.month, from: minDate)
                year = calendar.component(.year, from: minDate)
                hour = calendar.component(.hour, from: minDate)
                minute = calendar.component(.minute, from: minDate)
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
            validAddress = false
            
        } else {
            if let placemarks = placemarks, placemarks.count > 1 {
                print("MULTIPLE ADDRESSES")
                validAddress = false
            }
            else {
                validAddress = true
            }
            
            var location: CLLocation?
            
            if let placemarks = placemarks, placemarks.count > 0 {
                location = placemarks.first?.location
                
                var addressArr = placemarks.first!.addressDictionary!["FormattedAddressLines"] as! [String]
                print(addressArr)
                addressArr.removeLast()
                let address = addressArr.joined(separator: ", ")
                print(address)
                self.address = address
                
            }
            
            if let location = location {
                let coordinate = location.coordinate
                EventVariables.latitude = Double(coordinate.latitude)
                EventVariables.longitude = Double(coordinate.longitude)
            } else {
            }
        }
        
        calculateID(sender:sender)

    }
    
    private func calculateID(sender:Any) {
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
    
    private func createEvent(sender: Any, eventID: Int) {
        var eventStrID:String? = nil
        if isPublic {
            print(AddressTextbox.text ?? "OOPS")
            let event = Event(description: DescriptionTextbox.text!,
                              day: String(self.day),
                              month: String(self.month),
                              year: String(self.year),
                              hour: String(self.hour),
                              minute: String(self.minute),
                              address: self.address,
                              latitude: EventVariables.latitude,
                              longitude: EventVariables.longitude,
                              eventID: eventID,
                              isPublic: self.isPublic,
                              invitedFriends: [],
                              createdByUID: self.currentUser!.userID
                
            )
            
            let eventRefID = childRef.childByAutoId()
            eventStrID = eventRefID.key
            currentUser?.addEvent(eventID: eventRefID.key)
            let userRef = self.userRef.child("User: \(currentUser!.userID)")
            userRef.setValue(currentUser!.toAnyObject())
            UserData.updateData(withUser: currentUser!)
            eventRefID.setValue(event.toAnyObject())
        }
        else {
            let event = Event(description: DescriptionTextbox.text!,
                              day: String(self.day),
                              month: String(self.month),
                              year: String(self.year),
                              hour: String(self.hour),
                              minute: String(self.minute),
                              address: self.address,
                              latitude: EventVariables.latitude,
                              longitude: EventVariables.longitude,
                              eventID: eventID,
                              isPublic: self.isPublic,
                              invitedFriends: self.invitedFriendsUIDs,
                              createdByUID: self.currentUser!.userID
            
            )
            let eventRefID = childRef.childByAutoId()
            eventStrID = eventRefID.key
            currentUser?.addEvent(eventID: eventRefID.key)
            let userRef = self.userRef.child("User: \(currentUser!.userID)")
            userRef.setValue(currentUser!.toAnyObject())
            UserData.updateData(withUser: currentUser!)
            eventRefID.setValue(event.toAnyObject())
        }
        
        updateFriendsDB(eventStrID: eventStrID!)
        
        segueRightToLeft(storyboardIdentifier: "RevealViewController")
    }
    
    private func updateFriendsDB(eventStrID:String) {
        for userID in invitedFriendsUIDs {
            let userRef = FIRDatabase.database().reference(withPath: "Users/User: \(userID)")
            let invitedEventsRef = userRef.child("invitedEvents")
            invitedEventsRef.observeSingleEvent(of: .value, with: { (snapshot) in
                print(snapshot)
                if snapshot.exists() {
                    var snapDic = snapshot.value as! Dictionary<String,Int>
                    snapDic[eventStrID] = 0
                    invitedEventsRef.setValue(snapDic)
                }
                else {
                    let snapDic:Dictionary<String,Int> = ["\(eventStrID)":3]
                    invitedEventsRef.setValue(snapDic)
                }
            })
        }
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
            if validEntries && validAddress {
                return true
            }
            else {
                return false
            }
        }
        return true
    }
    
    func loadUser() {
        /*
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
         */
        currentUser = User(data: UserData())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadUser()
        self.navigationController?.isNavigationBarHidden = false

        InvitedFriends.reset()
        
        let minDate:Date = Date()
        myDatePicker.minimumDate = minDate
        
        segmentedControl.tintColor = Colors.blueGreen
        CreateEventBtn.backgroundColor = Colors.blueGreen
        CreateEventBtn.setTitleColor(UIColor.white, for: .normal)
        CreateEventBtn.layer.cornerRadius = 5
        
        self.AddressTextbox.delegate = self
        self.DescriptionTextbox.delegate = self
        
        DetailsBtn.isHidden = true
        AddFriendsBtn.isHidden = true
        FriendsLbl.isHidden = true
        AnyoneCanViewLbl.isHidden = false
        InvitedFriendsLbl.isHidden = true

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
            nextController.editable = true
            nextController.cameFromEventDetailsVC = false
            
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
            FriendsLbl.textColor = UIColor.gray
        }
        else {
            FriendsLbl.textColor = UIColor.black
            FriendsLbl.text = invitedFriendsStringRep
        }
    }
}


