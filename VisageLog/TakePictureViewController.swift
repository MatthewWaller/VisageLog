//
//  ViewController.swift
//  VisageLog
//
//  Created by Matthew Waller on 3/18/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class TakePictureViewController: UIViewController, UINavigationControllerDelegate {
    

    var cameraIsAllowed = true
    var photoLibraryIsAllowed = true
    var imageToPass: UIImage?

    @IBOutlet weak var getImageButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getImageButton.layer.cornerRadius = 10
        
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { (granted) -> Void in
        if !granted {
            self.cameraIsAllowed = false
            self.pictureAccessAlert("Camera not available", message: "Please enable the camera for this app to take a picture")
                
        } else {
                self.cameraIsAllowed = true
        }
            
        }
        
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.Denied {
            self.photoLibraryIsAllowed = true
        } else {
            self.photoLibraryIsAllowed = false
            self.pictureAccessAlert("Photos not available", message: "Please enable photos to access")
        }
    }
    
    func pictureAccessAlert(title: String, message: String){
        
        let accessAlert = UIAlertController(title:title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let okAction = UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction!) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            })
        })
        
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel",comment:""), style: UIAlertActionStyle.Cancel, handler: { (alert: UIAlertAction) -> Void in
            
        })
        accessAlert.addAction(okAction)
        accessAlert.addAction(cancelAction)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(accessAlert, animated: true, completion: nil)
        })

        
    }


    @IBAction func getImage(sender: UIButton) {
        
        let imagePickerActionSheet = UIAlertController(title: "Snap/Upload Photo",
            message: nil, preferredStyle: .ActionSheet)
        
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let cameraButton = UIAlertAction(title: "Take Photo",
                style: .Default) { (alert) -> Void in
                    
                    if self.cameraIsAllowed == false {
                        
                        self.pictureAccessAlert("Camera not available", message: "Please enable the camera for this app to take a picture")
                        return
                        
                    }
                    
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .Camera
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.presentViewController(imagePicker,
                            animated: true,
                            completion: nil)
                    })
                    
                               }
            imagePickerActionSheet.addAction(cameraButton)
        }
        
        
        let libraryButton = UIAlertAction(title: "Choose Existing",
            style: .Default) { (alert) -> Void in
                
                if self.photoLibraryIsAllowed == false {
                    
                    self.pictureAccessAlert("Photos not available", message: "Please enable photos to access")
                    
                    return
                    
                }
                
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .PhotoLibrary
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.presentViewController(imagePicker,
                        animated: true,
                        completion: nil)
                })

        }
        imagePickerActionSheet.addAction(libraryButton)
        
        
        let cancelButton = UIAlertAction(title: "Cancel",
            style: .Cancel) { (alert) -> Void in
        }
        imagePickerActionSheet.addAction(cancelButton)
        
        
        presentViewController(imagePickerActionSheet, animated: true,
            completion: nil)

        
    }
    

    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let analyzingViewController = segue.destinationViewController as? AnalyzePhotoViewController {
            
            analyzingViewController.chosenImage = imageToPass
            
        }
        
    }

}

extension TakePictureViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {

            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                imageToPass = UIImage()
                imageToPass = pickedImage
                
                
            }
            
            performSegueWithIdentifier("photoSegue", sender: self)
            
            dismissViewControllerAnimated(true, completion: nil)
            
}
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
        dismissViewControllerAnimated(true, completion: nil)
        
    }

}