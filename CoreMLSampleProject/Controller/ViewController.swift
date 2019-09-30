//
//  ViewController.swift
//  CoreML
//
//  Created by Patch Goyal on 9/23/19.
//  Copyright © 2019 Arkray. All rights reserved.
//


import CoreML
import UIKit
import Vision


class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var foodClassifierLabel: UILabel!
    
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var purpleView: UIView!
    @IBOutlet weak var pinkView: UIView!
    @IBOutlet weak var greenView: UIView!
    
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view1.isHidden = true
        
        greenView.isHidden = true
        purpleView.isHidden = true
        pinkView.isHidden = true
        
    }
    
  
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: JapFoodClassifier().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
                                self.processClassications(for: request, error: error)
               

            })
            
            request.imageCropAndScaleOption = .centerCrop
            
            return request
        } catch {
            fatalError("failed to load Core ML Model:\(error)")
        }
        
    }()
    
    func processClassications(for request: VNRequest, error: Error?) {
        showDetailsView()
        guard let classifications = request.results as? [VNClassificationObservation] else {
            self.foodClassifierLabel.text = "Unable to classify image. \n\(error?.localizedDescription ?? "Error")"
            return
        }
        
        if classifications.isEmpty {
            self.foodClassifierLabel.text = "Nothing recognized.\nPlease try again."
            
        } else {
            let topClassifications = classifications.prefix(2)
            let descriptions = topClassifications.map {
                classification in return String(format: "%.2f", classification.confidence * 100) + "% - " + classification.identifier
            }
            
           
            self.foodClassifierLabel.text = "Classification: \n" + descriptions.joined(separator: "\n")
            
            
        }
    }
    
    func updateClassification(for image: UIImage) {
        
        foodClassifierLabel.text = "Classifying...."
        
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)), let ciImage = CIImage(image: image) else {
            print("Something went wrong...\nPlease try again")
            return
        }
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        
        do {
            
            try handler.perform([classificationRequest])
            
        } catch {
            print("Failed to perform classification: \(error.localizedDescription)")
            
        }
    }
    
    
    
    


    
    @IBAction func cameraTapped(_ sender: Any) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        
        present(cameraPicker, animated: true)
        
    }
    
    
    
    @IBAction func openLibraryTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    //MARK: FUNCTION
    
    func showDetailsView() {
        view1.layer.shadowColor = UIColor.black.cgColor
        view1.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        view1.layer.shadowRadius = 1.0
        view1.layer.shadowOpacity = 70
        view1.layer.cornerRadius = 15.0
        view1.isHidden = false
        
      //colored View
        greenView.layer.cornerRadius = 15.0
        greenView.isHidden = false
       
        pinkView.layer.cornerRadius = 15.0
        pinkView.isHidden = false
        
        purpleView.layer.cornerRadius = 15.0
        purpleView.isHidden = false

    }
    

    
}


extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
            
            
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        cameraImageView.image = newImage
        
        showDetailsView()
        updateClassification(for: newImage)
    
        
    }
}


 

