//
//  ViewController.swift
//  CoreML
//
//  Created by Patch Goyal on 9/23/19.
//  Copyright © 2019 Arkray. All rights reserved.
//


import CoreML
import UIKit


class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var foodClassifierLabel: UILabel!
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var purpleView: UIView!
    @IBOutlet weak var pinkView: UIView!
    @IBOutlet weak var greenView: UIView!
    
    
    var model: Food11Classifier!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view1.isHidden = true
        
        greenView.isHidden = true
        purpleView.isHidden = true
        pinkView.isHidden = true
        
        
            }
    
    
    override func viewWillAppear(_ animated: Bool) {
        model = Food11Classifier()
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
        foodClassifierLabel.text = "Analyzing Image..."
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
        
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        
        showDetailsView()
        foodClassifierLabel.text = "This is \(prediction.classLabel)."
        
    }
}


 

