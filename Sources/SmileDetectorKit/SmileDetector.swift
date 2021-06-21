//
//  SmileDetector.swift
//  
//
//  Created by Omar Allaham on 6/15/21.
//

import Foundation
import Vision
import Combine
import UIKit
import os

public protocol DetectionDelegate: AnyObject {
    
    typealias DetectionResult = Result<(CIImage, CIFeature), Error>
    
    func detector(_ detector: SmileDetector, didFinishWith result: DetectionResult?)
}

public class SmileDetector {
    
    public static var shared: SmileDetector = .init()
    
    public var shouldCaptureSmileAutomatically: Bool = true
    
    private weak var cameraCaptureController: CameraViewController?
    
    weak var delegate: DetectionDelegate?
    
    public init() {}
    
    public func start(using source: DetectionSource = .camera,
                      from vc: UIViewController,
                      withValidator v: SampleBufferValidator = SmilingValidator(),
                      delegate: DetectionDelegate?) {
        
        guard cameraCaptureController == nil else {
            Logger().error("SmileDetector already started and can not be started again")
            assertionFailure()
            return
        }
        
        self.delegate = delegate
        
        let controller = CameraViewController()
        controller.validator = v
        controller.delegate = self

        vc.present(controller, animated: true, completion: nil)

        self.cameraCaptureController = controller
    }
    
    public func dismissActiveSession(completion: (() -> Void)? = nil) {
        
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                dismissActiveSession(completion: completion)
            }
            
            return
        }

        self.delegate = nil
        
        cameraCaptureController?.dismiss(animated: true, completion: completion)
    }
}

extension SmileDetector: CameraViewControllerDelegate {
    
    func cameraViewController(_ controller: CameraViewController, didFinishWith result: Result<(CIImage, CIFeature), Error>?) {
        
        delegate?.detector(self, didFinishWith: result)
    }
}
