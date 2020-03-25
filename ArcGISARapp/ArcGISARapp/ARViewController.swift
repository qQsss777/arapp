//
//  ARViewController.swift
//  ArcGISARapp
//
//  Created by Marc Le Moigne on 19/12/2019.
//  Copyright © 2019 Esri France. All rights reserved.
//

import UIKit
import ArcGIS

class ARViewController: UIViewController {

    private var _scene:AGSScene!
    private let _arView = ArcGISARView()
    public var mapToAr:MapToAr = MapToAr()

   override func viewDidLoad() {
        super.viewDidLoad()

    self._arView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(self._arView)

        NSLayoutConstraint.activate([
            self._arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self._arView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self._arView.topAnchor.constraint(equalTo: view.topAnchor),
            self._arView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        self.configureSceneForAR()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self._arView.startTracking(.ignore)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self._arView.stopTracking()
    }
    
    private func configureSceneForAR() {
        // Create scene
        self._scene = AGSScene()
        // Create an elevation source and add it to the scene
        let elevationSource = AGSArcGISTiledElevationSource(url:
            URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        self._scene.baseSurface?.elevationSources.append(elevationSource)

        // Allow camera to go beneath the surface
        self._scene.baseSurface?.navigationConstraint = .stayAbove
        self._scene.baseSurface?.opacity = 0
        
        let sceneLayer = AGSArcGISSceneLayer(url: URL(string:"YOUR_URL")!)
        self._scene.operationalLayers.add(sceneLayer)

        // Create Camera, altitude set to 0 so there is a error. We can call method on basesurface to get elevation point (not write here)
        let camera = AGSCamera(latitude: self.mapToAr.y, longitude: self.mapToAr.x, altitude: 0, heading: self.mapToAr.heading, pitch: 90, roll: 0.0)

        //change worldAlignement to update heading with your value
        self._arView.arConfiguration.worldAlignment = .gravity

        self._arView.sceneView.scene = self._scene
        self._arView.originCamera = camera
        self._arView.clippingDistance = 5000
        self._arView.translationFactor = 1
        
        // Configure atmosphere and space effect
        self._arView.sceneView.spaceEffect = .transparent
        self._arView.sceneView.atmosphereEffect = .none
    }
}
