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
    
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    var sfwLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    var nsfwLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    //MARK: - Lifecycles
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapSelectImage))
        button.tintColor = .blue
        navigationItem.rightBarButtonItem = button
        let stackView = UIStackView(arrangedSubviews: [sfwLabel, nsfwLabel])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -30),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -120),
            stackView.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "SFW / NSFW"
    }
    
    private func userSelectedPhoto(image: UIImage) {
        predictor.makePredictions(for: image) { [weak self] predictions in
            DispatchQueue.main.async {
                guard let self = self,
                      let nsfw = predictions?.first(where: {$0.category == .censored}),
                      let sfw = predictions?.first(where: {$0.category == .safe})
                else { return }
                var imageToShow: UIImage? = image
                if nsfw.confidence > sfw.confidence {
                    imageToShow = self.blurImage(image: image, amount: 30)
                }
                self.imageView.image = imageToShow
                self.sfwLabel.text = "SFW: \(sfw.confidence.description) confidence"
                self.nsfwLabel.text = "NSFW: \(nsfw.confidence.description) confidence"
            }
        }
    }
    private func blurImage(image input: UIImage, amount: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: input), let blurEffect = CIFilter(name: "CIGaussianBlur") else { return nil }
        
        blurEffect.setValue(ciImage, forKey: kCIInputImageKey)
        blurEffect.setValue(amount, forKey: kCIInputRadiusKey)
        
        guard let output = blurEffect.outputImage else { return nil }
        
        return UIImage(ciImage: output)
    }
    private func clearViews() {
        imageView.image = nil
        nsfwLabel.text = nil
        sfwLabel.text = nil
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
                    DispatchQueue.main.async {
                        self.clearViews()
                    }
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
