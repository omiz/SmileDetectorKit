//
//  File.swift
//  
//
//  Created by Omar Allaham on 6/17/21.
//

import Foundation
import AVKit
import Combine
import UIKit

class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    
    var results = PassthroughSubject<UIImage, Never>()
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        
        if let cgImage = photo.cgImageRepresentation()?.takeRetainedValue(),
           let orientation = photo.metadata[kCGImagePropertyOrientation as String] as? UInt32,
           let uiOrientation = UIImage.Orientation.orientation(fromCGOrientationRaw: orientation) {
            
            let image = UIImage(cgImage: cgImage, scale: 1, orientation: uiOrientation)
            
            results.send(image)
        }
    }
}


extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
            @unknown default:
                self = .up
        }
    }
}
extension UIImage.Orientation {
    
    static func orientation(fromCGOrientationRaw cgOrientationRaw: UInt32) -> UIImage.Orientation? {
        var orientation: UIImage.Orientation?
        if let cgOrientation = CGImagePropertyOrientation(rawValue: cgOrientationRaw) {
            orientation = UIImage.Orientation(cgOrientation)
        } else {
            orientation = nil // only hit if improper cgOrientation is passed
        }
        return orientation
    }
    
    init(_ cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        }
    }

}
