//
//  EventFriendListVC.swift
//  LE
//
//  Created by Rahil Patel on 5/29/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

struct InvitedFriends {
    static var invitedFriendsUIDs: [String] = []
    static var invitedFriendsUsernames: [String] = []
    
    static func reset() {
        invitedFriendsUIDs = []
        invitedFriendsUsernames = []
    }
}

class EventFriendListVC: UITableViewController, UINavigationControllerDelegate {
    
    let storageRef = FIRStorage.storage().reference()
    let eventRef = FIRDatabase.database().reference(withPath: "Events")

    //Passed values from previous VC
    var invitedFriendsUIDs:[String] = []
    var invitedFriendsUsernames:[String] = []
    var currentUser:User? = nil
    var editable:Bool? = nil
    var cameFromEventDetailsVC = false

    //Not passed values from previous VC
    var selectedCellsIndex:[Int] = []
    var editIsSelected:Bool = false
    var profilePicArray = [UIImage]()
    var rsvpStatusArray = [String:Int]()
    
    @IBOutlet weak var SelectAllButton: UIButton!
    @IBOutlet weak var DeleteButton: UIButton!
    @IBOutlet weak var EditButtonLbl: UIButton!
    @IBOutlet var editInvitedFriendsTableView: UITableView!
    
    @IBAction func SelectAllInvitedFriends(_ sender: Any) {
        if invitedFriendsUIDs != [] {
        DeleteButton.setTitleColor(UIColor.init(red:14.0/255, green:122.0/255, blue:254.0/255, alpha: 1), for: .normal)
        }
        selectedCellsIndex = []
        let numOfRows = editInvitedFriendsTableView.numberOfRows(inSection: 0)
        for i in 0..<numOfRows {
        editInvitedFriendsTableView.selectRow(at: IndexPath(row:i, section:0), animated: true, scrollPosition: .none)
        selectedCellsIndex.append(i)
        }
    }
    @IBAction func DeleteFriends(_ sender: Any) {
        print("{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}")
        selectedCellsIndex = selectedCellsIndex.sorted(by: >)
        for index in selectedCellsIndex {
            print("index: \(index)\ninvitedFriendsUIDs: \(invitedFriendsUsernames)")
            invitedFriendsUIDs.remove(at: index)
            invitedFriendsUsernames.remove(at: index)
            profilePicArray.remove(at: index)
        }
        
        if (invitedFriendsUIDs == []) {
            EditButtonLbl.sendActions(for: .touchUpInside)
        }
        
        DeleteButton.setTitleColor(UIColor.lightGray, for: .normal)
        InvitedFriends.invitedFriendsUIDs = invitedFriendsUIDs
        InvitedFriends.invitedFriendsUsernames = invitedFriendsUsernames
        editInvitedFriendsTableView.reloadData()
        
        selectedCellsIndex = []
        
        if cameFromEventDetailsVC {
            
            EventVariables.invitedFriends = invitedFriendsUIDs
            /*
            eventsRef.observeSingleEvent(of: .value, with: { (snapshot) in
                print("VALUE \n\(snapshot.value)")
                var event = Event(snapshot: snapshot)
                
                //the line below is somehow calling the "Event Details" segue from map view controller to event details VC and in the process calling the corresponding code in MapViewController's prepare(for segue:)
                //event.invitedFriends = self.invitedFriendsUIDs
                //eventsRef.setValue(event.toAnyObject())

                let invFriendsRef = eventsRef.child("invitedFriends")
                let invitedFriendsStringRep = self.invitedFriendsUIDs.joined(separator: ",")
                invFriendsRef.setValue(invitedFriendsStringRep)
                
            })
            */
            
            
            let invFriendsRef = self.eventRef.child(EventVariables.eventID).child("invitedFriends")
            let invitedFriendsStringRep = self.invitedFriendsUIDs.joined(separator: ",")
            invFriendsRef.setValue(invitedFriendsStringRep)
            
            //eventRef.setValue(invitedFriendsUIDs, forKey: "invitedFriends")
        }
 
    }
    @IBAction func EditButton(_ sender: Any) {
        editIsSelected = !editIsSelected
        selectedCellsIndex = []
        DeleteButton.setTitleColor(UIColor.lightGray, for: .normal)
        if editIsSelected { //the word edit is tapped
            DeleteButton.isHidden = false
            SelectAllButton.isHidden = false
            EditButtonLbl.setTitle("Done", for: .normal)
            editInvitedFriendsTableView.setEditing(true, animated: true)
        }
        else { //the word done is tapped
            DeleteButton.isHidden = true
            SelectAllButton.isHidden = true
            EditButtonLbl.setTitle("Edit", for: .normal)
            editInvitedFriendsTableView.setEditing(false, animated: true)
        }
        editInvitedFriendsTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProfilePictures()
        
        if cameFromEventDetailsVC {
            determineRSVPStatus()
        }
        
        DeleteButton.isHidden = true
        SelectAllButton.isHidden = true
        EditButtonLbl.isHidden = !editable!
        navigationController?.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //updating the current user's data before tableview is set up
        if !ProfileInfo.isVisible {
            self.navigationController?.navigationBar.isUserInteractionEnabled = true
        }
        currentUser = User(data: UserData())
        return invitedFriendsUsernames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventFriendCell", for: indexPath) as! CustomEventFriendListCell
                
        if indexPath.row < profilePicArray.count {
            cell.ProfileImg.image = profilePicArray[indexPath.row]
        }
        else {
            cell.ProfileImg.image = #imageLiteral(resourceName: "DefaultProfileImg")
        }
        
        if invitedFriendsUsernames[indexPath.row] == currentUser?.username {
            cell.UsernameLbl.text = "You"
            cell.UsernameLbl.font = UIFont.boldSystemFont(ofSize: cell.UsernameLbl.font.pointSize)
        }
        else {
            cell.UsernameLbl.text = invitedFriendsUsernames[indexPath.row]
        }
        
        if editIsSelected {
            cell.selectionStyle = UITableViewCellSelectionStyle.init(rawValue: 3)!
            //cell.removeGestureRecognizer(tapGesture)
        }
        else {
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
            cell.tag = indexPath.row
            cell.addGestureRecognizer(tapGesture)
        }
        
        if cameFromEventDetailsVC {
            for (userID, status) in rsvpStatusArray {
                if userID == invitedFriendsUIDs[indexPath.row] {
                    switch status {
                    case 0:
                        cell.rsvpStatusLabel.text = "Going"
                        cell.rsvpStatusLabel.textColor = Colors.eucalyptus
                    case 1:
                        cell.rsvpStatusLabel.text = "Maybe"
                        cell.rsvpStatusLabel.textColor = Colors.royalBlue
                    case 2:
                        cell.rsvpStatusLabel.text = "Not Going"
                        cell.rsvpStatusLabel.textColor = Colors.cinnabar
                    case 3:
                        cell.rsvpStatusLabel.text = "Undecided"
                        cell.rsvpStatusLabel.textColor = Colors.lightGray
                    default:
                        break
                    }
                }
            }
        }
        
        cell.tintColor = Colors.blueGreen
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DeleteButton.setTitleColor(UIColor.init(red:14.0/255, green:122.0/255, blue:254.0/255, alpha: 1), for: .normal)
        selectedCellsIndex.append(indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        for (index, element) in selectedCellsIndex.enumerated() {
            if element == indexPath.row {
                selectedCellsIndex.remove(at: index)
            }
        }
        if selectedCellsIndex == [] {
            DeleteButton.setTitleColor(UIColor.gray, for: .normal)
        }
        print(selectedCellsIndex)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle(rawValue: 3)!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let nextController = (segue.destination as! AddEventController)
        print(invitedFriendsUsernames)
        nextController.invitedFriendsUIDs = invitedFriendsUIDs
        nextController.invitedFriendsUsernames = invitedFriendsUsernames
    }
    
    func loadProfilePictures() {
        for _ in invitedFriendsUIDs {
            profilePicArray.append(#imageLiteral(resourceName: "DefaultProfileImg"))
        }
        
        for (index,id) in invitedFriendsUIDs.enumerated() {
            var profilePic:UIImage = #imageLiteral(resourceName: "DefaultProfileImg")
            //let photoIndex = index
            let filePath = "Users/User: \(id)/\("profilePicture")"
            self.storageRef.child(filePath).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
                if error == nil {
                    let userPhoto = UIImage(data: data!)
                    profilePic = userPhoto!
                }
                else {
                    profilePic = #imageLiteral(resourceName: "DefaultProfileImg")
                }
                
                self.profilePicArray[index] = profilePic
                self.editInvitedFriendsTableView.reloadData()
            })
        }
        
    }
    
