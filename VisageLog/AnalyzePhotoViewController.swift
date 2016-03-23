//
//  AnalyzePhotoViewController.swift
//  VisageLog
//
//  Created by Matthew Waller on 3/18/16.
//  Copyright © 2016 Matthew Waller. All rights reserved.
//

import Foundation
import UIKit

class AnalyzePhotoViewController: UIViewController, UITextFieldDelegate {
    
    var chosenImage: UIImage?
    var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var joyLabel: UILabel!
    @IBOutlet weak var sorrowLabel: UILabel!
    @IBOutlet weak var angerLabel: UILabel!
    @IBOutlet weak var surpriseLabel: UILabel!
    
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var faceImageView: UIImageView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var photoToEdit: Photo?
    
    override func viewDidLoad() {
        
        if photoToEdit != nil {
            
            faceImageView.image = CloudVisionClient.sharedInstance().getImage((photoToEdit?.fileName!)!)
            
            joyLabel.text = photoToEdit?.joyResponse
            angerLabel.text = photoToEdit?.angerResponse
            sorrowLabel.text = photoToEdit?.sorrowResponse
            surpriseLabel.text = photoToEdit?.surpriseResponse
            noteTextField.text = photoToEdit?.myNote
            
        } else {
        
            faceImageView.image = chosenImage

            addActivityIndicator()
            
            // Base64 encode the image and create the request
            let binaryImageData = CloudVisionClient.sharedInstance().base64EncodeImage(chosenImage!)
            CloudVisionClient.sharedInstance().createRequest(binaryImageData, completionHandler: { (result, error) -> Void in
            
            if error != nil {
                self.presentErrorAlert("Error from cloud: \(error?.localizedDescription)!")
                } else {
                
                    if result != nil {
                            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                            self.analyzeResults(result) //do this on main queue
                            
                            }
                    } else {
                        self.presentErrorAlert("No results found")
                    }
                }
            })
            
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        subscribeToKeyboardNotifications()
        noteTextField.delegate = self // must be here or the view will forget that the noteTextField should be the delegate
        navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        unsubscribeFromKeyboardNotifications()
    }
    
    func analyzeResults(resultsToParse: AnyObject) {
        
        removeActivityIndicator()
        
        if let errorObj = resultsToParse["error"] as? String {
            presentErrorAlert("There was an error in analyzing results: \(errorObj)")
            
        } else {
            
            guard let responses = resultsToParse["responses"] as? [[String: AnyObject]] else {
                
                presentErrorAlert("Didn't get responses from server")
                
                return
                
            }
        
            guard let faceAnnotations = responses[0] as [String: AnyObject]? else {
                presentErrorAlert("Didn't get responses from server")
                
                return
            }
            
            if faceAnnotations.isEmpty {
                presentErrorAlert("Didn't get facial analysis from server")
                
                return
            }
            
            let theFaceAnnotations = faceAnnotations["faceAnnotations"]
            
            let drilledDownFaceAnnotations = theFaceAnnotations![0]
            
            let joyLikelihood = drilledDownFaceAnnotations["joyLikelihood"]
            
            joyLabel.text = "\(joyLabel.text!) \(resultTranslator(joyLikelihood as! String))"
            
            let angerLikelihood = drilledDownFaceAnnotations["angerLikelihood"]
            
            angerLabel.text = "\(angerLabel.text!) \(resultTranslator(angerLikelihood as! String))"
            
            let surpriseLikelihood = drilledDownFaceAnnotations["surpriseLikelihood"]
            
            surpriseLabel.text = "\(surpriseLabel.text!) \(resultTranslator(surpriseLikelihood as! String))"
            
            let sorrowLikelihood = drilledDownFaceAnnotations["sorrowLikelihood"]
            
            sorrowLabel.text = "\(sorrowLabel.text!) \(resultTranslator(sorrowLikelihood as! String))"
        }
        
    }
    
