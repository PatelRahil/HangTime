//
//  EventDetailsVC.swift
//  LE
//
//  Created by Rahil Patel on 6/8/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import GoogleMaps

struct EventVariables {
    static var eventIsCreated = false
    static var latitude = 0.0
    static var longitude = 0.0
    static var description = ""
    static var address = ""
    static var eventID = ""
    static var dateMonth = 00
    static var dateDay = 00
    static var dateYear = 0000
    static var timeMin = 00
    static var timeHr = 00
    static var createdByUID = ""
    static var invitedFriends = [String]()
    static var isPublic = true
    
    static func reset() {
        self.eventIsCreated = false
        self.latitude = 0.0
        self.longitude = 0.0
        self.description = ""
        self.address = ""
        self.eventID = ""
        self.dateMonth = 00
        self.dateDay = 00
        self.dateYear = 0000
        self.timeMin = 00
        self.timeHr = 00
        self.createdByUID = ""
        self.invitedFriends = []
        self.isPublic = true
    }
    
    static func updateEventWithCurrentVariables() {
        let event = Event(description: EventVariables.description, day: String(EventVariables.dateDay), month: String(EventVariables.dateMonth), year: String(EventVariables.dateYear), hour: String(EventVariables.timeHr), minute: String(EventVariables.timeMin), address: EventVariables.address, latitude: EventVariables.latitude, longitude: EventVariables.longitude, eventID: 0, isPublic: EventVariables.isPublic, invitedFriends: EventVariables.invitedFriends, createdByUID: EventVariables.createdByUID)
        let childRef = FIRDatabase.database().reference(withPath: "Events")
        let eventRef = childRef.child(EventVariables.eventID)
        eventRef.setValue(event.toAnyObject())
    }
}


