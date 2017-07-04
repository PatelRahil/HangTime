//
//  SettingsVC.swift
//  LE
//
//  Created by Rahil Patel on 5/21/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var OpenSideBar: UIButton!
    @IBOutlet weak var LogoutBtn: UIButton!
    @IBOutlet weak var settingsTableView: UITableView!
    
    @IBAction func LogOut(_ sender: Any) {
        
        
    }
    
    let notificationTableArray = ["Push Notifications"]
    let supportTableArray  = ["FAQs", "Privacy Policy"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        //self.view.backgroundColor = UIColor.lightGray
        self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
        
        
        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
        
        LogoutBtn.setTitleColor(UIColor.white, for: .normal)
        LogoutBtn.backgroundColor = UIColor.red
        LogoutBtn.layer.cornerRadius = 5
        
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.isScrollEnabled = false
        
        setupTableViewFrame()
        setupLogoutButtonFrame()

    }
    
    private func setupTableViewFrame() {
        let headerHeight:CGFloat = 40
        let rowHeight:CGFloat = 60
        
        var tableViewHeight = headerHeight * CGFloat(settingsTableView.numberOfSections)
        for index in 0...(settingsTableView.numberOfSections - 1) {
            tableViewHeight += rowHeight * CGFloat(settingsTableView.numberOfRows(inSection: index))
        }
        
        let frame = CGRect(x: 0, y: settingsTableView.frame.minY, width: settingsTableView.frame.width, height: tableViewHeight)
        settingsTableView.frame = frame
    }
    
    private func setupLogoutButtonFrame() {
        let viewFrame = self.view.frame
        let btnFrame = LogoutBtn.frame
        let tblFrame = settingsTableView.frame
        let sideOffset = viewFrame.width/20
        let newFrame = CGRect(x: sideOffset, y: tblFrame.maxY + 10, width: viewFrame.width - (2 * sideOffset), height: btnFrame.height)
        
        LogoutBtn.frame = newFrame
    }
    
}

//tableview stuff
extension SettingsVC {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0, 1:
            return 40
        default:
            return 10
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return notificationTableArray.count
        case 1:
            return supportTableArray.count
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                print("FAQs tapped")
            case 1:
                print("Privacy Policy tapped")
            default:
                break
            }
            settingsTableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UILabel(frame: CGRect(origin: CGPoint.init(x: 0, y: 0), size: CGSize(width: self.view.frame.width, height: 40)))
        let label = UILabel(frame: CGRect(x: 20, y: 20, width: self.view.frame.width, height: 10))
        headerView.backgroundColor = Colors.lightGray
        label.font = UIFont(name: label.font.fontName, size: 12)
        label.textColor = UIColor.lightGray
        
        if section == 0 {
            label.text = "NOTIFICATIONS"
        }
        else if section == 1 {
            label.text = "SUPPORT"
        }
        
        headerView.addSubview(label)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "defaultSwitch") as! CustomSettingsCell
            cell.textLabel?.text = notificationTableArray[indexPath.row]
            cell.selectionStyle = .none
            return cell
        }
        else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "default")!
            cell.textLabel?.text = supportTableArray[indexPath.row]
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "default")!
            return cell
        }
    }
}

class CustomSettingsCell:UITableViewCell {
    
    @IBOutlet weak var cellSwitch: UISwitch!
    
    @IBAction func switchTapped(_ sender: Any) {
        
    }
    
    
}
