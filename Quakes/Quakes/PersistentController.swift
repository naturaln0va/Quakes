
import UIKit
import CoreData
import CoreLocation

typealias NewQuakeCountCompletionBlock = (newCount: Int) -> Void

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
        saveQuakes(parsedQuake, completion: nil)
    }
    
    func saveQuakes(parsedQuake: [ParsedQuake], completion: NewQuakeCountCompletionBlock?) {
        var newQuakeCount = 0
        for quake in parsedQuake {
            do {
                if let _ = try Quake.singleObjectInContext(moc, predicate: NSPredicate(format: "identifier == %@", quake.identifier), sortedBy: nil, ascending: false) {
                    continue
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
            
            newQuakeCount++
        }
        
        attemptSave()
        
        if let completion = completion {
            completion(newCount: newQuakeCount)
        }
    }
    
}