class EventDetailsVC:UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    lazy var geocoder = CLGeocoder()

    // MARK: - Firebase reference paths
    let userRef = FIRDatabase.database().reference(withPath: "Users")
    let storageRef = FIRStorage.storage().reference()
    // MARK: Users
    var currentUser:User? = nil
    var eventCreator:User? = nil
    
    // MARK: Array for tables
    //var TableArray = ["Created By", "Date", "Address", "Description","Invited Users"]
    var TableArray = ["Created By", "Date", "Address", "Description"] {
        willSet {
            print("TableArray is about to change to \(newValue)")
        }
        didSet{
            
        }
    }

    // MARK: Other variables
    var invitedFriendsUsernames = [String]()
    var eventInfo = [String]()
    var isEditSelected = false
    var shouldChangeInfoText = true
    
    // MARK: Variables for RSVP
    let segmentColors:[UIColor] = [UIColor.white, Colors.eucalyptus, Colors.royalBlue, Colors.cinnabar]
    let boxSubView = UIView()
    var prevTranslation:CGPoint = CGPoint.zero
    var initialYPos:CGFloat = 0

    
    // MARK: IBOutlets
    @IBOutlet weak var datePickerDoneBtn: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerSubview: CustomDatePickerView!
    @IBOutlet weak var EditEventInfo: UIButton!
    @IBOutlet weak var eventDetailsTableView: UITableView!
    @IBOutlet var greySubview: UIView!
    
    // MARK: - Button methods
    @IBAction func EditInfo(_ sender: Any) {
        if !eventInfo.isEmpty {
            isEditSelected = !isEditSelected
        
            if isEditSelected {
                eventDetailsTableView.reloadData()
                EditEventInfo.setTitle("Done", for: .normal)
                
            }
            else {
                eventDetailsTableView.reloadData()
                EditEventInfo.setTitle("Edit", for: .normal)
                
                saveTextFieldInfo()
                
                geocoder.geocodeAddressString(EventVariables.address) { (placemarks, error) in
                    // Process Response
                    self.processResponse(withPlacemarks: placemarks, error: error, sender: sender)
                    EventVariables.updateEventWithCurrentVariables()
                }
                
                
            }
        }
    }
    @IBAction func showDatePickerSubview(_ sender: Any) {
        saveTextFieldInfo()
        
        datePickerSubview.isHidden = false
        
        greySubview.isHidden = false
        eventDetailsTableView.isUserInteractionEnabled = false
        view.bringSubview(toFront: datePickerSubview)
        datePickerSubview.isUserInteractionEnabled = true
        
    }
    @IBAction func setDateAndTime(_ sender: Any) {
        let components = datePicker.calendar.dateComponents([.year, .month, .day, .minute, .hour], from: datePicker.date)
        EventVariables.dateDay = components.day!
        EventVariables.dateMonth = components.month!
        EventVariables.dateYear = components.year!
        EventVariables.timeMin = components.minute!
        EventVariables.timeHr = components.hour!
                
        eventDetailsTableView.reloadData()
        
        greySubview.isHidden = true
        datePickerSubview.isHidden = true
        eventDetailsTableView.isUserInteractionEnabled = true
    }

    // MARK: - View setup methods
    override func viewDidLoad() {
        self.navigationController?.isNavigationBarHidden = false
        //self.navigationController?.navigationBar.barTintColor = UIColor.init(r: 189, g: 195, b: 199, a: 0.5)
        self.navigationController?.navigationBar.isTranslucent = false
        
        
        //so the back button on VCs higher on the navigation stack have a back arrow without text
        self.title = ""
        currentUser = User(data: UserData())
        
        eventDetailsTableView.delegate = self
        eventDetailsTableView.dataSource = self
        eventDetailsTableView.backgroundColor = UIColor.init(red: 238.0/255, green: 238.0/255, blue: 238.0/255, alpha: 1)
        
        //all the UI stuff for the information tableview
        let containerView:UIView = UIView(frame:CGRect(x: view.frame.width/50, y: view.frame.width/50, width: 46 * view.frame.width / 50, height: view.frame.height - view.frame.width/3.125))
        eventDetailsTableView.isScrollEnabled = false
        eventDetailsTableView.separatorStyle = .none
        eventDetailsTableView.frame = containerView.frame
        containerView.backgroundColor = UIColor.clear
        containerView.layer.shadowColor = UIColor.darkGray.cgColor
        containerView.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.shadowRadius = 2
        eventDetailsTableView.layer.cornerRadius = 10
        eventDetailsTableView.layer.masksToBounds = true
        view.addSubview(containerView)
        containerView.addSubview(eventDetailsTableView)
    
        /*
        datePickerSubview.layer.shadowColor = UIColor.darkGray.cgColor
        datePickerSubview.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        datePickerSubview.layer.shadowOpacity = 1.0
        datePickerSubview.layer.shadowRadius = 2
         */
        datePickerSubview.layer.cornerRadius = 10
        datePickerSubview.layer.masksToBounds = true
 
        datePickerSubview.frame = CGRect(x: 2 * self.eventDetailsTableView.frame.minX, y: datePickerSubview.frame.minY, width: eventDetailsTableView.frame.width, height: datePickerSubview.frame.height)
        datePickerSubview.isHidden = true
        view.addSubview(datePickerSubview)
        
        greySubview.backgroundColor = UIColor.darkGray
        greySubview.frame = view.frame
        greySubview.alpha = 0.8
        view.addSubview(greySubview)
        greySubview.isHidden = true
        
        datePicker.minimumDate = Date()
        }
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = nil
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = nil
        //if enabled, causes problems with the navigation bar disappearing if the gesture is only half completed
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    // MARK: - Table view methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        print("THIS:   \(EventVariables.isPublic)    \(TableArray)")
        //if an event is switched from private to public at any point, this occurs
        if EventVariables.isPublic && TableArray.contains("Add More Friends") {
            
            // last element is "Add More Friends" because setTitle() appends it to the end of TableArray, and nothing else is appended to TableArray after that
            TableArray.removeLast()
        }
        
        //if an event is switched from private to public, and then back to private again at any point, these next two occur
        if (!TableArray.contains("Invited Users") && !EventVariables.isPublic) {
            TableArray.append("Invited Users")
        }
        
        if (!TableArray.contains("Add More Friends") && !EventVariables.isPublic) {
            if let id = eventCreator?.userID {
                if id == currentUser!.userID {
                    print(TableArray)
                    TableArray.append("Add More Friends")
                }
            }
        }
        if let eventCreator = eventCreator {
            if !EventVariables.isPublic {
                self.navigationItem.setTitle(title: "\(eventCreator.username)'s", subtitle: "Private Event")
            }
            else {
                self.navigationItem.setTitle(title: "\(eventCreator.username)'s", subtitle: "Public Event")
            }
        }
        return TableArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 132
        }
        else {
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if TableArray[indexPath.row] == "Invited Users" && !EventVariables.isPublic {
            saveTextFieldInfo()
            performSegue(withIdentifier: "invited friends", sender: indexPath)
        }
        if TableArray[indexPath.row] == "Add More Friends" {
            saveTextFieldInfo()
            performSegue(withIdentifier: "AddFriends", sender: indexPath)
        }
        eventDetailsTableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Profile Picture Cell", for: indexPath) as! CustomEventCreatorProfilePicCell
            layoutProfilePic(with: cell)
            cell.selectionStyle = .none
            cell.backgroundColor = Colors.darkGray
            //cell.backgroundColor = Colors.mintGreen
            return cell
        }
        else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DataAndTime", for: indexPath) as! CustomDateTimeDetailsCell
            cell.textLabel?.text = "Date"
            
            var dateAndTimeStr = "loading"
            if EventVariables.dateYear != 0 {
                dateAndTimeStr = formatDate(day: EventVariables.dateDay, month: EventVariables.dateMonth, year: EventVariables.dateYear, hour: EventVariables.timeHr, minute: EventVariables.timeMin)
            }

            cell.showDatePickerBtn.setTitle(dateAndTimeStr, for: .normal)
            cell.textLabel?.backgroundColor = UIColor.clear
            cell.backgroundColor = UIColor.init(red: 238.0/255, green: 238.0/255, blue: 238.0/255, alpha: 1)
            cell.showDatePickerBtn.setTitleColor(UIColor.init(red: 0, green: 0.478431, blue: 1, alpha: 1), for: .normal)
            cell.showDatePickerBtn.setTitleColor(UIColor.black, for: .disabled)
            cell.showDatePickerBtn.isEnabled = false
            //cell.showDatePickerBtn.backgroundColor = UIColor.red
            cell.selectionStyle = .none
            
            if EventVariables.createdByUID != currentUser!.userID || !isEditSelected {
                //cell.showDatePickerBtn.setTitleColor(UIColor.black, for: .normal)
                cell.showDatePickerBtn.isEnabled = false
            }
            else {
                cell.showDatePickerBtn.isEnabled = true
            }
            
            return cell
        }
        else if TableArray[indexPath.row] == "" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PublicPrivate", for: indexPath) as! CustomPublicPrivateCell
            cell.selectionStyle = .none
            cell.textLabel?.text = "Private"
            cell.textLabel?.backgroundColor = UIColor.clear
            cell.backgroundColor = UIColor.init(red: 238.0/255, green: 238.0/255, blue: 238.0/255, alpha: 1)

            cell.publicPrivateSwitch.onTintColor = Colors.blueGreen
            cell.publicPrivateSwitch.isOn = !EventVariables.isPublic
            
            return cell
        }
        else if TableArray[indexPath.row] == "Invited Users" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Invited Friends", for: indexPath)
            //cell.selectionStyle = .none
            if EventVariables.isPublic {
                cell.textLabel?.text = "This event is public"
                cell.selectionStyle = .none
                cell.accessoryType = .none
                cell.backgroundColor = UIColor.init(red: 238.0/255, green: 238.0/255, blue: 238.0/255, alpha: 1)
            }
            else {
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = TableArray[indexPath.row]
                cell.selectionStyle = .default
                cell.backgroundColor = UIColor.init(red: 238.0/255, green: 238.0/255, blue: 238.0/255, alpha: 1)
            }
            return cell
        }
        else if TableArray[indexPath.row] == "Add More Friends" {
            //index path should only be 6 if the event is not public and the user is the creator of the event
            let cell = tableView.dequeueReusableCell(withIdentifier: "Invited Friends", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = TableArray[indexPath.row]
            //cell.selectionStyle = .none
            cell.backgroundColor = UIColor.init(red: 238.0/255, green: 238.0/255, blue: 238.0/255, alpha: 1)
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Placeholder", for: indexPath) as! CustomEventDetailsCell
            
            cell.selectionStyle = .none
            cell.textLabel?.text = TableArray[indexPath.row]
            cell.textLabel?.backgroundColor = UIColor.clear
            cell.backgroundColor = UIColor.init(r: 238, g: 238, b: 238, a: 1)
            
            cell.EventDataTextField.delegate = self
            cell.EventDataTextField.isUserInteractionEnabled = false
            cell.EventDataTextField.backgroundColor = UIColor.clear
            cell.EventDataTextField.borderStyle = .none
            cell.layoutIfNeeded()

            if indexPath.row-2 < eventInfo.count && shouldChangeInfoText {
                cell.EventDataTextField.text = eventInfo[indexPath.row-2]
                cell.EventDataTextField.attributedPlaceholder = NSAttributedString(string: eventInfo[indexPath.row-2], attributes: [NSForegroundColorAttributeName:UIColor.black])
            }
            
            if isEditSelected {
                let border = CALayer()
                let width = CGFloat(1.0)
                border.borderColor = UIColor.darkGray.cgColor
                border.frame = CGRect(x: 0, y: cell.EventDataTextField.frame.size.height - width, width:  cell.EventDataTextField.frame.size.width, height: cell.EventDataTextField.frame.size.height)
                
                border.borderWidth = width
                cell.EventDataTextField.layer.addSublayer(border)
                cell.EventDataTextField.layer.masksToBounds = true
                if let placeholder = cell.EventDataTextField.placeholder {
                    cell.EventDataTextField.text = placeholder
                }
                cell.EventDataTextField.placeholder = nil
                cell.EventDataTextField.clearButtonMode = .whileEditing
                cell.EventDataTextField.isUserInteractionEnabled = true
                
                //eventInfo[indexPath.row - 2]
            }
            else {
                if let layers = cell.EventDataTextField.layer.sublayers {
                    layers[0].removeFromSuperlayer()
                }
                //cell.EventDataTextField.text = nil
                cell.EventDataTextField.isUserInteractionEnabled = false
            }
            
            return cell
        }
    }
    // MARK: - Textfield delegate methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    // MARK: - Previous VC uses this to update values
    func setTitle() {
        //self.title = "\(eventCreator!.username)'s Event"
        if !EventVariables.isPublic {
            self.navigationItem.setTitle(title: "\(eventCreator!.username)'s", subtitle: "Private Event")
        }
        else {
            self.navigationItem.setTitle(title: "\(eventCreator!.username)'s", subtitle: "Public Event")
        }
        if !EventVariables.isPublic && !TableArray.contains("Invited Users") {
            TableArray.append("Invited Users")
        }
        if EventVariables.createdByUID == currentUser!.userID {
            EditEventInfo.isHidden = false
            print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
            TableArray.insert("", at: 4)
            if !EventVariables.isPublic && !TableArray.contains("Add More Friends") {
                TableArray.append("Add More Friends")
            }
        }
        else {
            EditEventInfo.isHidden = true
            createRSVPBox()
        }

        eventInfo.append(EventVariables.address)
        eventInfo.append(EventVariables.description)
        loadCreatorProfilePic()
        datePicker.date = formatDate(day: EventVariables.dateDay, month: EventVariables.dateMonth, year: EventVariables.dateYear, hour: EventVariables.timeHr, minute: EventVariables.timeMin)
        
        eventDetailsTableView.reloadData()
    }
    
    // MARK: - Private methods (Convenience methods for organization)
    //used for formatting the title label of the date button
    private func formatDate(day:Int, month:Int, year:Int, hour:Int, minute:Int) -> String {
        var dayStr = String(day)
        var monthStr = String(month)
        var hourStr = String(hour)
        var minuteStr = String(minute)
        if day < 10 {
            dayStr = "0\(day)"
        }
        if month < 10 {
            monthStr = "0\(month)"
        }
        if hour < 10 {
            hourStr = "0\(hour)"
        }
        if minute < 10 {
            minuteStr = "0\(minute)"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let date : Date = dateFormatter.date(from: "\(year)-\(monthStr)-\(dayStr) \(hourStr):\(minuteStr)")!
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        //dateFormatter.dateFormat = "MMM dd, yyyy HH:mm"
        let formattedDate = dateFormatter.string(from: date)
        return formattedDate
    }
    
    //used for setting the date for the datepicker
    private func formatDate(day:Int, month:Int, year:Int, hour:Int, minute:Int) -> Date {
        var dayStr = String(day)
        var monthStr = String(month)
        var hourStr = String(hour)
        var minuteStr = String(minute)
        if day < 10 {
            dayStr = "0\(day)"
        }
        if month < 10 {
            monthStr = "0\(month)"
        }
        if hour < 10 {
            hourStr = "0\(hour)"
        }
        if minute < 10 {
            minuteStr = "0\(minute)"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let date : Date = dateFormatter.date(from: "\(year)-\(monthStr)-\(dayStr) \(hourStr):\(minuteStr)")!

        return date
    }
    
    private func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?, sender: Any) {
        // Update View
        
        if let error = error {
            print("Unable to Forward Geocode Address (\(error))")
            
        } else {
            var location: CLLocation?
            
            if let placemarks = placemarks, placemarks.count > 0 {
                location = placemarks.first?.location
                
                var addressArr = placemarks.first!.addressDictionary!["FormattedAddressLines"] as! [String]
                print(addressArr)
                addressArr.removeLast()
                let address = addressArr.joined(separator: ", ")
                print(address)
                eventInfo[0] = address
                EventVariables.address = address
                
                let addressCell = eventDetailsTableView.cellForRow(at: IndexPath(row: 2, section: 0)) as! CustomEventDetailsCell
                addressCell.EventDataTextField.text = address
            }
            
            if let location = location {
                let coordinate = location.coordinate
                EventVariables.latitude = Double(coordinate.latitude)
                EventVariables.longitude = Double(coordinate.longitude)
            } else {
            }
        }
        
    }
    
    private func saveTextFieldInfo() {
        shouldChangeInfoText = false
        let addressCell:CustomEventDetailsCell = eventDetailsTableView.cellForRow(at: IndexPath(row: 2, section: 0)) as! CustomEventDetailsCell
        let descriptionCell:CustomEventDetailsCell = eventDetailsTableView.cellForRow(at: IndexPath(row: 3, section: 0)) as! CustomEventDetailsCell
        shouldChangeInfoText = true
        eventInfo[0] = addressCell.EventDataTextField.text!
        EventVariables.address = addressCell.EventDataTextField.text!
        eventInfo[1] = descriptionCell.EventDataTextField.text!
        EventVariables.description = descriptionCell.EventDataTextField.text!
    }
    
    private func loadCreatorProfilePic() {
            var profilePic:UIImage = #imageLiteral(resourceName: "DefaultProfileImg")
            let filePath = "Users/User: \(eventCreator!.userID)/profilePicture"
            self.storageRef.child(filePath).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
                if error == nil {
                    let userPhoto = UIImage(data: data!)
                    profilePic = userPhoto!
                }
                else {
                    print("ERROR: \(String(describing: error))")
                    profilePic = #imageLiteral(resourceName: "DefaultProfileImg")
                }
                
                let profilePicCell:CustomEventCreatorProfilePicCell = self.eventDetailsTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! CustomEventCreatorProfilePicCell
                profilePicCell.ProfilePicture.image = profilePic
        })
    }
    
    private func layoutProfilePic(with cell:CustomEventCreatorProfilePicCell) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: cell.ProfilePicture.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(ovalIn: cell.ProfilePicture.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        
        cell.ProfilePicture.layoutIfNeeded()
        cell.ProfilePicture.clipsToBounds = true
        cell.ProfilePicture.layer.masksToBounds = true
        cell.ProfilePicture.layer.cornerRadius = cell.ProfilePicture.bounds.size.width/2.0
        cell.ProfilePicture.layer.addSublayer(gradient)

    }
    
    private func createRSVPBox() {
        
        let boxWidth:CGFloat = 5 * view.frame.width / 6
        let boxHeight:CGFloat = (navigationController?.navigationBar.frame.height)!
        let xPos:CGFloat = view.frame.width/24
        let yPos:CGFloat = -boxHeight
        let boxFrame:CGRect = CGRect(x: xPos * 2, y: yPos, width: boxWidth, height: 3*boxHeight/2)
        let rsvpFrame:CGRect = CGRect(x: 0, y: 0, width: boxWidth, height: boxHeight)

        
        boxSubView.frame = boxFrame
        boxSubView.alpha = 0.95
        let arrowBoxWidth:CGFloat = boxWidth/4 - view.frame.width/24.0
        let arrowBoxHeight:CGFloat = boxHeight/2
        let arrowBoxX:CGFloat = boxFrame.width/2 - arrowBoxWidth/2
        let arrowBoxY:CGFloat = boxHeight
        let arrowBoxFrame:CGRect = CGRect(x: arrowBoxX, y: arrowBoxY, width: arrowBoxWidth, height: arrowBoxHeight)
        
        let arrowBox = UIView(frame: arrowBoxFrame)
        //extension at the bottom of this file
        arrowBox.roundCorners([.bottomLeft,.bottomRight], radius: 5)
        arrowBox.backgroundColor = UIColor.white
        arrowBox.alpha = 0.95
        
        let rsvpBox = UISegmentedControl(frame: rsvpFrame)
        rsvpBox.insertSegment(withTitle: "Going?", at: 0, animated: false)
        rsvpBox.insertSegment(withTitle: "Yes", at: 1, animated: false)
        rsvpBox.insertSegment(withTitle: "Maybe", at: 2, animated: false)
        rsvpBox.insertSegment(withTitle: "No", at: 3, animated: false)
        
        let shortSegmentWidth:CGFloat = boxWidth/4 - view.frame.width/24.0
        let longSegmentWidth:CGFloat = boxWidth/2 - view.frame.width/12.0
        
        rsvpBox.setWidth(longSegmentWidth, forSegmentAt: 0)
        rsvpBox.setWidth(shortSegmentWidth, forSegmentAt: 1)
        rsvpBox.setWidth(shortSegmentWidth, forSegmentAt: 2)
        rsvpBox.setWidth(shortSegmentWidth, forSegmentAt: 3)
        
        
        rsvpBox.setEnabled(false, forSegmentAt: 0)
        
        let defaultColor:UIColor = UIColor.white
        rsvpBox.backgroundColor = defaultColor
        rsvpBox.alpha = 0.95
        rsvpBox.tintColor = UIColor.black
        
        rsvpBox.setSegmentStyle(colors: segmentColors)
        
        if let rsvpCode = getCurrentRSVP() {
            switch rsvpCode {
            case 0:
                rsvpBox.selectedSegmentIndex = 1
                selectedSegment(sender: rsvpBox)
            case 1:
                rsvpBox.selectedSegmentIndex = 2
                selectedSegment(sender: rsvpBox)
            case 2:
                rsvpBox.selectedSegmentIndex = 3
                selectedSegment(sender: rsvpBox)
                print("IT SHOULD'VE WORKED")
            default:
                break
            }
        }
        
        for subview in rsvpBox.subviews[0].subviews {
            if let label = subview as? UILabel {
                label.textColor = UIColor.black
            }
        }
        
        rsvpBox.addTarget(self, action: #selector(selectedSegment), for: .valueChanged)
        
        view.addSubview(boxSubView)
        boxSubView.addSubview(rsvpBox)
        boxSubView.addSubview(arrowBox)
        view.bringSubview(toFront: boxSubView)
        boxSubView.bringSubview(toFront: arrowBox)
        addThreeLines(to: arrowBox)
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(EventDetailsVC.handleTap(gestureRecognizer:)))
        tapGesture.delegate = self
        arrowBox.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(EventDetailsVC.handlePan(gestureRecognizer:)))
        panGesture.delegate = self
        arrowBox.addGestureRecognizer(panGesture)
        
        handleTap(gestureRecognizer: nil)
        
    }
    
    private func getCurrentRSVP() -> Int? {
        if let invitedEvents = currentUser?.invitedEvents {
            for (event,rsvp) in invitedEvents {
                if event == EventVariables.eventID {
                    print("IT WORKED \(rsvp)")
                    return rsvp
                }
            }
        }
        
        return nil
    }
    
    private func updateUserRSVP(with code:Int) {
        let invitedEventsRef = userRef.child("User: \(currentUser!.userID)").child("invitedEvents").child(EventVariables.eventID)
        invitedEventsRef.setValue(code)
        for (event,_) in currentUser!.invitedEvents {
            if event == EventVariables.eventID {
                currentUser?.invitedEvents[event] = code
            }
        }
        
        if let invitedEvents = UserData.invitedEvents {
            for (event,_) in invitedEvents {
                if event == EventVariables.eventID {
                    UserData.invitedEvents![event] = code
                }
            }
        }
        
    }
    
    private func addThreeLines(to view: UIView) {
        let size = CGSize(width: 40, height: 1)
        let xPos:CGFloat = view.frame.width / 2 - size.width/2
        let const:CGFloat = 1/14.0 * view.frame.height

        let pos1 = CGPoint(x: xPos, y: const * 5)
        let pos2 = CGPoint(x: xPos, y: const * 7)
        let pos3 = CGPoint(x: xPos, y: const * 9)

        let line1 = UIView(frame: CGRect(origin: pos1, size: size))
        let line2 = UIView(frame: CGRect(origin: pos2, size: size))
        let line3 = UIView(frame: CGRect(origin: pos3, size: size))
        
        line1.backgroundColor = UIColor.lightGray
        line2.backgroundColor = UIColor.lightGray
        line3.backgroundColor = UIColor.lightGray

        view.addSubview(line1)
        view.addSubview(line2)
        view.addSubview(line3)

    }
    
    // MARK: Action for UISegmentedControl
    @objc private func selectedSegment(sender:UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            break
        case 1:
            sender.setSegmentStyle(colors: segmentColors)
            updateUserRSVP(with: 0)
        case 2:
            sender.setSegmentStyle(colors: segmentColors)
            updateUserRSVP(with: 1)
        case 3:
            sender.setSegmentStyle(colors: segmentColors)
            updateUserRSVP(with: 2)
        default:
            break
        }
    }
    
    // MARK: - Gesture Recognizers
    @objc private func handleTap(gestureRecognizer: UITapGestureRecognizer?) {
        let frame = boxSubView.frame
        if frame.minY < 0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.boxSubView.frame = CGRect(x: frame.minX, y: 0, width: frame.width, height: frame.height)
            })
            
        }
        else {
            UIView.animate(withDuration: 0.5, animations: {
                self.boxSubView.frame = CGRect(x: frame.minX, y: -(self.navigationController?.navigationBar.frame.height)!, width: frame.width, height: frame.height)
            })
        }
    }
    
    @objc private func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            initialYPos = boxSubView.frame.minY
        }
        
        if gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: boxSubView)
            //below line sets limit to how far down the view will go
            if translation.y >= 0 && boxSubView.frame.minY <= 0 {
                prevTranslation = CGPoint(x: 0, y: translation.y - prevTranslation.y)
                boxSubView.center = CGPoint(x: boxSubView.center.x, y: boxSubView.center.y + prevTranslation.y)
                prevTranslation = translation
            }
            
            else if translation.y < 44 && boxSubView.frame.minY >= -(self.navigationController?.navigationBar.frame.height)! {
                prevTranslation = CGPoint(x: 0, y: translation.y - prevTranslation.y)
                boxSubView.center = CGPoint(x: boxSubView.center.x, y: boxSubView.center.y + prevTranslation.y)
                prevTranslation = translation
            }
            else if boxSubView.frame.minY >= 0{
                prevTranslation = translation
            }
            
        }
        
        if gestureRecognizer.state == .ended {
            prevTranslation = CGPoint.zero
            let frame: CGRect = boxSubView.frame
            if gestureRecognizer.translation(in: boxSubView).y > 0 {
                UIView.animate(withDuration: 0.5, animations: {
                    self.boxSubView.frame = CGRect(x: frame.minX, y: 0, width: frame.width, height: frame.height)
                })
                
            }
            else {
                UIView.animate(withDuration: 0.5, animations: {
                    self.boxSubView.frame = CGRect(x: frame.minX, y: -(self.navigationController?.navigationBar.frame.height)!, width: frame.width, height: frame.height)
                })
            }
        }
    }
    // MARK: - Segue method
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            invitedFriendsUsernames = []
        if segue.identifier == "invited friends" {
        
            let nextController = (segue.destination as! EventFriendListVC)
            nextController.editable = currentUser!.userID == EventVariables.createdByUID
            nextController.invitedFriendsUIDs = EventVariables.invitedFriends
            nextController.currentUser = currentUser
            nextController.cameFromEventDetailsVC = true
            
            

            for uid in EventVariables.invitedFriends {
                let userRef = self.userRef.child("User: \(uid)")
                userRef.observe(.value, with: { (snapshot) in
                    let user = User(snapshot: snapshot)
                    self.invitedFriendsUsernames.append(user.username)
                    nextController.invitedFriendsUsernames = self.invitedFriendsUsernames
                })
            }
        }
        if segue.identifier == "AddFriends" {
            let nextController = (segue.destination as! AddFriendsToEventVC)
            nextController.addedFriends = EventVariables.invitedFriends
            nextController.eventDetailsWasPrevVC = true
            let event = Event(description: EventVariables.description, day: String(EventVariables.dateDay), month: String(EventVariables.dateMonth), year: String(EventVariables.dateYear), hour: String(EventVariables.timeHr), minute: String(EventVariables.timeMin), address: EventVariables.address, latitude: EventVariables.latitude, longitude: EventVariables.longitude, eventID: 0, isPublic: EventVariables.isPublic, invitedFriends: EventVariables.invitedFriends, createdByUID: EventVariables.createdByUID)
            nextController.event = event
            nextController.eventID = EventVariables.eventID
        }
    }
}
// MARK: - Custom tableview cells
class CustomEventCreatorProfilePicCell: UITableViewCell {
    
