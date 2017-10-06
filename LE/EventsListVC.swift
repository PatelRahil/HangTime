//
//  EventsListVC.swift
//  LE
//
//  Created by Rahil Patel on 7/17/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class EventsListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var currentUser:User? = nil
    
    let sectionTitleArray:[String] = ["Your Created Events", "Events You're Invited To"]
    var invitedEvents:[Event] = [Event]()
    var createdEvents:[Event] = [Event]()
    var eventCreatorProfilePics:[String:UIImage] = [String:UIImage]()
    var eventCreatorUsernames:[String:String] = [String:String]()
    var invitedEventIDs:[String] = [String]()
    
    @IBOutlet weak var eventsListTableView: UITableView!
    @IBOutlet weak var OpenSideBar: UIButton!
    
    override func viewDidLoad() {
        print(UserData.createdEvents)
        currentUser = User.init(data: UserData())
        print(currentUser?.createdEvents)
        self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)

        //makes sure the events list contains an updated list, in case an event is deleted before UserData has a chance to update
        currentUser?.updateUserFromDatabase(completionHandler: {
            self.setupArrays()
            self.downloadCreatedEvents()
            self.downloadInvitedEvents()
            
            self.eventsListTableView.delegate = self
            self.eventsListTableView.dataSource = self
            self.eventsListTableView.separatorColor = Colors.blueGreen
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let indexPaths = eventsListTableView.indexPathsForSelectedRows {
            for indexPath in indexPaths {
                eventsListTableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }
    
    private func setupArrays() {
        if let invitedEventIDs = currentUser?.invitedEvents {
            var count:Int = 0
            for (key,_) in invitedEventIDs {
                let tempEvent = Event(description: "loading...", day: "01", month: "01", year: "2017", hour: "00", minute: "00", address: "loading", latitude: 0, longitude: 0, eventID: 0, isPublic: true, invitedFriends: [String](), createdByUID: "\(count)")
                
                invitedEvents.append(tempEvent)
                eventCreatorProfilePics[tempEvent.createdByUID] = #imageLiteral(resourceName: "DefaultProfileImg")
                eventCreatorUsernames[tempEvent.createdByUID] = "loading..."
                
                self.invitedEventIDs.append("")
                count += 1
            }
        }
        for _ in currentUser!.createdEvents {
            let tempEvent = Event(description: "loading...", day: "01", month: "01", year: "2017", hour: "00", minute: "00", address: "loading", latitude: 0, longitude: 0, eventID: 0, isPublic: true, invitedFriends: [String](), createdByUID: "")
            createdEvents.append(tempEvent)
        }
    }
    
    private func downloadInvitedEvents() {
        var count = 0
        if let invitedEvents = currentUser?.invitedEvents {
            for (id,_) in invitedEvents {
                let eventRef = FIRDatabase.database().reference(withPath: "Events").child(id)
                eventRef.observe(.value, with: { [preCount = count] (snapshot) in
                    if snapshot.exists() {
                        let event = Event(snapshot: snapshot)
                        self.determineUsername(of: event.createdByUID, count: preCount)
                        self.downloadPhoto(of: event.createdByUID, count: preCount)
                        self.invitedEvents[preCount] = event
                
                        self.eventsListTableView.reloadData()
                        //to imporove performace, only reload the row that contain's this event's information
                        //self.eventsListTableView.reloadRows(at: [IndexPath.init(row: preCount, section: 1)], with: .fade)
                    }
                    else {
                        print(id)
                    }
                })
                self.invitedEventIDs[count] = id
                count += 1
            }
        }
    }
    
    private func downloadCreatedEvents() {
        var count = 0
        for id in currentUser!.createdEvents {
            let eventRef = FIRDatabase.database().reference(withPath: "Events").child(id)
            eventRef.observe(.value, with: { [preCount = count] (snapshot) in
                print(snapshot.value)
                if snapshot.exists() {
                    let event = Event(snapshot: snapshot)
                    self.createdEvents[preCount] = event
                
                    self.eventsListTableView.reloadData()
                //to improve performace, only reload the row that contain's this event's information
                    //self.eventsListTableView.reloadRows(at: [IndexPath.init(row: preCount, section: 0)], with: .fade)
                }
                else {
                    print(id)
                }
            })
            count += 1
        }
    }
    
    private func determineUsername(of id:String, count:Int) {
        let userRef = FIRDatabase.database().reference(withPath: "Users").child("User: \(id)").child("username")
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let username:String = snapshot.value as! String
            self.eventCreatorUsernames[id] = username
            //self.eventsListTableView.reloadData()
            //to improve performace, only reload the row that contain's this event's information
            self.eventsListTableView.reloadRows(at: [IndexPath.init(row: count, section: 1)], with: .fade)
        })
    }
    
    private func downloadPhoto(of id:String, count:Int) {
        let userStorageRef = FIRStorage.storage().reference(withPath: "Users").child("User: \(id)").child("profilePicture")
        userStorageRef.data(withMaxSize: 10*1024*1024) { (data, error) in
            if error == nil {
                let profilePic = UIImage(data: data!)
                self.eventCreatorProfilePics[id] = profilePic
                //self.eventsListTableView.reloadData()
                //to improve performace, only reload the row that contain's this event's information
                self.eventsListTableView.reloadRows(at: [IndexPath.init(row: count, section: 1)], with: .fade)
            }
        }
    }
    
    func formatDate(day:Int, month:Int, year:Int, hour:Int, minute:Int) -> String {
        var dayStr = String(day)
        var monthStr = String(month)
        var hourStr = String(hour)
        var minuteStr = String(minute)
        var yearStr = String(year)
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
        let date : Date = dateFormatter.date(from: "\(yearStr)-\(monthStr)-\(dayStr) \(hourStr):\(minuteStr)")!
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        //dateFormatter.dateFormat = "MMM dd, yyyy HH:mm"
        let formattedDate = dateFormatter.string(from: date)
        return formattedDate
    }
}

