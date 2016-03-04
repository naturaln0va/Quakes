
import Foundation
import MapKit

struct ParsedPolyQuake {
    
    let center: CLLocationCoordinate2D
    let points: [CLLocationCoordinate2D]
    
    var polygon: MKPolygon {
        let pointsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(points.count)
        for indexPoint in points.enumerate() {
            pointsPointer[indexPoint.index] = indexPoint.element
        }
        
        let polygonFromPoints = MKPolygon(coordinates: pointsPointer, count: points.count)
        pointsPointer.destroy()
        pointsPointer.dealloc(points.count)
        
        return polygonFromPoints
    }
}