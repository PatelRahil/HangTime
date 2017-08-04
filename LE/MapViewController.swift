//
//  MapViewController.swift
//  LE
//
//  Created by Rahil Patel on 11/12/16.
//  Copyright © 2016 Rahil. All rights reserved.
//

// things to add:
// event title then separate description bar (click to see more details button)
// change time of event disappearance to 30 minutes after event
// or you can make an end time 
// allow creator to edit event (will need to add an array of events created by a user under a specific profile

import UIKit
import Firebase
import GooglePlacePicker
import GoogleMaps
import CoreLocation
import FirebaseDatabase
import FirebaseStorage


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


class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    //for debugging
    
    let childRef = FIRDatabase.database().reference(withPath: "Events")
    let userRef = FIRDatabase.database().reference(withPath: "Users")
    let storageRef = FIRStorage.storage().reference()
    
    var events: [Event] = []
    var markers: [GMSMarker] = []
    // following variable is [eventID:eventCreatorProfilePic]
    var eventCreatorProfilePics: [String:UIImage] = [String:UIImage]()
    var pickedEventID:String = ""
    var cameraHasBeenSetToCurrentPositionAtLeastOnce:Bool = false
    var cameraPosition:GMSCameraPosition? = nil

    var currentUser:User!
    var mapView: GMSMapView = GMSMapView.map(withFrame: CGRect.zero, camera: GMSCameraPosition.camera(withLatitude: 0,longitude:0, zoom:6))
    
    let locationManager = CLLocationManager()
    
    //Google Map Locations variables
    var selectedRoute: Dictionary<String, AnyObject>!
    var overviewPolyline: Dictionary<String, AnyObject>!
    var originCoordinate: CLLocationCoordinate2D!
    var destinationCoordinate: CLLocationCoordinate2D!
    var originAddress: String!
    var destinationAddress: String!
    var routePolyline: GMSPolyline!
    
    //container view variables
    var searchLocationsContainerView:UIView = UIView()
    var textField:UITextField = UITextField()
    var isContainerLaidOut = false
    var originalContainerPosition:CGPoint? = nil
    var direction:GestureDirection? = nil
    
    //Location searching variables
    var tableView:UITableView = UITableView()
    var tableData:[String] = [String]()
    var secondaryTableData:[String] = [String]()
    var fullAddressData:[String] = [String]()
    var placeIDData:[String] = [String]()
    var dataFetcher:GMSAutocompleteFetcher? = nil
    var tempMarker:GMSMarker? = nil
    

    //just the image of the button
    @IBOutlet weak var PressButton: UIButton!
    @IBOutlet var OpenSideBar: UIButton!
    @IBAction func PushButton(_ sender: Any, forEvent event: UIEvent) {
    }
    
    // MARK: - View methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        currentUser = User(data: UserData())
        mapView.delegate = self
        view.addSubview(mapView)
        
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            // 4
            locationManager.startUpdatingLocation()
            //5

            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
            view = mapView
            
        }

        self.navigationController?.isNavigationBarHidden = true
        
        layoutButtons()
        view.addSubview(self.PressButton)
        view.addSubview(self.OpenSideBar)
        
        OpenSideBar.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
        //self.revealViewController().rearViewRevealWidth = self.view.frame.width - 200

        //removes a default gesture recognizer blocker from the mapview so that other ui elements can be interacted with
        for gesture in mapView.gestureRecognizers! {
            mapView.removeGestureRecognizer(gesture)
        }
        
    }
    override func viewDidLayoutSubviews() {
        //ensures the laying out is only done once
        if !isContainerLaidOut {
            //moves the myLocation button above the container view
            mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.height/9, right: 0)
            searchLocationsContainerView = findAddressView()
            view.addSubview(searchLocationsContainerView)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if CLLocationManager.locationServicesEnabled() {
            // 4
            locationManager.startUpdatingLocation()
            //5
            
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
            view = mapView
            
            if let cameraPos = cameraPosition {
                mapView.camera = cameraPos
            }
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMap()
        self.navigationController?.isNavigationBarHidden = true
        print("Button Position:::  (\(PressButton.frame.midX),\(PressButton.frame.midY)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraPosition = mapView.camera
    }
    
    // MARK: - GMSMapView Delegate methods
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        //perform segue depending on the event
        var userData:String = marker.userData as! String
        let firstChar = userData[userData.startIndex]

        if firstChar == "&" {
            userData.remove(at:userData.startIndex)
            print("USERDATA: \(userData)")
            pushToCreateEventWithAddress(address: userData)
        }
        else {
            pickedEventID = marker.userData as! String
            performSegue(withIdentifier: "EventDetails", sender: marker)
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        
        if let marker = tempMarker {
            var userData:String = marker.userData as! String
            
            userData.remove(at: userData.startIndex)
            for (index,address) in fullAddressData.enumerated() {
                if address == userData {
                    let indexPath:IndexPath = IndexPath(row: index, section: 0)
                    print(indexPath)
                    tableView.deselectRow(at: indexPath, animated: false)
                }
            }
        }
        
        clearMapExceptEventMarkers()
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let userData:String = marker.userData as! String
        let firstChar = userData[userData.startIndex]
        if firstChar == "&" {
            return false
        }
        else {
            //remove any previous polylines
            clearMapExceptEventMarkers()
        
            //draw polyline from current location to marker
            if let coord = locationManager.location?.coordinate {
            
                var coordBounds:GMSCoordinateBounds = GMSCoordinateBounds(coordinate: coord, coordinate: marker.position)
            
                let insets:UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
                //mapView.animate(to: mapView.camera(for: coordBounds, insets: insets)!)
                drawPath(startLocation: coord, endLocation: marker.position) { (status, success) in
                    if success {
                        self.drawRoute()
                        coordBounds = coordBounds.includingPath(self.routePolyline.path!)
                        mapView.animate(to: mapView.camera(for: coordBounds, insets: insets)!)
                    }
                }
                mapView.selectedMarker = marker
            
                return true
            }
            else {
                return false
            }
        }
    }
    
    // MARK: - CLLocationManager delegate methods
    private func locationManager1(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            
            locationManager.startUpdatingLocation()
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if !cameraHasBeenSetToCurrentPositionAtLeastOnce {
            if let location = locations.first {
                mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
                
                locationManager.stopUpdatingLocation()
            }
            cameraHasBeenSetToCurrentPositionAtLeastOnce = true
        }
    }
    
    // MARK: - Transition methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        locationManager.stopUpdatingLocation()
        if segue.identifier == "EventDetails" {
            let nextController = (segue.destination as! EventDetailsVC)
            childRef.observeSingleEvent(of: .value, with: { snapshot in
                for item in snapshot.children {
                    let snap = item as! FIRDataSnapshot
                    if snap.key == self.pickedEventID {
                        let event:Event = Event(snapshot: snap)
                        
                        print(event)
                        
                        EventVariables.address = event.address
                        EventVariables.dateDay = Int(event.day)!
                        EventVariables.dateMonth = Int(event.month)!
                        EventVariables.dateYear = Int(event.year)!
                        EventVariables.description = event.description
                        EventVariables.latitude = event.latitude
                        EventVariables.longitude = event.longitude
                        EventVariables.timeHr = Int(event.hour)!
                        EventVariables.timeMin = Int(event.minute)!
                        EventVariables.eventID = self.pickedEventID
                        EventVariables.createdByUID = event.createdByUID
                        EventVariables.invitedFriends = event.invitedFriends
                        EventVariables.isPublic = event.isPublic
                        
                        self.userRef.child("User: \(event.createdByUID)").observeSingleEvent(of: .value,with: { snapshot in
                            nextController.eventCreator = User(snapshot: snapshot)
                            nextController.setTitle() //This is what causes a switch to be added
                        })
                    }
                }
            })
            
        }
    }
    
    private func pushToCreateEventWithAddress(address:String) {
        let destinationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddEventController") as! AddEventController
        destinationVC.address = address
        
        self.navigationController?.pushViewController(destinationVC, animated: true)
    }
    
    // MARK: - Private convenience methods
    
    //MARK: laying out mapView
    func updateMap() {
        mapView.clear()
        childRef.observeSingleEvent(of: .value, with: { snapshot in
            // 2
            var newEvents: [Event] = []
            // 3
            for item in snapshot.children {
                // 4
                let snap = item as! FIRDataSnapshot
                let event = Event(snapshot: snap)
                
                //let thirtyPast: Bool = self.isThirtyPastCurrentTime(date: NSDate(), hour: Int(event.hour)!, minute: Int(event.minute)!, day: Int(event.day)!, month: Int(event.month)!, year: Int(event.year)!)
                let allowedToView: Bool = self.isAllowedToViewEvent(isPublic:event.isPublic, friendsAllowed: event.invitedFriends, tag:snap.key)
                if allowedToView {
                    newEvents.append(event)
                    self.createMarker(hour:event.hour, minute:event.minute, address:event.address, latitude:event.latitude, longitude:event.longitude, description:event.description, day:event.day, month:event.month, year:event.year, tag:snap.key, uid:event.createdByUID)
                    
                    
                    
                }
            }
            // 5
            self.events = newEvents
        })
        
    }
    
    func createMarker(hour:String, minute:String, address:String, latitude:Double, longitude:Double, description:String, day:String, month:String, year:String, tag:String, uid:String) {
        var newHr:Int = Int(hour)!
        var newMin = minute
        var AMPMstr = " AM"
        if newHr == 0 {
            newHr = 12
        }
        else if newHr > 12 {
            newHr -= 12
            AMPMstr = " PM"
        }
        if Int(newMin)! < 10 {
            newMin = "0" + newMin
        }
        let timeStr = String(newHr) + ":" + newMin + AMPMstr
        
        let marker = GMSMarker()
        
        if userCreatedEvent(withTag: tag) {
            marker.icon = GMSMarker.markerImage(with: UIColor.blue)
        }
        else {
            marker.icon = GMSMarker.markerImage(with: nil)
        }
 
        marker.position = GMSCameraPosition.camera(withLatitude: CLLocationDegrees(latitude),longitude:CLLocationDegrees(longitude), zoom:6).target
        marker.snippet = description + "\n" + month + "/" + day + "/" + year + "\n" + timeStr + "\n" + address
        marker.userData = tag
        marker.appearAnimation = kGMSMarkerAnimationPop
        marker.map = mapView
        //until the profile picture is loaded
        marker.iconView = setupMarkerView(profilePic: #imageLiteral(resourceName: "DefaultProfileImg"))
        marker.tracksViewChanges = true
        marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0.25)
        markers.append(marker)
        updateMarkerView(uid: uid, marker: marker)
        
    }

    func drawPath(startLocation:CLLocationCoordinate2D, endLocation:CLLocationCoordinate2D, completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        let origin = "\(startLocation.latitude),\(startLocation.longitude)"
        let destination = "\(endLocation.latitude),\(endLocation.longitude)"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving"
        //url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let directionsURL = URL(string: url)
        DispatchQueue.main.async {
            do {
                let directionsData = try Data(contentsOf: directionsURL!)
                print("VALID DATA")
                do {
                    let dict = try JSONSerialization.jsonObject(with: directionsData, options: JSONSerialization.ReadingOptions.mutableContainers)
                    if let dictionary = dict as? [String:AnyObject] {
                        
                        
                            let status = dictionary["status"] as! String
                
                            if status == "OK" {
                                self.selectedRoute = (dictionary["routes"] as! Array<Dictionary<String, AnyObject>>)[0]
                                self.overviewPolyline = self.selectedRoute["overview_polyline"] as! Dictionary<String, AnyObject>
                    
                                let legs = self.selectedRoute["legs"] as! Array<Dictionary<String, AnyObject>>
                    
                                let startLocationDictionary = legs[0]["start_location"] as! Dictionary<String, AnyObject>
                                self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! Double, startLocationDictionary["lng"] as! Double)
                    
                                let endLocationDictionary = legs[legs.count - 1]["end_location"] as! Dictionary<String, AnyObject>
                                self.destinationCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! Double, endLocationDictionary["lng"] as! Double)
                    
                                self.originAddress = legs[0]["start_address"] as! String
                                self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
                                completionHandler(status, true)
                    //self.calculateTotalDistanceAndDuration()
                    
                            }
                            else {
                    completionHandler(status, false)
                            }
                
                        }
                }
                
                catch {
                    print("json error: \(error.localizedDescription)")
                    completionHandler("",false)

                }
            }
            catch {
                print("invalid data error: \n\(error)")
            }
        }
        
    }
    
    func drawRoute() {
        let route = self.overviewPolyline["points"] as! String
        
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        routePolyline.strokeWidth = 4
        routePolyline.strokeColor = Colors.blueGreen
        routePolyline.map = mapView
    }
    
    private func isAllowedToViewEvent(isPublic:Bool, friendsAllowed:[String], tag:String) -> Bool {
        var isAllowed = false
        var userCreatedThisEvent = false
        for friend in friendsAllowed {
            if friend == currentUser.getUserID() {
                isAllowed = true
            }
        }
        
        userCreatedThisEvent = userCreatedEvent(withTag: tag)
        //print("Public: \(isPublic)   Allowed: \(isAllowed)   User Created This: \(userCreatedThisEvent)")
        return isPublic || isAllowed || userCreatedThisEvent
    }
    private func userCreatedEvent(withTag tag:String) -> Bool {
        var userCreatedThisEvent = false
        for event in currentUser.createdEvents {
            if event == tag {
                userCreatedThisEvent = true
            }
        }
        return userCreatedThisEvent
    }
    private func isThirtyPastCurrentTime(date: NSDate, hour: Int, minute: Int, day: Int, month:Int, year:Int) -> Bool {
        var tempMin = minute
        var tempHr = hour
        var tempDay = day
        var tempMonth = month
        var tempYear = year
        
        let thisYear = Calendar.current.component(.year, from: date as Date)
        let thisMonth =  Calendar.current.component(.month, from: date as Date)
        let thisDay =  Calendar.current.component(.day, from: date as Date)
        
        //can replace 30 with a variable for how long after the start time you want the event to be visible
        while ((tempMin + 30) >= 60) {
            tempMin = minute + 30 - 60
            tempHr += 1
        }
        if (tempHr > 24) {
            tempHr = 1
            tempDay += 1
        }
        if (month == 1||month == 3||month == 5||month == 7||month == 8||month == 10||month == 12) {
            if (day == 31) {
                tempMonth += 1
            }
        }
        else if (month == 2){ // @saif
            if (year-2000 % 4 == 0) {
                if (day == 29) {
                    tempMonth += 1
                }
            }
            else {
                if (day == 28) {
                    tempMonth += 1
                }
            }
        }
        else {
            if (day == 30) {
                tempMonth += 1
            }
        }
        if (tempMonth > 12) {
            tempYear += 1
        }
        
        if (tempYear > thisYear) {
            return false
        }
        else if (tempYear == thisYear && tempMonth > thisMonth) {
            return false
        }
        else if (tempYear == thisYear && tempMonth == thisMonth && tempDay > thisDay){
            return false
        }
        else if (tempYear == thisYear && tempMonth == thisMonth && tempDay == thisDay && tempHr > date.hour()) {
            return false
        }
        else if (tempYear == thisYear && tempMonth == thisMonth && tempDay == thisDay && tempHr == date.hour() && tempMin > date.minute()) {
            return false
        }
        else {
            return true
        }
    }
    
    // MARK: UI Stuff
    private func layoutButtons() {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let btnWidth = height/15 //so width and height are equal
        let btnHeight = height/15
        let offset:CGFloat = 30
        let size = CGSize(width: btnWidth, height: btnHeight)
        let origin = CGPoint(x: width - btnWidth - offset/4 , y: offset)
        //PressButton.frame = CGRect(origin: CGPoint(x: 8 * width / 9, y: height / 50), size: CGSize(width: height / 11, height: height / 11))
        PressButton.frame = CGRect(origin: origin, size: size)
        OpenSideBar.frame = CGRect(origin: CGPoint(x: 7 * width / 320, y: height / 25), size: CGSize(width: height / 22, height: height / 22))
        
    }
    
    private func setupMarkerView(profilePic: UIImage) -> UIImageView {
        let markerOutline = UIImage(named: "CustomMarker.png")!
        let markerView = UIImageView()

        let size = CGSize(width: 60, height: 96)
        UIGraphicsBeginImageContext(size)
        let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        markerOutline.draw(in: areaSize)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        markerView.frame = areaSize
        markerView.image = newImage
        
        let imgView = UIImageView()
        markerView.addSubview(imgView)
        let xPos: CGFloat = imgView.superview!.frame.width / 4.0
        let yPos: CGFloat = imgView.superview!.frame.height / 3.878787878787
        let width: CGFloat = imgView.superview!.frame.width / 2
        let height: CGFloat = width
        let frame = CGRect(x: xPos, y: yPos, width: width, height: height)
        imgView.frame = frame
        imgView.image = profilePic
        imgView.layer.masksToBounds = true
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = imgView.layer.bounds.width/2.0
        
        return markerView
    }
    
    private func updateMarkerView(uid:String, marker:GMSMarker) {
        
        let filePath = "Users/User: \(uid)/\("profilePicture")"
        self.storageRef.child(filePath).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
            if error == nil {
                let userPhoto = UIImage(data: data!)
                
                marker.iconView = self.setupMarkerView(profilePic: userPhoto!)
                self.eventCreatorProfilePics[marker.userData as! String] = userPhoto!
            }
            else {
                //error
            }
            marker.tracksViewChanges = false
        })
    }
    
    private func findAddressView() -> UIView {
        let swipeGesture:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(swipeRecognizer(gestureRecognizer:)))
        swipeGesture.delegate = self
        
        let containerView = UIView()
        let containerWidth = view.frame.width
        let containerHeight = 2 * view.frame.height/3
        let xPos:CGFloat = 0
        let yPos = view.frame.height - containerHeight/6
        containerView.frame = CGRect(x: xPos, y: yPos, width: containerWidth, height: containerHeight)
        containerView.backgroundColor = UIColor.init(r: 255, g: 255, b: 255, a: 0.9)
        containerView.layer.cornerRadius = 8
        containerView.addGestureRecognizer(swipeGesture)
        
        let textFieldXPos:CGFloat = 10
        let textFieldYPos:CGFloat = 10
        let textFieldHeight:CGFloat = 40
        let textFieldWidth:CGFloat = containerWidth - textFieldXPos * 2

        textField.frame = CGRect(x: textFieldXPos, y: textFieldYPos, width: textFieldWidth, height: textFieldHeight)
        textField.backgroundColor = UIColor.init(r: 204, g: 204, b: 204, a: 1)
        textField.borderStyle = .roundedRect
        textField.placeholder = "Search"
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .search
        textField.delegate = self
        textField.addTarget(self, action: #selector(processTextfieldText(_:)), for: .editingChanged)
        
        let tableViewXPos:CGFloat = 0
        let tableViewYPos:CGFloat = textFieldYPos * 2 + textFieldHeight
        let tableViewWidth:CGFloat = containerWidth
        let tableViewHeight:CGFloat = containerHeight - tableViewYPos
        
        tableView.frame = CGRect(x: tableViewXPos, y: tableViewYPos, width: tableViewWidth, height: tableViewHeight)
        tableView.separatorColor = Colors.blueGreen
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "placeCell")
        
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        dataFetcher = GMSAutocompleteFetcher(bounds: nil, filter: nil)
        dataFetcher?.delegate = self
        
        containerView.addSubview(textField)
        containerView.addSubview(tableView)
        isContainerLaidOut = true
        return containerView
    }
    
    // MARK:- Other
    func clearMapExceptEventMarkers() {
        print("CLEARING MAP")
        print(eventCreatorProfilePics)
        mapView.clear()
        for marker in markers {
            marker.appearAnimation = kGMSMarkerAnimationNone
            marker.map = self.mapView
            
            if let eventID = marker.userData as? String {
                if let profilePic = eventCreatorProfilePics[eventID] {
                    marker.iconView = setupMarkerView(profilePic: profilePic)
                }
            }
        }
    }
    
}

