//
//  MapViewController.swift
//  LE
//
//  Created by Rahil Patel on 11/12/16.
//  Copyright © 2016 Rahil. All rights reserved.
//

import UIKit
import Firebase
import GooglePlacePicker
import GoogleMaps
import CoreLocation
import FirebaseDatabase

struct EventVariables {
    static var eventIsCreated = false;
    static var latitude = 0.0
    static var longitude = 0.0
    static var description = ""
    static var address = "";
    static var dateMonth = 00
    static var dateDay = 00
    static var dateYear = 0000
    static var timeMin = 00
    static var timeHr = 00
}

extension NSDate
{
    func hour() -> Int
    {
        //Get Hour
        let calendar = NSCalendar.current
        
        let hour = calendar.component(.hour, from: self as Date)
        
        //Return Hour
        return hour
    }
    
    
    func minute() -> Int
    {
        //Get Minute
        let calendar = NSCalendar.current

        let minute = calendar.component(.minute, from: self as Date)
        
        //Return Minute
        return minute
    }
    
    func toShortTimeString() -> String
    {
       
        //Get Short Time String
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: self as Date)
        
        //Return Short Time String
        return timeString
    }
}


class MapViewController: UIViewController, CLLocationManagerDelegate{
    
    let childRef = FIRDatabase.database().reference(withPath: "Events")
    var events: [Event] = []

    
    var mapView: GMSMapView = GMSMapView.map(withFrame: CGRect.zero, camera: GMSCameraPosition.camera(withLatitude: -33.868,longitude:151.2086, zoom:6))
    
    let locationManager = CLLocationManager()
    //let mapView: GMSMapView?
    @IBOutlet weak var addButton: UIImageView!
    
    @IBOutlet weak var PressButton: UIButton!
    @IBAction func PushButton(_ sender: Any, forEvent event: UIEvent) {
        //self.performSegue(withIdentifier: "CreateEventSegue", sender: sender)
    }
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        childRef.observe(.value, with: { snapshot in
            // 2
            var newEvents: [Event] = []
            
            // 3
            for item in snapshot.children {
                // 4
                
                let event = Event(snapshot: item as! FIRDataSnapshot)
                
                if (self.isThirtyPastCurrentTime(date: NSDate(), hour: Int(event.hour)!, minute: Int(event.minute)!)) {

                newEvents.append(event)
                
                self.createMarker(hour:event.hour, minute:event.minute, address:event.address, latitude:event.latitude, longitude:event.longitude, description:event.description, day:event.day, month:event.month, year:event.year)
                }
            }
            
            // 5
            self.events = newEvents
        })
        
        /*for event in events {
            createMarker(hour:event.hour, minute:event.minute, address:event.address, latitude:event.latitude, longitude:event.longitude, description:event.description, day:event.day, month:event.month, year:event.year)
        }*/
        
        
        view.addSubview(mapView)
        
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            // 4
            locationManager.startUpdatingLocation()
            //5

            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
            mapView.settings.compassButton = true
            view = mapView
            
        }
        
        view.addSubview(self.addButton)
        view.addSubview(self.PressButton)
    }
    
    func createMarker(hour:String, minute:String, address:String, latitude:Double, longitude:Double, description:String, day:String, month:String, year:String) {
        
            let timeStr = hour + ":" + minute
        
            let marker = GMSMarker()
        
            marker.position = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(latitude),longitude:CLLocationDegrees(longitude), zoom:6).target
            marker.snippet = description + "\nDate: " + month + "/" + day + "/" + year + "\nTime: " + timeStr + "\nLocation: " + address
            marker.appearAnimation = kGMSMarkerAnimationPop
            marker.map = mapView

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.dataLabel!.text = dataObject
    }
    
    private func isThirtyPastCurrentTime(date: NSDate, hour: Int, minute: Int) -> Bool {
        var tempMin = 0
        var tempHr = hour
        if ((minute + 30) >= 60) {
            tempMin = minute - 30
            tempHr += 1
        }
        if (tempHr > 12) {
            tempHr = 1
        }
        if (tempHr > date.hour()) {
            return true
        }
        else if (tempHr == date.hour() && tempMin > date.minute()) {
            return true
        }
        else {
            return false
        }
    }
    
//}

//extension MapViewController: CLLocationManagerDelegate {
    // 2
    private func locationManager1(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // 3
        if status == .authorizedWhenInUse {
            
            // 4
            locationManager.startUpdatingLocation()
            
            //5
            //mapView!.isMyLocationEnabled = true
            //mapView!.settings.myLocationButton = true
        }
    }
    
    // 6
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            
            // 7
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            
            // 8
            locationManager.stopUpdatingLocation()
        }
        
    }
}
