//
//  Colors.swift
//  LE
//
//  Created by Rahil Patel on 7/2/17.
//  Copyright © 2017 Rahil. All rights reserved.
//

import Foundation

struct Colors {
    
    //possible color theme colors
    static let mintGreen = UIColor.init(r: 38, g: 192, b: 92, a: 1) //minty green
    //static let darkGreen = UIColor.init(r: 0, g: 110, b: 50, a: 1) //dark green
    static let darkMintGreen = UIColor.init(r: 0, g: 161, b: 112, a: 1) //dark minty green

    static let purple = UIColor.init(r: 153, g: 50, b: 204, a: 1) //purple
    static let indigo = UIColor.init(r: 75, g: 0, b: 130, a: 1) //indigo
    static let darkRed = UIColor.init(r: 203, g: 37, b: 37, a: 1) //dark red
    static let gold = UIColor.init(r: 219, g: 174, b: 88, a: 1) //gold
    static let salmon = UIColor.init(r: 245, g: 84, b: 73, a: 1) //salmon
    //current color theme
    static let blueGreen = UIColor.init(r: 26, g: 126, b: 126, a: 1) //bluegreen
        
    //For gradient
    static let yellow = UIColor.init(r: 25, g: 200, b: 0, a: 1)
    
    //used for profile pic cell in EventDetailsVC
    static let darkGray = UIColor.init(r: 189, g: 195, b: 199, a: 1)

    //For tableview section headers
    static let lightGray = UIColor.init(r: 125, g: 125, b: 125, a: 0.2)

    //variation of green theme
    static let evergreen = UIColor.init(r: 38, g: 167, b: 92, a: 1)
    
    //some more flat colors
    static let eucalyptus = UIColor.init(r: 38, g: 166, b: 91, a: 1) //green
    static let cinnabar = UIColor.init(r: 231, g: 76, b: 60, a: 1) //red
    static let royalBlue = UIColor.init(r: 65, g: 131, b: 215, a: 1) //blue
}

struct AppData {
    static var token:String = ""
}
