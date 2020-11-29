//
//  MapViewController.swift
//  CommercialProject
//
//  Created by Vũ Quý Đạt  on 18/11/2020.
//

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager:CLLocationManager!
    private var allAnnotations: [MKAnnotation]?
    var x = 21.795_316
    
    let defaults = UserDefaults.standard
    var myarray = [String]()
    var shouldPassArray = true
    
    // MARK: - Properties
    var annotations: [Annotation] = []
    var annotationInfos: [AnnotationInfo] = []
    
    let acronymsRequest = ResourceRequest<Annotation>(resourcePath: "annotations/data") // get image
    let annotationsRequestInfo = ResourceRequest<AnnotationInfo>(resourcePath: "annotations")
    
    private var displayedAnnotations: [MKAnnotation]? {
        willSet {
            if let currentAnnotations = displayedAnnotations {
                mapView.removeAnnotations(currentAnnotations)
            }
        }
        didSet {
            if let newAnnotations = displayedAnnotations {
                mapView.addAnnotations(newAnnotations)
            }
//            centerMapOnSanFrancisco()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled(){
            locationManager.startUpdatingLocation()
        }
        
        registerMapAnnotationViews()
        
        
        let flowerAnnotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: 21.795_316, longitude: 105.493_760))
        flowerAnnotation.title = NSLocalizedString("FLOWERS_TITLE", comment: "Flower annotation")
        flowerAnnotation.imageName = "conservatory_of_flowers"
        
        
        // Dispaly all annotations on the map.
        
