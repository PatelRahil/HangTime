//
//  BackTableVC.swift
//  LE
//
//  Created by Rahil Patel on 5/16/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage

class BackTableVC: UITableViewController {
    @IBOutlet var sideTableView: UITableView!
    
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Users")
    let storageRef = FIRStorage.storage().reference()

    var TableArray = [String]()
    var username:String = ""
    var currentUser:User? = nil
    var profilePic: UIImage = #imageLiteral(resourceName: "DefaultProfileImg")
    
    override func viewDidLoad() {
        TableArray = [" ", "Map", "Add Friends", "Settings"]
        loadUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadUser()
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableArray.count 
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //profile option
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: " ", for: indexPath) as! CustomSideTableViewCell
            cell.UsernameLbl.text = currentUser?.username
            let prevHeightLbl = cell.UsernameLbl.frame.height
            
            cell.ProfilePic.image = profilePic
            cell.ProfilePic.frame.origin.y = 10
            cell.ProfilePic.layoutIfNeeded()
            cell.ProfilePic.clipsToBounds = true
            cell.ProfilePic.layer.cornerRadius = cell.ProfilePic.bounds.size.width/2.0
            
            cell.UsernameLbl.frame.origin.y = cell.ProfilePic.frame.maxY + prevHeightLbl/2
            //(90.0, 82.0, 77.0, 77.0)
            //(90.0, 164.0, 77.0, 77.0)
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableArray[indexPath.row], for: indexPath)
            cell.textLabel?.text = TableArray[indexPath.row]
            return cell
        }
    }
    
    
    func loadUser() {
        currentUser = User(data: UserData())
        profilePic = currentUser!.profilePic!
        print(currentUser?.username)
        sideTableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return 150
        }
        else {
            return 50
        }
    }
}

class CustomSideTableViewCell: UITableViewCell {
    @IBOutlet weak var UsernameLbl: UILabel!
    @IBOutlet weak var ProfilePic: UIImageView!
    
}
