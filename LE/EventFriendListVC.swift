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
}

class EventFriendListVC: UITableViewController, UINavigationControllerDelegate {
    
    let storageRef = FIRStorage.storage().reference()

    //Passed values from previous VC
    var invitedFriendsUIDs:[String] = []
    var invitedFriendsUsernames:[String] = []
    var currentUser:User? = nil

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
        selectedCellsIndex = selectedCellsIndex.sorted(by: >)
        for index in selectedCellsIndex {
            print("index: \(index)\ninvitedFriendsUIDs: \(invitedFriendsUsernames)")
            invitedFriendsUIDs.remove(at: index)
            invitedFriendsUsernames.remove(at: index)
        }
        if (invitedFriendsUIDs == []) {
            EditButtonLbl.sendActions(for: .touchUpInside)
        }
        DeleteButton.setTitleColor(UIColor.lightGray, for: .normal)
        InvitedFriends.invitedFriendsUIDs = invitedFriendsUIDs
        InvitedFriends.invitedFriendsUsernames = invitedFriendsUsernames
        editInvitedFriendsTableView.reloadData()
        selectedCellsIndex = []
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
        navigationController?.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invitedFriendsUsernames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventFriendCell", for: indexPath) as! CustomEventFriendListCell
        cell.ProfileImg.layoutIfNeeded()
        cell.ProfileImg.clipsToBounds = true
        cell.ProfileImg.layer.cornerRadius = cell.ProfileImg.bounds.size.width/2.0
        cell.ProfileImg.image = profilePicArray[indexPath.row]
        cell.UsernameLbl.text = invitedFriendsUsernames[indexPath.row]
        if editIsSelected {
            cell.selectionStyle = UITableViewCellSelectionStyle.init(rawValue: 3)!
        }
        else {
            cell.selectionStyle = UITableViewCellSelectionStyle.none
        }
        cell.tintColor = UIColor.blue
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
}

class CustomEventFriendListCell: UITableViewCell {
    @IBOutlet weak var ProfileImg: UIImageView!
    @IBOutlet weak var UsernameLbl: UILabel!
    
    
}
