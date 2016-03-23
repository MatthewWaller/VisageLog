//
//  CloudVisionClient.swift
//  VisageLog
//
//  Created by Matthew Waller on 3/18/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CloudVisionClient {
    
    let API_KEY = "AIzaSyBUia5AchKJEBiFqIPCYyNsZ_zY1UhCHoY"
    
    func createRequest(imageData: String, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        // Create our request URL
        let request = NSMutableURLRequest(URL: NSURL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(API_KEY)")!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build our API request
        let jsonRequest: [String: AnyObject] = [
            "requests": [
                "image": [
                    "content": imageData
                ],
                "features": [
                    [
                        "type": "FACE_DETECTION",
                        "maxResults": 30
                    ]
                ]
            ]
        ]
        
        // Serialize the JSON
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(jsonRequest, options: [])
        
        // Run the request on a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.runRequestOnBackgroundThread(request, completionHandler: { (result, error) -> Void in
                completionHandler(result: result, error: error) //this sends it back to the viewController
            })
        });
        
    }
    
    func runRequestOnBackgroundThread(request: NSMutableURLRequest, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        let session = NSURLSession.sharedSession()
        
        // run the request
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            if error == nil {
            
                CloudVisionClient.parseJSONWithCompletionHandler(data!, completionHandler: { (result, error) -> Void in
                    
                    completionHandler(result: result, error: error) // this sends it back to create request
                })
            } else {
                completionHandler(result: nil, error: error)
            }
        })
            
        task.resume()
    }
    
    func base64EncodeImage(image: UIImage) -> String {
        var imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 2MB API limit
        if (imagedata?.length > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSizeMake(800, oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedStringWithOptions(.EncodingEndLineWithCarriageReturn)
    }
    
    func base64DecodeImage(base64String: String) -> UIImage {
        
        let decodedData = NSData(base64EncodedString: base64String, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
        let theImage = UIImage(data: decodedData!)
        
        return theImage!
    }
    
    func resizeImage(imageSize: CGSize, image: UIImage) -> NSData {
        UIGraphicsBeginImageContext(imageSize)
        image.drawInRect(CGRectMake(0, 0, imageSize.width, imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func savePhotoAndResponse(imageToSave: UIImage, cloudResponse: [String:String], myNote: String){
        
        let creationDate = NSDate()
        let dateFormatter = NSDateFormatter() //help from here http://www.codingexplorer.com/swiftly-getting-human-readable-date-nsdateformatter/
        
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .MediumStyle
        let dateString = dateFormatter.stringFromDate(creationDate)
        let dateStringFilename = "\(dateString).png"
        
        let documentsDirectoryURL = databaseURL()
        var fileURL = documentsDirectoryURL?.URLByAppendingPathComponent(dateStringFilename)
        
        while NSFileManager.defaultManager().fileExistsAtPath((fileURL?.path)!) {
            
            let urlWithoutExtension = fileURL?.URLByDeletingPathExtension
            let oldFileName = urlWithoutExtension?.lastPathComponent
            
            print("lastFileName")
            
            let newFileName = "\(oldFileName)1.png"
            
            let urlWithoutLastPathComponent = fileURL?.URLByDeletingLastPathComponent
            
            fileURL = urlWithoutLastPathComponent?.URLByAppendingPathComponent(newFileName)
                
            //in case the user changes the time on the phone, make sure the path is different
        }
        
        let fileName = fileURL?.lastPathComponent
        
        let reorientedImage = imageToSave.rotateImageByOrientation()
        
        if let imageData = UIImagePNGRepresentation(reorientedImage) {
            
            imageData.writeToURL(fileURL!, atomically: true)
            
        }
        
        print(cloudResponse["joyString"])
        
        _ = Photo(fileName: fileName!, creationDate: creationDate,
            joyResponse: cloudResponse["joyString"]!,
            angerResponse: cloudResponse["angerString"]!,
            sorrowResponse: cloudResponse["sorrowString"]!,
            surpriseResponse: cloudResponse["surpriseString"]!,
            myNote: myNote, context: sharedContext)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        
    }
    
    func getImage(fileName: String) -> UIImage {
        
        let filename = fileName
        let documentsDirectory = databaseURL()
        let fileURL = documentsDirectory?.URLByAppendingPathComponent(filename)
        var retrievedImage = UIImage()
        if let retrievedImageData = NSData(contentsOfFile: (fileURL?.path)!) {
            
            retrievedImage = UIImage(data: retrievedImageData)!
            
        }
        
        return retrievedImage
    }
    
    // MARK: Helpers
    
    class func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        if parsedResult != nil {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
        
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    
    
    func databaseURL() -> NSURL? {
        
        let fileManager = NSFileManager.defaultManager()
        
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        if let documentDirectory = urls.first {
            return documentDirectory
        }
        
        
        return nil
    }

    // MARK: Shared Instance
    
    class func sharedInstance() -> CloudVisionClient {
        
        struct Singleton {
            static var sharedInstance = CloudVisionClient()
        }
        
        return Singleton.sharedInstance
    }

}