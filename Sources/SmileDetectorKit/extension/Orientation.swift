//
//  Orientation.swift
//  
//
//  Created by Omar Allaham on 6/17/21.
//

import UIKit
import AVKit

extension UIInterfaceOrientation {
    
    var videoOrientation: AVCaptureVideoOrientation {
        switch self {
            case .portrait:
                return AVCaptureVideoOrientation.portrait
            case .landscapeRight:
                return AVCaptureVideoOrientation.landscapeRight
            case .landscapeLeft:
                return AVCaptureVideoOrientation.landscapeLeft
            case .portraitUpsideDown:
                return AVCaptureVideoOrientation.portraitUpsideDown
            default:
                return AVCaptureVideoOrientation.portrait
        }
    }
    
    
    var ciDetectorImageOrientation: Int {
        switch self {
            case .portrait:             return 6
            case .portraitUpsideDown:   return 2
            case .landscapeLeft:        return 3
            case .landscapeRight:       return 4
                
            case .unknown:              return 1
        }
    }
}

extension UIDeviceOrientation {
    
    var ciDetectorImageOrientation: Int {
        switch self {
            case .portrait:             return 6
            case .portraitUpsideDown:   return 2
            case .landscapeLeft:        return 3
            case .landscapeRight:       return 4
                
            default :                   return 1
        }
    }
    
    var uiInterfaceOrientation: UIInterfaceOrientation {
        switch self {
            case .unknown: return .unknown
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            case .faceUp:
                return .portrait
            case .faceDown:
                return .portrait
            @unknown default:
                return .portrait
        }
    }
}