    @IBOutlet weak var ProfilePicture: UIImageView!
    override func layoutSubviews() {
        super.layoutSubviews()
        let tableView:UITableView = superview?.superview as! UITableView
        let xPos: CGFloat = tableView.frame.width/2 - ProfilePicture.frame.width/2
        let yPos: CGFloat = self.frame.height/8
        
        ProfilePicture.frame = CGRect(x: xPos, y: yPos, width: ProfilePicture.frame.width, height: ProfilePicture.frame.height)
        
        
    }
    
}

class CustomEventDetailsCell: UITableViewCell {
    @IBOutlet weak var EventDataTextField: UITextField!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //self.textLabel?.frame = textFrame
        self.textLabel?.sizeToFit()
        var textFrame:CGRect = (self.textLabel?.frame)!
        textFrame = CGRect(x: 12, y: 12, width: textFrame.width, height: textFrame.height)
        self.textLabel?.frame = textFrame

        let frame:CGRect = self.EventDataTextField.frame
        let offset:CGFloat = 12
        let newWidth: CGFloat = self.contentView.frame.width - (textFrame.width + 4 * offset)
        let newFrame = CGRect(x: textFrame.maxX + 2 * offset, y: frame.minY, width: newWidth, height: frame.height)
        EventDataTextField.frame = newFrame
    }
}

