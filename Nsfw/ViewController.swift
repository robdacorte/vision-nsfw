//
//  ViewController.swift
//  Nsfw
//
//  Created by Rob on 15/10/22.
//

import UIKit
import PhotosUI

class ViewController: UIViewController {

    //MARK: - Properties
    
    lazy var photoPicker: PHPickerViewController = {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images
        
        let photoPicker = PHPickerViewController(configuration: config)
        photoPicker.delegate = self
        return photoPicker
    }()
    
    let predictor: ImagePredictor = ImagePredictor()
    
    //MARK: - Lifecycles
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapSelectImage))
        button.tintColor = .blue
        navigationItem.rightBarButtonItem = button
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "SFW / NSFW"
    }
    
    private func userSelectedPhoto(image: UIImage) {
        predictor.makePredictions(for: image) { _ in
            
        }
    }
    
    @objc
    private func didTapSelectImage() {
        present(photoPicker, animated: true)
    }
}


extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        //Workaround for a 2 years old bug
        let supportedRepresentations = [UTType.rawImage.identifier,
                                        UTType.tiff.identifier,
                                        UTType.bmp.identifier,
                                        UTType.png.identifier,
                                        UTType.heif.identifier,
                                        UTType.heic.identifier,
                                        UTType.jpeg.identifier,
                                        UTType.webP.identifier,
                                        UTType.gif.identifier,
        ]
        
        picker.dismiss(animated: false)
        guard let result = results.first else { return }
        for representation in supportedRepresentations {
            if result.itemProvider.hasRepresentationConforming(toTypeIdentifier: representation) {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: representation) { url, error in
                    if let _ = error { return }
                    guard let url else { return }
                    do {
                        guard let image = UIImage(data: try Data(contentsOf: url)) else { return }
                        self.userSelectedPhoto(image: image)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}
