//
//  ImagePredictor.swift
//  Nsfw
//
//  Created by Rob on 15/10/22.
//

import Foundation
import Vision
import UIKit

enum Category: String {
    case safe = "SFW"
    case censored = "NSFW"
}

final class ImagePredictor {
    
    //MARK: - Properties
    private var imageClassifier: VNCoreMLModel = {
        let config = MLModelConfiguration()
        guard let wrapper = try? NSFWDetector(configuration: config) else { fatalError() }
        guard let model = try? VNCoreMLModel(for: wrapper.model) else { fatalError() }
        return model
    }()
    
    private var predictionsMap = [VNRequest: (predictions: [Prediction]?) -> Void]()
    
    //MARK: - Helpers
    func makePredictions(for photo: UIImage, completion: @escaping (_ predictions: [Prediction]?) -> Void) {
        let orientation = CGImagePropertyOrientation(photo.imageOrientation)
        guard let image = photo.cgImage else { fatalError() }
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
        
        let imageClassificationRequest = VNCoreMLRequest(model: imageClassifier) { req, error in
            //Heres where magic happens
            if let error = error {
                print("Vision image classification error...\n\n\(error.localizedDescription)")
                return
            }
            
            if req.results == nil {
                print("Vision request had no results.")
                return
            }
            
            guard let observations = req.results as? [VNClassificationObservation] else { return }
            
            let predictions = observations.map { Prediction(category: Category(rawValue: $0.identifier)!, confidence: $0.confidence)}
            print(predictions)
        }
        
        predictionsMap[imageClassificationRequest] = completion
        let requests: [VNRequest] = [imageClassificationRequest]
        do {
            try handler.perform(requests)
        } catch {
            print("there was an error \(error.localizedDescription)")
        }
    }
}


extension ImagePredictor {
    struct Prediction {
        var category: Category
        var confidence: Float
        
        init(category: Category, confidence: Float) {
            self.category = category
            self.confidence = confidence * 100
        }
    }
}
