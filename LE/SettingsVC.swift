//
//  SettingsVC.swift
//  LE
//
//  Created by Rahil Patel on 5/21/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation

class SettingsVC: UIViewController {
    
    @IBOutlet weak var OpenSideBar: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
        
    }
    
}