class CustomDateTimeDetailsCell: UITableViewCell {
    @IBOutlet weak var showDatePickerBtn: UIButton!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let tableView:UITableView = superview?.superview as! UITableView
        let offset:CGFloat = 12
        let xPos:CGFloat = tableView.frame.width - offset - showDatePickerBtn.frame.width
        
        showDatePickerBtn.frame = CGRect(x: xPos, y: showDatePickerBtn.frame.minY, width: showDatePickerBtn.frame.width, height: showDatePickerBtn.frame.height)
        showDatePickerBtn.titleLabel?.textAlignment = .right
    }
}

class CustomPublicPrivateCell: UITableViewCell {
    @IBOutlet weak var publicPrivateSwitch: UISwitch!
    @IBAction func changePublicPrivate(_ sender: Any) {
        EventVariables.isPublic = !publicPrivateSwitch.isOn
        //first superview is a tableviewwrapper class
        let tableView:UITableView = superview?.superview as! UITableView
        tableView.reloadData()
        EventVariables.updateEventWithCurrentVariables()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let tableView:UITableView = superview?.superview as! UITableView
        let offset:CGFloat = 12
        let xPos:CGFloat = tableView.frame.width - offset - publicPrivateSwitch.frame.width
        publicPrivateSwitch.frame = CGRect(x: xPos, y: publicPrivateSwitch.frame.minY, width: publicPrivateSwitch.frame.width, height: publicPrivateSwitch.frame.height)
    }
    
}
// MARK: - Misc
class CustomDatePickerView: UIView {
    
}