// MARK:- Textfield Methods
extension MapViewController:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let frame = searchLocationsContainerView.frame
        UIView.animate(withDuration: 0.3) {
            let endPoint:CGPoint = CGPoint(x: 0, y: self.view.frame.height/3)
            self.searchLocationsContainerView.frame = CGRect(origin: endPoint, size: frame.size)
        }
    }
    
    func processTextfieldText(_ sender:UITextField) {
        if let input = sender.text {
            searchForLocationWithText(text: input)
        }
    }
    
    private func searchForLocationWithText(text:String) {
        dataFetcher?.sourceTextHasChanged(text)
    }
}

// MARK:- GMSAutocompleteFetcherDelegate
extension MapViewController: GMSAutocompleteFetcherDelegate {
   
    func didAutocomplete(with predictions: [GMSAutocompletePrediction]) {
        tableData.removeAll()
        secondaryTableData.removeAll()
        fullAddressData.removeAll()
        placeIDData.removeAll()
        
        for prediction in predictions {
            
            tableData.append(prediction.attributedPrimaryText.string)
            fullAddressData.append(prediction.attributedFullText.string)
            if let placeID = prediction.placeID {
                placeIDData.append(placeID)
            }
            else {
                fullAddressData.append("")
            }
            if let secondaryText = prediction.attributedSecondaryText?.string {
                secondaryTableData.append(secondaryText)
            }
            else {
                secondaryTableData.append("")
            }
            
        }
        tableView.reloadData()
    }
    
