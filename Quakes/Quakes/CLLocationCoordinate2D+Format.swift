
import CoreLocation

extension CLLocationCoordinate2D {
    
    func formatedString() -> String {
        var resultingString = ""
        let coords = [self.latitude, self.longitude]
        
        for coord in coords {
            var seconds = Int(round(fabs(coord * 3600)))
            let degrees = seconds / 3600
            seconds %= 3600
            let minutes = seconds / 60
            seconds %= 60
            
            let cardinal: String
            let first: Bool = resultingString.characters.count == 0
            if first {
                cardinal = coord >= 0 ? "N" : "S"
            }
            else {
                cardinal = coord >= 0 ? "W" : "E"
            }
            resultingString += String(format: "%02i° %02i' %02i\" %@", degrees, minutes, seconds, cardinal)
            resultingString += (first ? ", " : "")
        }
        
        return resultingString
    }
    
}
