
import MapKit

extension MKCoordinateRegion
{
    
    func mapRectForCoordinateRegion() -> MKMapRect {
        let pointA = MKMapPointForCoordinate(
            CLLocationCoordinate2D(
                latitude: center.latitude + span.latitudeDelta / 2,
                longitude: center.longitude - span.longitudeDelta / 2
            )
        )
        
        let pointB = MKMapPointForCoordinate(
            CLLocationCoordinate2D(
                latitude: center.latitude - span.latitudeDelta / 2,
                longitude: center.longitude + span.longitudeDelta / 2
            )
        )
        
        return MKMapRectMake(min(pointA.x, pointB.x), min(pointA.y, pointB.y), abs(pointA.x - pointB.x), abs(pointA.y - pointB.y))
    }
    
}