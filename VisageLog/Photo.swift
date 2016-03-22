//
//  Photo.swift
//  VisageLog
//
//  Created by Matthew Waller on 3/18/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import CoreData

class Photo: NSManagedObject {
    
    @NSManaged var creationDate: NSDate?
    @NSManaged var fileName: String?
    @NSManaged var joyResponse: String?
    @NSManaged var sorrowResponse: String?
    @NSManaged var angerResponse: String?
    @NSManaged var surpriseResponse: String?
    @NSManaged var myNote: String?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(fileName: String, creationDate: NSDate, joyResponse: String, angerResponse: String, sorrowResponse: String, surpriseResponse: String, myNote: String, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.creationDate = creationDate
        self.fileName = fileName
        self.joyResponse = joyResponse
        self.sorrowResponse = sorrowResponse
        self.angerResponse = angerResponse
        self.surpriseResponse = surpriseResponse
        self.myNote = myNote
        
    }
    
    override func prepareForDeletion() {
        let documentsDirectory = CloudVisionClient.sharedInstance().databaseURL()
        
        let fileURL = documentsDirectory?.URLByAppendingPathComponent(fileName!)
        
        do {
            try NSFileManager.defaultManager().removeItemAtURL(fileURL!)
        } catch {
            
        }
    }
    
    
}