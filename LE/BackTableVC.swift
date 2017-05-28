//
//  BackTableVC.swift
//  LE
//
//  Created by Rahil Patel on 5/16/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation
import Firebase

class BackTableVC: UITableViewController {
    @IBOutlet var sideTableView: UITableView!
    
    let rootRef = FIRDatabase.database().reference()
    let childRef = FIRDatabase.database().reference(withPath: "Users")
    var TableArray = [String]()
    var username:String = ""
    var currentUser:User? = nil
    
    override func viewDidLoad() {
        TableArray = [" ", "Map", "Add Friends", "Settings"]
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
            cell.ProfilePic.frame.origin.y = 10
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
        if let currentUser = FIRAuth.auth()?.currentUser {
            let userID = currentUser.uid
            
            self.childRef.observe(.value, with: { snapshot in
                for item in snapshot.children.allObjects as! [FIRDataSnapshot] {
                    let dict = item.value as! Dictionary<String,Any>
                    if (dict["UserID"] as? String == userID) {
                        self.currentUser = User(snapshot: item)
                    }
                }
            self.sideTableView.reloadData()
            })
        }
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
