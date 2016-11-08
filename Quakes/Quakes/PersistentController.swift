
import UIKit
import CoreData
import CoreLocation

class PersistentController
{
    
    static let sharedController = PersistentController()
    fileprivate static let contextName = "Quakes"
    
    // MARK: - Managed Object Context
    lazy var moc: NSManagedObjectContext = {
        guard let modelURL = Bundle.main.url(forResource: contextName, withExtension: "momd") else {
            fatalError("Could not find the data model in the bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("error initializing model from: \(modelURL)")
        }
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.appendingPathComponent("\(contextName).sqlite")
        
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
            
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
        }
            
        catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
    }()
    
    // MARK: - Helpers
    func attemptSave() {
        if moc.hasChanges {
            do {
                try self.moc.save()
            }
                
            catch {
                fatalError("\nError saving the managed object context: \(error)\n\n")
            }
        }
    }
    
    func attemptCleanup() {
        let maxQuakesToStore = SettingsController.sharedController.fetchLimit.rawValue
        
        if let quakes = try? Quake.objectsInContext(moc, predicate: nil, sortedBy: "timestamp", ascending: false) {
            var quakesCopy = quakes
            
            for quake in quakesCopy {
                if quake.timestamp.isMoreThanAMonthOld() {
                    moc.delete(quake)
                    quakesCopy.removeLast()
                }
            }
            
            while quakesCopy.count > maxQuakesToStore {
                if let lastQuake = quakes.last {
                    moc.delete(lastQuake)
                    quakesCopy.removeLast()
                }
            }
            
            if SettingsController.sharedController.isLocationOptionWorldOrMajor() {
                return
            }
            
            var locationOption: CLLocation?
            if let nearbyLocation = SettingsController.sharedController.cachedAddress?.location, SettingsController.sharedController.lastLocationOption == LocationOption.Nearby.rawValue {
                locationOption = nearbyLocation
            }
            else if let searchedLocation = SettingsController.sharedController.lastSearchedPlace?.location {
                locationOption = searchedLocation
            }
            
            if let location = locationOption {
                let radius = SettingsController.sharedController.searchRadius.rawValue
                
                for quake in quakesCopy {
                    if quake.location.distance(from: location) > (Double(radius) * 1000) {
                        moc.delete(quake)
                    }
                }
            }
        }
        else {
            print("Failed to read quakes from the database.")
        }
    }
    
    // MARK: - Quake Management
    func deleteAllQuakes() {
        guard let allQuakes = try? Quake.objectsInContext(moc) else {
            print("Failed to fetch all the quakes to delete")
            return
        }
        
        for quake in allQuakes {
            moc.delete(quake)
        }
        
        attemptSave()
    }
    
    func deleteQuake(_ quakeToDelete: Quake) {
        moc.delete(quakeToDelete)
        
        attemptSave()
    }
    
    func updateQuakeWithID(_ identifier: String, withNearbyCities cities: [ParsedNearbyCity]?, withCountry country: String?) {
        do {
            if let quakeToUpdate = try Quake.singleObjectInContext(moc, predicate: NSPredicate(format: "identifier == %@", identifier), sortedBy: nil, ascending: false) {
                if let cities = cities {
                    let data = NSKeyedArchiver.archivedData(withRootObject: cities)
                    quakeToUpdate.nearbyCitiesData = data
                }
                quakeToUpdate.countryCode = country ?? nil
            }
        }
        
        catch {
            print("Error updating quake with id: \(identifier), error: \(error)")
            return
        }
        
        attemptSave()
    }
    
    func deleteAllThenSaveQuakes(_ parsedQuakes: [ParsedQuake]) {
        guard let allQuakes = try? Quake.objectsInContext(moc) else {
            print("Failed to fetch all the quakes to delete")
            return
        }
        
        for quake in allQuakes {
            moc.delete(quake)
        }
        
        saveQuakes(parsedQuakes)
    }
    
    func saveQuakes(_ parsedQuake: [ParsedQuake]) {
        for quake in parsedQuake {
            do {
                if let savedQuake = try Quake.singleObjectInContext(moc, predicate: NSPredicate(format: "identifier == %@", quake.identifier), sortedBy: nil, ascending: false) {
                    
                    if savedQuake.felt == quake.felt {
                        continue
                    }
                    else {
                        savedQuake.felt = quake.felt
                        continue
                    }
                }
            }
                
            catch {
                print("Failed to get a single object from the managed context.")
            }
            
            guard let dataToSave = NSEntityDescription.insertNewObject(forEntityName: Quake.entityName(), into: moc) as? Quake else {
                fatalError("Expected to insert and entity of type 'Quake'.")
            }
            
            dataToSave.timestamp = quake.date
            dataToSave.depth = quake.depth
            dataToSave.weblink = quake.link
            dataToSave.name = quake.name
            dataToSave.magnitude = quake.magnitude
            dataToSave.latitude = quake.latitude
            dataToSave.longitude = quake.longitude
            dataToSave.identifier = quake.identifier
            dataToSave.detailURL = quake.detailURL
            dataToSave.distance = quake.distance as NSNumber?
            dataToSave.felt = quake.felt
        }
        
        attemptSave()
    }
    
}
