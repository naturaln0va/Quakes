
import Foundation
import MapKit

struct ParsedPolyQuake {
    
    let center: CLLocationCoordinate2D
    let points: [CLLocationCoordinate2D]
    
    var polygon: MKPolygon {
        let pointsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: points.count)
        for indexPoint in points.enumerated() {
            pointsPointer[indexPoint.0] = indexPoint.element
        }
        
        let polygonFromPoints = MKPolygon(coordinates: pointsPointer, count: points.count)
        pointsPointer.deinitialize()
        pointsPointer.deallocate(capacity: points.count)
        
        return polygonFromPoints
    }
}
