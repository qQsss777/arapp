//
//  ViewController.swift
//  ArcGISARapp
//
//  Created by Marc Le Moigne on 19/12/2019.
//  Copyright © 2019 Esri France. All rights reserved.
//

import UIKit
import ArcGIS

class MapViewController: UIViewController, AGSGeoViewTouchDelegate {

    @IBOutlet weak var mapView: AGSMapView!
    
    private var _map:AGSMap!
    private var _locationDisplay: AGSLocationDisplay!
    private var _isManualGPS:Bool!
    private var _graphicsOverlay = AGSGraphicsOverlay()
    private var _graphic: AGSGraphic!
    
    public var mapToAr:MapToAr = MapToAr()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self._isManualGPS = false
        // Do any additional setup after loading the view.
        
        //SET RUNTIME LICENSE TO REMOVE WATERMARK. STANDARD REQUIRED FOR VIEWSHED TO FUNCTION.
        
        //license the app with the supplied License key
        
        do {
            let result = try AGSArcGISRuntimeEnvironment.setLicenseKey("YOUR LICENCE from ArcGIS Developer account")
            print("License Result : \(result.licenseStatus)")
        }
        catch let error as NSError {
            print("error: \(error)")
        }
        
        self._displayMap()
    }
    
    //Function to display a map, initialize LocationDisplay variable
    private func _displayMap() {
        //Display a map using the ArcGIS Online openStreetMap basemap service
        self._map = AGSMap(basemapType: .openStreetMap, latitude: 48.3833789, longitude: -4.4932725, levelOfDetail: 13)
        self.mapView.map = _map
        self.mapView.graphicsOverlays.add(self._graphicsOverlay)
        self._locationDisplay = self.mapView.locationDisplay
        //When map loaded, display device location, handle change localation
        self._map.load{ [weak self] (error) in
            self?._showAndZoomDeviceLocation()
        }
        
        self.mapView.viewpointChangedHandler = {() in
            self.mapToAr.heading = self.mapView.rotation
        }
    }
    
    //show Device postion
    private func _showAndZoomDeviceLocation() {
        //When location display start, pan and center map on my position
        self._locationDisplay.start{ _ in
            self._locationDisplay.autoPanMode = .compassNavigation
            self._locationDisplay.locationChangedHandler = { (loc) in
                self._getDeviceLocation(location: loc)
            }
        }
    }
    
    //get Location from device
    private func _getDeviceLocation(location:AGSLocation) {
        guard let gpsPosition = location.position else{ return }
        self.mapToAr.x = gpsPosition.x
        self.mapToAr.y = gpsPosition.y

        //negative = course unavaible on the device
        if location.course < 0 {
            self.mapToAr.heading =  self.mapView.rotation
        } else{
            self.mapToAr.heading = location.course
        }
    }
    
    private func _activateLocationTapMapView() {
        self.mapView.touchDelegate = self
        self._locationDisplay.stop()
    }
    
    private func _activateLocationDevice(){
        self.mapView.touchDelegate = nil
        self._graphicsOverlay.graphics.removeAllObjects()
        self._showAndZoomDeviceLocation()
    }
    
    private func createGraphic(mapPoint:AGSPoint) {
        //delete all graphics
        self._graphicsOverlay.graphics.removeAllObjects()
        //create a simple marker symbol
        let image = UIImage(named:"arrow")!
        let symbol = AGSPictureMarkerSymbol(image: image)
        symbol.height = 25
        symbol.width = 25
        //graphic for point using simple marker symbol
        self._graphic = AGSGraphic(geometry: mapPoint, symbol: symbol, attributes: nil)
        //add the graphic to the graphics overlay
        self._graphicsOverlay.graphics.add(self._graphic)
    }
    
    func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.createGraphic(mapPoint: mapPoint)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowArView"{
            guard let destination = segue.destination as? ARViewController else {return}
            //if location from point tapped
            if self._isManualGPS {
                guard let pointLatLon = self._graphic.geometry as? AGSPoint else{return}
                self.mapToAr.heading = self.mapView.rotation
                self.mapToAr.x = pointLatLon.toCLLocationCoordinate2D().longitude
                self.mapToAr.y = pointLatLon.toCLLocationCoordinate2D().latitude
                destination.mapToAr = self.mapToAr
            }else{
                destination.mapToAr = self.mapToAr
            }
        }else {
            return
        }
    }
    
    @IBAction func goToArView(_ sender: UIButton) {
        self.performSegue(withIdentifier: "ShowArView", sender: self)
    }
    
    //Button action to choose modes for retrieve coordinates
    @IBAction func chooseCoordinates(_ sender: UIButton) {
        if self._isManualGPS {
            self._activateLocationDevice()
            self._isManualGPS = false
            sender.setBackgroundImage(UIImage(systemName:"location.slash.fill"), for: .normal)
        }
        else {
            self._activateLocationTapMapView()
            self._isManualGPS = true
            sender.setBackgroundImage(UIImage(systemName:"location.fill"), for: .normal)
        }
    }
}