    private func determineRSVPStatus() {
        for userID in invitedFriendsUIDs {
            //default value
            rsvpStatusArray[userID] = 3
            
            let userRef = FIRDatabase.database().reference(withPath: "Users")
            let invitedEventRef = userRef.child("User: \(userID)").child("invitedEvents").child(EventVariables.eventID)
            invitedEventRef.observe(.value, with: { (snapshot) in
                
                self.rsvpStatusArray[userID] = snapshot.value as? Int
                self.editInvitedFriendsTableView.reloadData()
            })
        }
    }
    
    @objc private func cellTapped(_ sender: UITapGestureRecognizer) {
        
        print("CELL TAPPED")
        let tapLocation = sender.location(in: self.editInvitedFriendsTableView)
        let indexPath = editInvitedFriendsTableView.indexPathForRow(at: tapLocation)
        let cell = editInvitedFriendsTableView.cellForRow(at: indexPath!)
        let uid = invitedFriendsUIDs[cell!.tag]
        let profilePic = profilePicArray[cell!.tag]
        
        ProfileInfo.presentOnTableView(tableView: self.editInvitedFriendsTableView, userID: uid, superViewFrame: self.view.frame, currentUser: self.currentUser!, profilePic: profilePic)
        self.navigationController?.navigationBar.isUserInteractionEnabled = false
        
    }
    
}

class CustomEventFriendListCell: UITableViewCell {
    @IBOutlet weak var ProfileImg: UIImageView!
    @IBOutlet weak var UsernameLbl: UILabel!
    @IBOutlet weak var rsvpStatusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layoutProfilePics(with: self)
    }
    
    private func layoutProfilePics(with cell:CustomEventFriendListCell) {
        
        let gradient = CAGradientLayer()
        gradient.frame =  CGRect(origin: CGPoint.zero, size: cell.ProfileImg.frame.size)
        gradient.colors = [Colors.blueGreen.cgColor, Colors.yellow.cgColor]
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(ovalIn: cell.ProfileImg.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        
        cell.ProfileImg.layoutIfNeeded()
        cell.ProfileImg.clipsToBounds = true
        cell.ProfileImg.layer.masksToBounds = true
        cell.ProfileImg.layer.cornerRadius = cell.ProfileImg.bounds.size.width/2.0
        cell.ProfileImg.layer.addSublayer(gradient)
        
    }
}
