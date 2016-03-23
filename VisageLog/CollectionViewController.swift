//
//  CollectionViewController.swift
//  VisageLog
//
//  Created by Matthew Waller on 3/22/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import UIKit
import CoreData



class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var selectedPhoto: Photo?
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    //MARK: lifecycle
    override func viewDidLoad() {
        
        do {
            try fetchedResultsController.performFetch()
        } catch _ as NSError {
            
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        
        let space: CGFloat = 8.0
        let spacingDimension = (view.frame.size.width - (3 * space)) / 2.0
        
        layout.minimumInteritemSpacing = space
        layout.minimumLineSpacing = space
        
        layout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        
        layout.itemSize = CGSize(width: spacingDimension, height: spacingDimension * 2)
        collectionView.collectionViewLayout = layout
    }
    
    //MARK: CollectionView setup
    
    func configureCell(cell: MoodCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
    
        if let imageFile = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
            
            let filename = imageFile.fileName
            let retrievedImage = CloudVisionClient.sharedInstance().getImage(filename!)
            
            cell.imageView.image = retrievedImage
    
            
            
            
            let feelingsArray = [imageFile.joyResponse, imageFile.angerResponse, imageFile.sorrowResponse, imageFile.surpriseResponse]
            
            var compactFeelings = [String]()
            
            for feeling in feelingsArray {
                
                let splitFeelingArray = feeling?.characters.split{$0 == ":"}.map(String.init)
                //from here http://stackoverflow.com/questions/25678373/swift-split-a-string-into-an-array
                
                let compactFeeling = splitFeelingArray![1]
                compactFeelings.append(compactFeeling)
                
            }
            
            cell.joyLabel.text = "Joy:\(compactFeelings[0])"
            cell.angerLabel.text = "Anger:\(compactFeelings[1])"
            cell.sorrowLabel.text = "Sorrow:\(compactFeelings[2])"
            cell.surpriseLabel.text = "Surprise:\(compactFeelings[3])"
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            let dateString = dateFormatter.stringFromDate(imageFile.creationDate!)
            cell.dateLabel.text = dateString
            
        }
    
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("moodCell", forIndexPath: indexPath) as! MoodCollectionViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        selectedPhoto = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo
        
        performSegueWithIdentifier("fromCollectionView", sender: self)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let analyzingViewController = segue.destinationViewController as? AnalyzePhotoViewController {
            
            analyzingViewController.photoToEdit = selectedPhoto
            
        }
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            
            break
        case .Move:
            
            break
            
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
                
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    

}