/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The custom MKAnnotation object representing the Ferry Building.
*/

import MapKit

class FerryBuildingAnnotation: NSObject, MKAnnotation {

    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
//    @objc dynamic var coordinate = CLLocationCoordinate2D(latitude: 21.795_316, longitude: 105.393_760)
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(_ latitude: CLLocationDegrees,_ longitude: CLLocationDegrees,_ img: String) {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.title = NSLocalizedString(img, comment: "Ferry Building annotation")
    }
    
//    var title: String? = NSLocalizedString("FERRY_BUILDING_TITLE", comment: "Ferry Building annotation")
}
