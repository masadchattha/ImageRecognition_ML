//
//  ViewController.swift
//  ImageRecognition_ML
//
//  Created by Muhammad Asad Chattha on 06/02/2022.
//

import UIKit
import PhotosUI
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!

    let unsplashAccessKey = "3bOT-lTr3T3MN2voXBYIPuljOe5vvZ8SE5OQT_wVSd4"
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ImagePicker
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //Get captured image and use it
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = userPickedImage
            
            let ciimage = ciimageConverter(userPickedImage)
            detect(image: ciimage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - IBActions
    
    //Called when camera icon pressed
    @IBAction func presentPicker(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    //Called when Gallery icon pressed
    @IBAction func presentPhotoPicker(_ sender: UIBarButtonItem) {
        //PHPicker
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }


    // MARK: - Perform CoreML

    private func detect(image: CIImage) {
        //MLModelConfiguration is required for latest verions
        let mlmodelconfiguration = MLModelConfiguration()
        //Initialize mlmodel with Vision CoreML coz our model is vision based
        guard let model = try? VNCoreMLModel(for: Inceptionv3(configuration: mlmodelconfiguration).model) else {
            fatalError("Loading CoreML Model Failed.")
        }

        //Prepare Request using VNCoreMLRequest - CoreML's vision request
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else { fatalError("Model failed to process Image.") }

            let highestConfidenceObservation = self.findHighestConfidenceObservation(from: results)
            let identifier = highestConfidenceObservation?.identifier
            self.navigationItem.title = identifier
            self.fetchAndDisplayImage(for: identifier ?? "place holder image")
        }
        
        //Perform ML request
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    //UIImage to CIImage Converter
    private func ciimageConverter(_ selectedImage: UIImage) -> CIImage {
        guard let ciimage = CIImage(image: selectedImage) else {
            fatalError("Couldn't Convert UIImage to CIImage")
        }
        
        return ciimage
    }

    // Assume observations is your array of VNClassificationObservation objects
    func findHighestConfidenceObservation(from observations: [VNClassificationObservation]) -> VNClassificationObservation? {
        // Use max(by:) to find the observation with the highest confidence
        return observations.max(by: { $0.confidence < $1.confidence })
    }

    func fetchAndDisplayImage(for query: String) {
        Task {
            guard let image = await fetchRandomImage(for: query) else { return }
            DispatchQueue.main.async { self.imageView.image = image }
        }
    }
}


// MARK: - PHPickerViewControllerDelegate

extension ViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // The client is responsible for presentation and dismissal
        dismiss(animated: true)
        
        // Get the first item provider from the results, the configuration only allowed one image to be selected
        if let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            let previousImage = imageView.image
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                
                //Update UI from background thread to main thread
                DispatchQueue.main.async {
                    guard let self = self, let image = image as? UIImage, self.imageView.image == previousImage else { return }
                    self.imageView.image = image
                    
                    let ciimage = self.ciimageConverter(image)
                    self.detect(image: ciimage)
                }
            }
        }
    }
}


// MARK: - Unsplsh image search

extension ViewController {

    func fetchRandomImage(for query: String) async -> UIImage? {
        let urlString = "https://api.unsplash.com/photos/random?query=\(query)&client_id=\(unsplashAccessKey)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let urls = json["urls"] as? [String: Any],
               let imageUrlString = urls["regular"] as? String,
               let imageUrl = URL(string: imageUrlString) {

                // Fetch the image data from the image URL
                let (imageData, _) = try await URLSession.shared.data(from: imageUrl)
                return UIImage(data: imageData)
            }
        } catch {
            print("Error fetching or parsing image: \(error.localizedDescription)")
        }

        return nil
    }
}
