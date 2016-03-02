
import UIKit
import CoreData
import CoreLocation

class PersistentController
{
    
    static let sharedController = PersistentController()
    private static let contextName = "Quakes"
    
    // MARK: - Managed Object Context
    lazy var moc: NSManagedObjectContext = {
        guard let modelURL = NSBundle.mainBundle().URLForResource(contextName, withExtension: "momd") else {
            fatalError("Could not find the data model in the bundle")
        }
        
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("error initializing model from: \(modelURL)")
        }
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.URLByAppendingPathComponent("\(contextName).sqlite")
        
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                configuration: nil,
                URL: storeURL,
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
            
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
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
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("\nError saving the managed object context: \(error)\n\n")
                }
            }
        }
    }
    
    func attemptCleanup() {
        guard SettingsController.sharedController.lastLocationOption != LocationOption.Major.rawValue ||
            SettingsController.sharedController.lastLocationOption != LocationOption.World.rawValue else {
                return
        }
        
        let maxQuakesToStore = SettingsController.sharedController.fetchLimit.rawValue
        
        if let quakes = try? Quake.objectsInContext(moc, predicate: nil, sortedBy: "timestamp", ascending: false) {
            var quakesCopy = quakes
            while quakesCopy.count > maxQuakesToStore {
                if let lastQuake = quakes.last {
                    moc.deleteObject(lastQuake)
                    quakesCopy.removeLast()
                }
            }
            
            var locationOption: CLLocation?
            if let nearbyLocation = SettingsController.sharedController.cachedAddress?.location {
                locationOption = nearbyLocation
            }
            else if let searchedLocation = SettingsController.sharedController.lastSearchedPlace?.location {
                locationOption = searchedLocation
            }
            
            if let location = locationOption {
                let radius = SettingsController.sharedController.searchRadius.rawValue
                
                for quake in quakesCopy {
                    if quake.location.distanceFromLocation(location) > (Double(radius) * 1000) {
                        moc.deleteObject(quake)
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
            moc.deleteObject(quake)
        }
        
        attemptSave()
    }
    
    func deleteQuake(quakeToDelete: Quake) {
        moc.deleteObject(quakeToDelete)
        
        attemptSave()
    }
    
    func updateQuakeWithID(identifier: String, withNearbyCities cities: [ParsedNearbyCity]?, withCountry country: String?) {
        do {
            if let quakeToUpdate = try Quake.singleObjectInContext(moc, predicate: NSPredicate(format: "identifier == %@", identifier), sortedBy: nil, ascending: false) {
                if let cities = cities {
                    let data = NSKeyedArchiver.archivedDataWithRootObject(cities)
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
    
    func deleteAllThenSaveQuakes(parsedQuakes: [ParsedQuake]) {
        guard let allQuakes = try? Quake.objectsInContext(moc) else {
            print("Failed to fetch all the quakes to delete")
            return
        }
        
        for quake in allQuakes {
            moc.deleteObject(quake)
        }
        
        saveQuakes(parsedQuakes)
    }
    
    func saveQuakes(parsedQuake: [ParsedQuake]) {
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
            
            guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(Quake.entityName(), inManagedObjectContext: moc) as? Quake else {
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
            dataToSave.distance = quake.distance
            dataToSave.felt = quake.felt
        }
        
        attemptCleanup()
        attemptSave()
    }
    
}