// MARK: - TableView functions extension
extension EventsListVC {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if currentUser!.createdEvents.count == 0 {
                return 1
            }
            else {
                return currentUser!.createdEvents.count
            }
        case 1:
            if let invitedEvents = currentUser?.invitedEvents {
                if invitedEvents.count == 0 {
                    return 1
                }
                else {
                    return invitedEvents.count
                }
            }
            else {
                return 1
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(indexPath)
        switch indexPath.section {
        case 0:
            //configure cell
            if currentUser!.createdEvents.count == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EmptySectionCell")!
                cell.textLabel?.text = "You haven't created any events yet."
                cell.textLabel?.textColor = UIColor.lightGray
                cell.isUserInteractionEnabled = false
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CreatedEvents") as! CustomCreatedEventsCell
                cell.isUserInteractionEnabled = true
                let event = createdEvents[indexPath.row]
                let publicPrivate:String = event.isPublic ? "Public":"Private"
                let description = "\"\(event.description)\""
                print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
                print(event.day)
                print(Int(event.day))
                let dateString = formatDate(day: Int(event.day)!, month: Int(event.month)!, year: Int(event.year)!, hour: Int(event.hour)!, minute: Int(event.minute)!)
                
                cell.publicPrivateDateTimeLbl.text = "\(publicPrivate) Event on \(dateString)"
                cell.publicPrivateDateTimeLbl.adjustsFontSizeToFitWidth = true
                cell.descriptionLbl.text = description
                cell.descriptionLbl.adjustsFontSizeToFitWidth = true
                
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        case 1:
            //configure cell
            if currentUser!.invitedEvents.count == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EmptySectionCell")!
                cell.textLabel?.text = "You haven't been invited to any events yet."
                cell.textLabel?.textColor = UIColor.lightGray
                cell.isUserInteractionEnabled = false
                
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "InvitedEvents") as! CustomInvitedEventsCell
                cell.isUserInteractionEnabled = true
                let event = invitedEvents[indexPath.row]
                let eventCreatorPic = eventCreatorProfilePics[event.createdByUID]
                let eventCreatorUsername = eventCreatorUsernames[event.createdByUID]
                let dateString = formatDate(day: Int(event.day)!, month: Int(event.month)!, year: Int(event.year)!, hour: Int(event.hour)!, minute: Int(event.minute)!)
                
                cell.eventCreatorLbl.text = eventCreatorUsername
                cell.eventCreatorLbl.adjustsFontSizeToFitWidth = true
                cell.eventCreatorProfilePic.image = eventCreatorPic
                cell.eventDescriptionLbl.text = event.description
                cell.eventDescriptionLbl.adjustsFontSizeToFitWidth = true
                cell.eventDateTimeLbl.text = dateString
                cell.eventDateTimeLbl.adjustsFontSizeToFitWidth = true
                
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let event:Event = indexPath.section == 0 ? createdEvents[indexPath.row] : invitedEvents[indexPath.row]
        var eventID:String = ""
        if indexPath.section == 0 && !currentUser!.createdEvents.isEmpty {
            eventID = currentUser!.createdEvents[indexPath.row]
        }
        else if indexPath.section == 1 {
            eventID = invitedEventIDs[indexPath.row]
        }
        eventID = indexPath.section == 0 ? currentUser!.createdEvents[indexPath.row] : invitedEventIDs[indexPath.row]
        
        //if eventID is an empty string, don't do anything because there are no events
        if eventID != "" {
            let destinationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EventDetails") as! EventDetailsVC
            
        
            EventVariables.address = event.address
            EventVariables.dateDay = Int(event.day)!
            EventVariables.dateMonth = Int(event.month)!
            EventVariables.dateYear = Int(event.year)!
            EventVariables.description = event.description
            EventVariables.latitude = event.latitude
            EventVariables.longitude = event.longitude
            EventVariables.timeHr = Int(event.hour)!
            EventVariables.timeMin = Int(event.minute)!
            EventVariables.eventID = eventID
            EventVariables.createdByUID = event.createdByUID
            EventVariables.invitedFriends = event.invitedFriends
            EventVariables.isPublic = event.isPublic
            
            self.navigationController?.pushViewController(destinationVC, animated: true)
            
            let userRef = FIRDatabase.database().reference(withPath: "Users/User: \(event.createdByUID)")
            userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                destinationVC.eventCreator = User(snapshot: snapshot)
                destinationVC.setTitle()
            })
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitleArray[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
}


// MARK: - Custom UITableViewClasses
class CustomInvitedEventsCell: UITableViewCell {
    @IBOutlet weak var eventCreatorLbl: UILabel!
    @IBOutlet weak var eventDescriptionLbl: UILabel!
    @IBOutlet weak var eventDateTimeLbl: UILabel!
    @IBOutlet weak var eventCreatorProfilePic: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layoutProfilePics(with: self)
    }
    
    private func layoutProfilePics(with cell: CustomInvitedEventsCell) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: cell.eventCreatorProfilePic.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(ovalIn: cell.eventCreatorProfilePic.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor // causing lag when scrolling
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        
        
        
        cell.eventCreatorProfilePic.layoutIfNeeded()
        cell.eventCreatorProfilePic.clipsToBounds = true
        cell.eventCreatorProfilePic.layer.masksToBounds = true
        cell.eventCreatorProfilePic.layer.cornerRadius = cell.eventCreatorProfilePic.bounds.size.width/2.0
        cell.eventCreatorProfilePic.layer.addSublayer(gradient)
    }
}

class CustomCreatedEventsCell: UITableViewCell {
    @IBOutlet weak var publicPrivateDateTimeLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
}


class ProfileView: UIView {
    
}
