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
        if editIsSelected { //edit is tapped
            DeleteButton.isHidden = false
            SelectAllButton.isHidden = false
            EditButtonLbl.setTitle("Done", for: .normal)
            editInvitedFriendsTableView.setEditing(true, animated: true)
        }
        else { //done is tapped
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
        DeleteButton.isHidden = true
        SelectAllButton.isHidden = true
        EditButtonLbl.isHidden = !editable!
        navigationController?.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invitedFriendsUsernames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventFriendCell", for: indexPath) as! CustomEventFriendListCell
        
        layoutProfilePics(with: cell)
        
        if indexPath.row < profilePicArray.count {
            cell.ProfileImg.image = profilePicArray[indexPath.row]
        }
        else {
            cell.ProfileImg.image = #imageLiteral(resourceName: "DefaultProfileImg")
        }
        cell.UsernameLbl.text = invitedFriendsUsernames[indexPath.row]
        if editIsSelected {
            cell.selectionStyle = UITableViewCellSelectionStyle.init(rawValue: 3)!
        }
        else {
            cell.selectionStyle = UITableViewCellSelectionStyle.none
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
                    print("ERROR: \(String(describing: error))")
                    profilePic = #imageLiteral(resourceName: "DefaultProfileImg")
                }
                
                self.profilePicArray[index] = profilePic
                self.editInvitedFriendsTableView.reloadData()
            })
        }
        
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

class CustomEventFriendListCell: UITableViewCell {
    @IBOutlet weak var ProfileImg: UIImageView!
    @IBOutlet weak var UsernameLbl: UILabel!
    
    
}
