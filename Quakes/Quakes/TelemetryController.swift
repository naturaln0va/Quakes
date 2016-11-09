
import Foundation

class TelemetryController {
    
    static let sharedController = TelemetryController()
    
    let apiKey = "CSS95K93T2ZCHS3MNQWM"
    
    fileprivate enum EventName: String {
        case FetchSize
        case NearbyRadius
        case UnitStyle
        case SupportedApp
        case QuakeDetail
        case QuakeCity
        case QuakeOpen
        case QuakeShare
        case QuakeMap
        case QuakeMapFilter
        case QuakeFinderOpened
        case QuakeFinderSelected
    }
    
    func logFetchSizeChange(_ newSize: Int) {
        Flurry.logEvent(EventName.FetchSize.rawValue, withParameters: ["newSize": newSize])
    }
    
    func logNearbyRadiusChanged(_ newRadius: Int) {
        Flurry.logEvent(EventName.NearbyRadius.rawValue, withParameters: ["newRadius": newRadius])
    }
    
    func logUnitStyleToggled() {
        Flurry.logEvent(EventName.UnitStyle.rawValue)
    }
    
    func logSupportedApp() {
        Flurry.logEvent(EventName.SupportedApp.rawValue)
    }
    
    func logQuakeDetailViewed(_ weblinkString: String) {
        Flurry.logEvent(EventName.QuakeDetail.rawValue, withParameters: ["weblink": weblinkString])
    }
    
    func logQuakeCitiesViewed() {
        Flurry.logEvent(EventName.QuakeCity.rawValue)
    }
    
    func logQuakeOpenedInBrowser() {
        Flurry.logEvent(EventName.QuakeOpen.rawValue)
    }
    
    func logQuakeShare() {
        Flurry.logEvent(EventName.QuakeShare.rawValue)
    }
    
    func logQuakeMapOpened() {
        Flurry.logEvent(EventName.QuakeMap.rawValue)
    }
    
    func logQuakeMapFiltered() {
        Flurry.logEvent(EventName.QuakeMapFilter.rawValue)
    }
    
    func logQuakeFinderOpened() {
        Flurry.logEvent(EventName.QuakeFinderOpened.rawValue)
    }
    
    func logQuakeFinderDidSelectLocation(_ newLocation: String) {
        Flurry.logEvent(EventName.QuakeFinderSelected.rawValue, withParameters: ["newLocation": newLocation])
    }
    
}