//        setupData()
//        showAllAnnotations(self)
        
        if let array = defaults.stringArray(forKey: "ListImageArray") {
            myarray = array
        } else {
            myarray = []
        }
        print("array: \(myarray)")
        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.setupData), userInfo: nil, repeats: true)
        getAnnotationList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @objc func setupData () {
        // list image did download
//        guard let array = defaults.stringArray(forKey: "ListImageArray") else {
//            print("false get item from plist!")
//            return shouldPassArray = false
//        }
        
        
        let checkTotalOfAnnotations = AcronymRequest(myarray.count - 1)
        checkTotalOfAnnotations.check { [weak self] result in
          switch result {
          case .success(let data):
            if data.shouldUpdate {
                self?.getDataForAnnotations()
            } else {
            }
          case .failure:
//            ErrorPresenter.showError(message: "There was an error getting the acronym's user", on: self)
          print("fail!")
          }
        }
        
        // annotations init
        // Create the array of annotations and the specific annotations for the points of interest.
//        self.allAnnotations = [FerryBuildingAnnotation(21.795_316, 105.393_760, "6.png"), FerryBuildingAnnotation(x, 105.493_760, "5.png"), FerryBuildingAnnotation(21.795_316, 105.593_760, "7.png"), FerryBuildingAnnotation(21.795_316, 105.693_760, "8.png")]
    }
    
    func getDataForAnnotations () {
        // annotations data
        acronymsRequest.getAll { [weak self] annotationResult in
            
            switch annotationResult {
            case .failure:
                ErrorPresenter.showError(message: "There was an error getting the annotations", on: self)
            case .success(let annotations):
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.annotations = annotations
                    for annotation in annotations {
                        if (self.myarray.count > 0 && self.myarray.contains(annotation.annotationImageName)) {
                        } else {
                            let data = Data(base64Encoded: annotation.image)
                            let image = UIImage(data: data!)?.pngData()
                            UserDefaults.standard.set(annotation.image, forKey: (annotation.annotationImageName))
                            print(annotation.annotationImageName)
                            
                            self.myarray.append(annotation.annotationImageName)
                            print("count: \(annotations.count)  \(self.myarray.count)")
                            self.defaults.set(self.myarray, forKey: "ListImageArray")
                        }
                    }
                    self.getAnnotationList()
                }
            }
        }
    }
    
    func getAnnotationList () {
        annotationsRequestInfo.getAll { [weak self] result in
            
            switch result {
            case .failure:
                ErrorPresenter.showError(message: "There was an error getting the annotations", on: self)
            case .success(let annotationInfos):
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.annotationInfos = annotationInfos
                    self.allAnnotations = self.annotationsInfoMaker(annotationInfos)
                    self.showAllAnnotations(self)
                }
            }
        }
    }
    
    func annotationsInfoMaker (_ annotationInfos: [AnnotationInfo]) -> [FerryBuildingAnnotation] {
        var fer = [FerryBuildingAnnotation]()
        for subAnnotationInfo in annotationInfos {
            print(subAnnotationInfo)
            let latitide = Double(subAnnotationInfo.latitude)!
            let longitude = Double(subAnnotationInfo.longitude)!
            fer.append(FerryBuildingAnnotation(latitide, longitude, (String(subAnnotationInfo.id) + ".png")))
            print("image render: \(String(subAnnotationInfo.id) + ".png")")
        }
        return fer
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    /// Register the annotation views with the `mapView` so the system can create and efficently reuse the annotation views.
    /// - Tag: RegisterAnnotationViews
    private func registerMapAnnotationViews() {
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(BridgeAnnotation.self))
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(CustomAnnotation.self))
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(SanFranciscoAnnotation.self))
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(FerryBuildingAnnotation.self))
    }
    
    private func centerMapOnSanFrancisco() {
        let span = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        let center = CLLocationCoordinate2D(latitude: x, longitude: 105.493_760)
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }
    
    // MARK: - Button Actions
    
    private func displayOne(_ annotationType: AnyClass) {
        let annotation = allAnnotations?.first { (annotation) -> Bool in
            return annotation.isKind(of: annotationType)
        }
        
        if let oneAnnotation = annotation {
            displayedAnnotations = [oneAnnotation]
        } else {
            displayedAnnotations = []
        }
    }

    @IBAction func test(_ sender: UIButton) {
        let y = x + 0.01
        x = y
        allAnnotations = [SanFranciscoAnnotation(), FerryBuildingAnnotation(21.795_316, 105.393_760, "ferry_building"), FerryBuildingAnnotation(y, 105.493_760, "ferry_building"), FerryBuildingAnnotation(21.795_316, 105.593_760, "ferry_building"), BridgeAnnotation(), FerryBuildingAnnotation(21.795_316, 105.693_760, "ferry_building")]
        displayedAnnotations = allAnnotations
    }
    @IBAction private func showOnlySanFranciscoAnnotation(_ sender: Any) {
        // User tapped "City" button in the bottom toolbar
        displayOne(SanFranciscoAnnotation.self)
    }
    
    @IBAction private func showOnlyBridgeAnnotation(_ sender: Any) {
        // User tapped "Bridge" button in the bottom toolbar
        displayOne(BridgeAnnotation.self)
    }
    
    @IBAction private func showOnlyFlowerAnnotation(_ sender: Any) {
        // User tapped "Flower" button in the bottom toolbar
        displayOne(CustomAnnotation.self)
    }
    
    @IBAction private func showOnlyFerryBuildingAnnotation(_ sender: Any) {
        // User tapped "Ferry" button in the bottom toolbar
        displayOne(FerryBuildingAnnotation.self)
    }
    
    @IBAction private func showAllAnnotations(_ sender: Any) {
        // User tapped "All" button in the bottom toolbar
        displayedAnnotations = allAnnotations
    }
}

extension MapViewController: MKMapViewDelegate {

