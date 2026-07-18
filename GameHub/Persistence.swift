//
//  Persistence.swift
//  sample1
//
//  Created by Pasindu Eranga on 2026-06-13.
//

internal import CoreData

// MARK: - Managed object subclass

@objc(HighScoreEntity)
class HighScoreEntity: NSManagedObject {
    @NSManaged var value: Int32
}

// MARK: - Core Data stack (programmatic model – no .xcdatamodeld file needed)

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        // Build the model entirely in code
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "HighScore"
        entity.managedObjectClassName = NSStringFromClass(HighScoreEntity.self)

        let attr = NSAttributeDescription()
        attr.name          = "value"
        attr.attributeType = .integer32AttributeType
        attr.defaultValue  = Int32(0)

        entity.properties = [attr]
        model.entities    = [entity]

        container = NSPersistentContainer(name: "TapFrenzy", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
