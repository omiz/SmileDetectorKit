//
//  FaceFeatureValidator.swift
//  
//
//  Created by Omar Allaham on 6/16/21.
//

import CoreImage
import CoreMedia
import CoreGraphics
import UIKit

public protocol SampleBufferValidator {
    
    func validate(_ buffer: CMSampleBuffer, withOrientation ciDetectorImageOrientation: Int) throws -> (image: CIImage, feature: CIFaceFeature)
}

public struct SmilingValidator: SampleBufferValidator {
    
    let faceDetector: CIDetector!
    
    public var featureOptions: [String : Any]? = [
        CIDetectorSmile : true,
        CIDetectorEyeBlink: true,
        CIDetectorReturnSubFeatures: true
    ]
    
    public init() {
        self.faceDetector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options: [CIDetectorAccuracy : CIDetectorAccuracyLow]
        )
    }
    
    public func validate(_ buffer: CMSampleBuffer,
                         withOrientation ciDetectorImageOrientation: Int) throws -> (image: CIImage, feature: CIFaceFeature) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(buffer)
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer!).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        let sourceImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        
        var options = featureOptions
        options?[CIDetectorImageOrientation] = ciDetectorImageOrientation
        
        let features: [CIFaceFeature] = self.faceDetector
            .features(in: sourceImage, options: options)
            .compactMap({ $0 as? CIFaceFeature })
        
        switch features.count {
            case 0:
                throw DetectionError.noFaceDetected
            case 1:
                let feature = features.first!
                try validate(feature, in: sourceImage)
                
                let outputImage = sourceImage.oriented(forExifOrientation: Int32(ciDetectorImageOrientation))
                
                return (outputImage, feature)
            default:
                throw DetectionError.tooManyFaces
        }
    }
    
    func validate(_ faceFeature: CIFaceFeature, in image: CIImage) throws {
        
        if !faceFeature.hasSmile {
            throw DetectionError.noSmile
        }
        
        if faceFeature.leftEyeClosed || faceFeature.rightEyeClosed {
            throw DetectionError.eyesAreClosed
        }
        let imageCenter = CGPoint(x: image.extent.midX, y: image.extent.midY)
        
        let centerRect = CGRect(origin: imageCenter, size: .zero)
            .inset(by: .init(top: 500, left: 500, bottom: 500, right: 500))
        
        let featureCenter = CGPoint(x: faceFeature.bounds.midX, y: faceFeature.bounds.midY)
        
        let isCentered = centerRect.contains(featureCenter)
        
        if  !isCentered {
            throw DetectionError.faceNotCentered
        }
    }
}