//changes text size of placeholder text if it is too long
class AutoSizeTextField: UITextField {
    
    override func layoutSubviews(){
        super.layoutSubviews()
        //print("SUBVIEWS:\n\(self.subviews)\n")
        for subView in self.subviews {
            if let label = subView as? UILabel {
                label.minimumScaleFactor = 0.3
                label.adjustsFontSizeToFitWidth = true
                label.textAlignment = .right
            }
        }
    }
}

extension UINavigationItem {
    
    func setTitle(title:String, subtitle:String) {
        
        let one = UILabel()
        one.text = title
        one.font = UIFont.boldSystemFont(ofSize: 17)
        one.sizeToFit()
        
        let two = UILabel()
        two.text = subtitle
        two.font = UIFont.systemFont(ofSize: 15)
        two.textAlignment = .center
        two.sizeToFit()
        
        
        
        let stackView = UIStackView(arrangedSubviews: [one, two])
        stackView.distribution = .equalCentering
        stackView.axis = .vertical
        
        let width = max(one.frame.size.width, two.frame.size.width)
        stackView.frame = CGRect(x: 0, y: 0, width: width, height: 35)
        stackView.alignment = .center
        
        one.sizeToFit()
        two.sizeToFit()
        
        
        self.titleView = stackView
    }
}

extension UISegmentedControl {
    
    func setSegmentStyle(colors:[UIColor]) {
        
        let segmentGrayColor = UIColor(red: 0.889415, green: 0.889436, blue:0.889424, alpha: 1.0 )
        setBackgroundImage(imageWithColor(color: backgroundColor!), for: .normal, barMetrics: .default)
        setDividerImage(imageWithColor(color: segmentGrayColor), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        
        if selectedSegmentIndex > 0 {
            print("HELP \(selectedSegmentIndex)")
            setBackgroundImage(imageWithColor(color: colors[selectedSegmentIndex]), for: .selected, barMetrics: .default)
        }
        else {
            setBackgroundImage(imageWithColor(color: colors[0]), for: .selected, barMetrics: .default)

        }
        
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 5.0
        self.layer.borderColor = segmentGrayColor.cgColor
        self.layer.masksToBounds = true
    
    }
    
    // create a 1x1 image with this color
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width:  1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor);
        context!.fill(rect);
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!
    }
    
}


extension UIView {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}