    func resultTranslator(result: String) -> String {
        
        switch result {
            
        case "UNKNOWN":
            return "Unknown"
            
        case "VERY_UNLIKELY":
            
            return "Very unlikely"
        case "UNLIKELY":
            return "Unlikely"
         
        case "POSSIBLE":
            return "Possible"
            
        case "LIKELY":
            return "Likely"
            
        case "VERY_LIKELY":
            return "Very likely"
            
        default:
            return "Unknown"
            
        }
        
    }
    
    func addActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: view.bounds)
        activityIndicator.activityIndicatorViewStyle = .WhiteLarge
        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
    
    func removeActivityIndicator() {
        activityIndicator.removeFromSuperview()
        activityIndicator = nil
    }

    
    @IBAction func saveImage(sender: UIBarButtonItem) {
        
        if photoToEdit != nil {
            
            photoToEdit?.myNote = noteTextField.text!
            
            CoreDataStackManager.sharedInstance().saveContext()
            
        } else {
        
            let cloudResponses = ["joyString": joyLabel.text!, "angerString": angerLabel.text!, "surpriseString": surpriseLabel.text!, "sorrowString": sorrowLabel.text!]
            CloudVisionClient.sharedInstance().savePhotoAndResponse(faceImageView.image!, cloudResponse: cloudResponses, myNote: noteTextField.text!)
        }
         navigationController?.popViewControllerAnimated(true) 
    }
    
    
    @IBAction func shareAction(sender: UIBarButtonItem) {
        
        let sharingImage = generateShareImage()
        let activityController = UIActivityViewController(activityItems: [sharingImage], applicationActivities: nil)
        activityController.completionWithItemsHandler = { activity, success, items, error in
           
        } // completion handler code sample from http://stackoverflow.com/questions/27454467/uiactivityviewcontroller-uiactivityviewcontrollercompletionwithitemshandler
        presentViewController(activityController, animated: true, completion: nil)

        
    }
    
    func generateShareImage() -> UIImage {
 
        toolbar.hidden = true
        
        if ((noteTextField.text?.isEmpty) != nil) {
            noteTextField.hidden = true
        }
        
        UIGraphicsBeginImageContext(view.frame.size)
        view.drawViewHierarchyInRect(view.frame,
            afterScreenUpdates: true)
        let shareImage : UIImage =
        UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        toolbar.hidden = false
        noteTextField.hidden = false
        
        return shareImage
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true // so that it doesn't show up when saving the image
    }
    
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        
        navigationController?.popViewControllerAnimated(true) //I segue here with push instead of modal to avoid seeing a transition from the imagePickerViewController
        
    }
    
    func presentErrorAlert(alertText: String){
        
        let errorAlert = UIAlertController(title: "Analysis Failure", message: alertText, preferredStyle: .Alert)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil)
        
        errorAlert.addAction(dismissAction)
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.presentViewController(errorAlert, animated: true, completion: nil)
            if self.activityIndicator != nil {
            self.removeActivityIndicator()
            }
        }
        
    }

    
    //MARK: Keyboard things
    
    var keyboardIsExternal = false
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        textField.text = ""
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        let userInfo = notification.userInfo
        let keyboardFrame = (userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboard = view.convertRect(keyboardFrame, fromView: view.window)
        
        if keyboard.origin.y + keyboard.size.height > view.frame.size.height { //help from here http://stackoverflow.com/questions/31991873/how-to-reliably-detect-if-an-external-keyboard-is-connected-on-ios-9
            
            keyboardIsExternal = true
            
        } else {
            
            keyboardIsExternal = false
        }
        
        if keyboardIsExternal == false {
        
            view.frame.origin.y -= keyboardFrame.height
            
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        view.frame.origin.y = 0 //getKeyboardHeight(notification)

    }
    
    func subscribeToKeyboardNotifications(){
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name:
            UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:
            UIKeyboardWillHideNotification, object: nil)
    }

    
}