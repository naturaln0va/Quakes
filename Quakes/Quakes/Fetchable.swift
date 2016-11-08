
import CoreData


protocol Fetchable {
    associatedtype FetchableType: NSManagedObject
    
    static func entityName() -> String
    static func objectsInContext(_ context: NSManagedObjectContext, predicate: NSPredicate?, sortedBy: String?, ascending: Bool) throws -> [FetchableType]
    static func singleObjectInContext(_ context: NSManagedObjectContext, predicate: NSPredicate?, sortedBy: String?, ascending: Bool) throws -> FetchableType?
    static func objectCountInContext(_ context: NSManagedObjectContext, predicate: NSPredicate?) -> Int
    static func fetchRequest(_ context: NSManagedObjectContext, predicate: NSPredicate?, sortedBy: String?, ascending: Bool) -> NSFetchRequest<NSFetchRequestResult>
}

extension Fetchable where Self: NSManagedObject, FetchableType == Self
{
    
    static func singleObjectInContext(_ context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortedBy: String? = nil, ascending: Bool = false) throws -> FetchableType?
    {
        let managedObjects: [FetchableType] = try objectsInContext(context, predicate: predicate, sortedBy: sortedBy, ascending: ascending)
        guard managedObjects.count > 0 else { return nil }
        
        return managedObjects.first
    }
    
    static func objectCountInContext(_ context: NSManagedObjectContext, predicate: NSPredicate? = nil) -> Int {
        let request = fetchRequest(context, predicate: predicate)
        return try! context.count(for: request)
    }
    
    static func objectsInContext(_ context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortedBy: String? = nil, ascending: Bool = false) throws -> [FetchableType]
    {
        let request = fetchRequest(context, predicate: predicate, sortedBy: sortedBy, ascending: ascending)
        let fetchResults = try context.fetch(request)
        
        guard let results = fetchResults as? [FetchableType] else {
            fatalError("Fetch results were not of type 'FetchableType'.")
        }
        
        return results
    }
    
    static func fetchRequest(_ context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortedBy: String? = nil, ascending: Bool = false) -> NSFetchRequest<NSFetchRequestResult>
    {
        let request = NSFetchRequest<NSFetchRequestResult>()
        let entity = NSEntityDescription.entity(forEntityName: entityName(), in: context)
        request.entity = entity
        
        if predicate != nil {
            request.predicate = predicate
        }
        
        if sortedBy != nil {
            let sort = NSSortDescriptor(key: sortedBy, ascending: ascending)
            let sortDescriptors = [sort]
            request.sortDescriptors = sortDescriptors
        }
        
        return request
    }
    
}