    func didFailAutocompleteWithError(_ error: Error) {
        //resultText?.text = error.localizedDescription
        print(error.localizedDescription)
    }
}

// MARK:- TableView Methods
extension MapViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //remove marker from previous selection if it exists
        clearMapExceptEventMarkers()
        
        //move search view down to give room for the mapView
        let frame = searchLocationsContainerView.frame
        UIView.animate(withDuration: 0.3) {
            let endPoint:CGPoint = CGPoint(x: 0, y: 8 * self.view.frame.height/9)
            self.searchLocationsContainerView.frame = CGRect(origin: endPoint, size: frame.size)
        }
        
        
        let selectedAddress:String = fullAddressData[indexPath.row]
        if placeIDData[indexPath.row] == "" {
            
        }
        else {
            let url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(placeIDData[indexPath.row])&key=AIzaSyB4pOS_SFVlZ78dl6rYDyzhkXWu7nrASk8"
            let directionsURL = URL(string: url)
            do {
                let data = try Data(contentsOf: directionsURL!)
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
                    if let dict = json as? [String:AnyObject] {
                        
                        let result = dict["result"] as! Dictionary<String,Any>
                        let geometry = result["geometry"] as! Dictionary<String,Any>
                        let address:[String:Any] = geometry["location"] as! Dictionary<String, Any>
                        let coord = CLLocationCoordinate2D(latitude: address["lat"] as! CLLocationDegrees, longitude: address["lng"] as! CLLocationDegrees)
                        
                        textField.text = selectedAddress
                        
                        self.tempMarker = GMSMarker(position: coord)
                        self.tempMarker?.snippet = "Tap to create an event here\n\(selectedAddress)"
                        self.tempMarker?.userData = "&\(selectedAddress)"
                        self.tempMarker?.map = self.mapView
                        self.mapView.animate(toLocation: coord)
                        self.mapView.selectedMarker = self.tempMarker
                        
                    }
                } catch {
                    print("Invalid json")
                }
                
            } catch {
                print("Bad data")
            }
        }
    }
 
}

