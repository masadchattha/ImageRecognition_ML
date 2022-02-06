//
//  ViewController.swift
//  ImageRecognition_ML
//
//  Created by Muhammad Asad Chattha on 06/02/2022.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - UIView Objects
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ImagePicker
        imagePicker.delegate = self
        //Pick Image from Camera
//        imagePicker.sourceType = .camera
        //Pick Image from Photos
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //Get captured image and use it
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = userPickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - IBActions

    @IBAction func presentPicker(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    

}

