
import UIKit
import CoreData
import CoreLocation


class PersistentController
{
    
    static let sharedController = PersistentController()
    private static let contextName = "Quakes"
    
    // MARK: - Current Models
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
    
    // MARK: - Quake Management
    func deleteQuake(quakeToDelete: Quake)
    {
        moc.deleteObject(quakeToDelete)
        
        if moc.hasChanges {
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("Error deleting quake: \(error)")
                }
            }
        }
    }
    
    func saveQuake(parsedQuake: ParsedQuake)
    {
        do {
            if let _ = try Quake.singleObjectInContext(moc, predicate: NSPredicate(format: "identifier == %@", parsedQuake.identifier), sortedBy: nil, ascending: false) {
                return
            }
        }
        
        catch {
            print("Failed to get a single object from the managed context.")
        }
        
        guard let dataToSave = NSEntityDescription.insertNewObjectForEntityForName(Quake.entityName(), inManagedObjectContext: moc) as? Quake else {
            fatalError("Expected to insert and entity of type 'Quake'.")
        }
        
        dataToSave.timestamp = parsedQuake.date
        dataToSave.depth = parsedQuake.depth
        dataToSave.weblink = parsedQuake.link
        dataToSave.name = parsedQuake.name
        dataToSave.magnitude = parsedQuake.magnitude
        dataToSave.latitude = parsedQuake.latitude
        dataToSave.longitude = parsedQuake.longitude
        dataToSave.identifier = parsedQuake.identifier
        
        if moc.hasChanges {
            moc.performBlockAndWait { [unowned self] in
                do {
                    try self.moc.save()
                }
                    
                catch {
                    fatalError("Error saving quake: \(error)")
                }
            }
        }
    }
    
}