extension MapViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "defaultCell")
        cell.textLabel?.text = tableData[indexPath.row]
        cell.textLabel?.highlightedTextColor = UIColor.white
        cell.detailTextLabel?.text = secondaryTableData[indexPath.row]
        cell.detailTextLabel?.highlightedTextColor = UIColor.white
        
        let selectedBGView:UIView = UIView()
        selectedBGView.backgroundColor = Colors.blueGreen
        cell.selectedBackgroundView = selectedBGView
        
        return cell
    }
}

// MARK:- Gesture Delegate methods
extension MapViewController:UIGestureRecognizerDelegate {
    
    enum GestureDirection {
        case up,down,left,right
    }
    
    func swipeRecognizer(gestureRecognizer: UIPanGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            originalContainerPosition = searchLocationsContainerView.center
        }
        
        if gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: view)
            if translation.y > 0 {
                direction = .down
            }
            else if translation.y < 0 {
                direction = .up
            }
            
            let newCenter = CGPoint(x: searchLocationsContainerView.center.x, y: originalContainerPosition!.y + translation.y)
            let refRect:UIView = UIView(frame: CGRect(origin: CGPoint.zero, size: searchLocationsContainerView.frame.size))
            refRect.center = newCenter

            if direction == .down {
                searchLocationsContainerView.center = newCenter
            }
            else if direction == .up && refRect.frame.minY >= self.view.frame.height/3 {
                searchLocationsContainerView.center = newCenter
            }
            
        }
        
        if gestureRecognizer.state == .ended {
            if let direction = direction {
                if direction == .down {
                    let frame = searchLocationsContainerView.frame
                    UIView.animate(withDuration: 0.3) {
                        let endPoint:CGPoint = CGPoint(x: 0, y: 8 * self.view.frame.height/9)
                        self.searchLocationsContainerView.frame = CGRect(origin: endPoint, size: frame.size)
                    }
                }
                else if direction == .up {
                    let frame = searchLocationsContainerView.frame
                    UIView.animate(withDuration: 0.3) {
                        let endPoint:CGPoint = CGPoint(x: 0, y: self.view.frame.height/3)
                        self.searchLocationsContainerView.frame = CGRect(origin: endPoint, size: frame.size)
                    }
                }
            }
            self.view.endEditing(true)
        }
        
    }
}
