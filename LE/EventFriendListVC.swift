//
//  EventFriendListVC.swift
//  LE
//
//  Created by Rahil Patel on 5/29/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase

struct InvitedFriends {
    static var invitedFriendsUIDs: [String] = []
    static var invitedFriendsUsernames: [String] = []
}

class EventFriendListVC: UITableViewController, UINavigationControllerDelegate {
    var invitedFriendsUIDs:[String] = []
    var invitedFriendsUsernames:[String] = []
    var selectedCellsIndex:[Int] = []
    var currentUser:User? = nil
    var editIsSelected:Bool = false
    
    @IBOutlet weak var SelectAllButton: UIButton!
    @IBOutlet weak var DeleteButton: UIButton!
    @IBOutlet weak var EditButtonLbl: UIButton!
    @IBOutlet var editInvitedFriendsTableView: UITableView!
    
    @IBAction func SelectAllInvitedFriends(_ sender: Any) {
        let numOfRows = editInvitedFriendsTableView.numberOfRows(inSection: 0)
        for i in 0..<numOfRows {
        editInvitedFriendsTableView.selectRow(at: IndexPath(row:i, section:0), animated: true, scrollPosition: .none)
        }
    }
    @IBAction func DeleteFriends(_ sender: Any) {
        selectedCellsIndex = selectedCellsIndex.sorted(by: >)
        for index in selectedCellsIndex {
            print("index: \(index)\ninvitedFriendsUIDs: \(invitedFriendsUsernames)")
            invitedFriendsUIDs.remove(at: index)
            invitedFriendsUsernames.remove(at: index)
        }
        InvitedFriends.invitedFriendsUIDs = invitedFriendsUIDs
        InvitedFriends.invitedFriendsUsernames = invitedFriendsUsernames
        editInvitedFriendsTableView.reloadData()
        selectedCellsIndex = []
    }
    @IBAction func EditButton(_ sender: Any) {
        editIsSelected = !editIsSelected
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
        DeleteButton.isHidden = true
        SelectAllButton.isHidden = true
        navigationController?.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invitedFriendsUsernames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventFriendCell", for: indexPath) as! CustomEventFriendListCell
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
        DeleteButton.setTitleColor(UIColor.init(red:0.196, green:0.3098, blue:0.52, alpha: 1), for: .normal)
        selectedCellsIndex.append(indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        for (index, element) in selectedCellsIndex.enumerated() {
            if element == indexPath.row {
                selectedCellsIndex.remove(at: index)
            }
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
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        print(viewController)
        (viewController as? AddEventController)?.invitedFriendsUIDs = invitedFriendsUIDs
        (viewController as? AddEventController)?.invitedFriendsUsernames = invitedFriendsUsernames
    }
}

class CustomEventFriendListCell: UITableViewCell {
    @IBOutlet weak var ProfileImg: UIImageView!
    @IBOutlet weak var UsernameLbl: UILabel!
    
    
}
