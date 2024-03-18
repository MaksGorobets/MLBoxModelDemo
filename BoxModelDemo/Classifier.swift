//
//  Classifier.swift
//  BoxModelDemo
//
//  Created by Maks Winters on 01.11.2023.
//
// https://stackoverflow.com/questions/75863781/code-9-could-not-create-inference-context-coreml-ios
//

import CoreML
import Vision
import CoreImage

struct Classifier {
    var modelSwitch: Bool = true
    let minimumConfidence: VNConfidence = 0.1
    var getModel: VNCoreMLModel? {
        get {
            let config = MLModelConfiguration()
            if modelSwitch {
                return try? VNCoreMLModel(for: StorifyQRImageClassifierV1(configuration: config).model)
            } else {
                return try? VNCoreMLModel(for: BoxesImageClassifier(configuration: config).model)
            }
        }
    }
    
    
    private(set) var results: String?
    private(set) var validResultsArray = [String]()
    
    mutating func detect(ciImage: CIImage) {
        validResultsArray.removeAll()
        print("Starting classification process")
        
        guard let model = getModel
        else {
            print("Model loading failed")
            return
        }
        
        let request = VNCoreMLRequest(model: model)
        
        #if targetEnvironment(simulator)
        let allDevices = MLComputeDevice.allComputeDevices

        for device in allDevices {
          if(device.description.contains("MLCPUComputeDevice")){
            request.setComputeDevice(.some(device), for: .main)
            break
          }
        }
        #endif
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([request])
            if let results = request.results as? [VNClassificationObservation], let firstResult = results.first {
                self.results = firstResult.identifier
                print("Image classified as: \(firstResult.identifier), \(firstResult.confidence)")
                
                print("Others:")
                results.forEach { observation in
                    if observation.confidence > minimumConfidence {
                        let observationString = observation.identifier
                        print(observationString)
                        validResultsArray.append(observationString)
                        print(validResultsArray)
                    }
                }
                
            } else {
                print("No classification results found")
            }
        } catch {
            print("Error in classification request: \(error)")
        }
        
    }
    
}