    /// Called whent he user taps the disclosure button in the bridge callout.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        // This illustrates how to detect which annotation type was tapped on for its callout.
        if let annotation = view.annotation, annotation.isKind(of: BridgeAnnotation.self) {
            print("Tapped Golden Gate Bridge annotation accessory view")
            
            if let detailNavController = storyboard?.instantiateViewController(withIdentifier: "DetailNavController") {
                detailNavController.modalPresentationStyle = .popover
                let presentationController = detailNavController.popoverPresentationController
                presentationController?.permittedArrowDirections = .any
                
                // Anchor the popover to the button that triggered the popover.
                presentationController?.sourceRect = control.frame
                presentationController?.sourceView = control
                
                present(detailNavController, animated: true, completion: nil)
            }
        }
    }
    
    /// The map view asks `mapView(_:viewFor:)` for an appropiate annotation view for a specific annotation.
    /// - Tag: CreateAnnotationViews
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !annotation.isKind(of: MKUserLocation.self) else {
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
            return nil
        }
        
        var annotationView: MKAnnotationView?
        
        if let annotation = annotation as? BridgeAnnotation {
            annotationView = setupBridgeAnnotationView(for: annotation, on: mapView)
        } else if let annotation = annotation as? CustomAnnotation {
            annotationView = setupCustomAnnotationView(for: annotation, on: mapView)
        } else if let annotation = annotation as? SanFranciscoAnnotation {
            annotationView = setupSanFranciscoAnnotationView(for: annotation, on: mapView)
        } else if let annotation = annotation as? FerryBuildingAnnotation {
            annotationView = setupFerryBuildingAnnotationView(for: annotation, on: mapView)
        }
        
        return annotationView
    }
    
    /// The map view asks `mapView(_:viewFor:)` for an appropiate annotation view for a specific annotation. The annotation
    /// should be configured as needed before returning it to the system for display.
    /// - Tag: ConfigureAnnotationViews
    private func setupSanFranciscoAnnotationView(for annotation: SanFranciscoAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let reuseIdentifier = NSStringFromClass(SanFranciscoAnnotation.self)
        let flagAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier, for: annotation)
        
        flagAnnotationView.canShowCallout = true
        
        // Provide the annotation view's image.
        let image = #imageLiteral(resourceName: "flag")
        flagAnnotationView.image = image
        
        // Provide the left image icon for the annotation.
        flagAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))
        
        // Offset the flag annotation so that the flag pole rests on the map coordinate.
        let offset = CGPoint(x: image.size.width / 2, y: -(image.size.height / 2) )
        flagAnnotationView.centerOffset = offset
        
        return flagAnnotationView
    }
    
    /// Create an annotation view for the Golden Gate Bridge, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    private func setupBridgeAnnotationView(for annotation: BridgeAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let identifier = NSStringFromClass(BridgeAnnotation.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = true
            markerAnnotationView.markerTintColor = UIColor(named: "internationalOrange")
            
            /*
             Add a detail disclosure button to the callout, which will open a new view controller or a popover.
             When the detail disclosure button is tapped, use mapView(_:annotationView:calloutAccessoryControlTapped:)
             to determine which annotation was tapped.
             If you need to handle additional UIControl events, such as `.touchUpOutside`, you can call
             `addTarget(_:action:for:)` on the button to add those events.
             */
            let rightButton = UIButton(type: .detailDisclosure)
            markerAnnotationView.rightCalloutAccessoryView = rightButton
        }
        
        return view
    }
    
    private func setupCustomAnnotationView(for annotation: CustomAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        return mapView.dequeueReusableAnnotationView(withIdentifier: NSStringFromClass(CustomAnnotation.self), for: annotation)
    }
    
    /// Create an annotation view for the Ferry Building, and add an image to the callout.
    /// - Tag: CalloutImage
    private func setupFerryBuildingAnnotationView(for annotation: FerryBuildingAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let identifier = NSStringFromClass(FerryBuildingAnnotation.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = true
            markerAnnotationView.markerTintColor = UIColor.red
            
            // Provide an image view to use as the accessory view's detail view.
            if (annotation.title != nil && myarray.contains(annotation.title!)) {
                let data = UserDefaults.standard.object(forKey: annotation.title!) as! String
                print(data)
                let imageDes = UIImage(data: Data(base64Encoded: data)!)
                markerAnnotationView.detailCalloutAccessoryView = UIImageView(image: imageDes)
            }
//            markerAnnotationView.detailCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "ferry_building"))
//            markerAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "conservatory_of_flowers"))
//            markerAnnotationView.rightCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "golden_gate"))
        }
        
        return view
    }

    @IBAction func tabkePhotoViewController(_ sender: UIButton) {
        
    }
    
    //MARK: - location delegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation :CLLocation = locations[0] as CLLocation

//        print("user latitude = \(userLocation.coordinate.latitude)")
//        print("user longitude = \(userLocation.coordinate.longitude)")

    //    self.labelLat.text = "\(userLocation.coordinate.latitude)"
    //    self.labelLongi.text = "\(userLocation.coordinate.longitude)"
//        print("\(userLocation.coordinate.latitude) ----- \(userLocation.coordinate.longitude)")

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(userLocation) { (placemarks, error) in
            if (error != nil){
                print("error in reverseGeocode - can not get location of device!")
            }
            var placemark: [CLPlacemark]!
            if placemarks != nil {
                placemark = placemarks! as [CLPlacemark]
            } else {
                print("loading location..")
                return
            }
            if placemark.count>0{
                let placemark = placemarks![0]
//                print(placemark.locality!)
//                print(placemark.administrativeArea!)
//                print(placemark.country!)
            }
        }
        

    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Service Error \(error)")
    }
    
}
