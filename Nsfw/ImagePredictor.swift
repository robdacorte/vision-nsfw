//
//  ImagePredictor.swift
//  Nsfw
//
//  Created by Rob on 15/10/22.
//

import UIKit
import Vision

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
        
        let imageClassificationRequest = VNCoreMLRequest(model: imageClassifier, completionHandler: classificationCompletionHandler)
        
        predictionsMap[imageClassificationRequest] = completion
        let requests: [VNRequest] = [imageClassificationRequest]
        do {
            try handler.perform(requests)
        } catch {
            print("there was an error \(error.localizedDescription)")
        }
    }
    
    private func classificationCompletionHandler(request: VNRequest, error: Error?) {
        //Here's where magic happens
        
        //First, we get the completion handler from the dictionary
        guard let completion = predictionsMap[request] else { return }
        var predictions: [Prediction] = []
        
        defer {
            completion(predictions)
        }
        
        if let error = error {
            print("Vision image classification error...\n\n\(error.localizedDescription)")
            return
        }
        
        if request.results == nil {
            print("Vision request had no results.")
            return
        }
        
        guard let observations = request.results as? [VNClassificationObservation] else { return }
        
        predictions = observations.map { Prediction(category: Category(rawValue: $0.identifier)!, confidence: $0.confidence)}
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
