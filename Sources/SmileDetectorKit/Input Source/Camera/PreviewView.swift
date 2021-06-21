//
//  PreviewView.swift
//  
//
//  Created by Omar Allaham on 6/17/21.
//

import UIKit
import AVKit
import os

final class PreviewView: UIView {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var videoOrientation: AVCaptureVideoOrientation? {
        videoPreviewLayer.connection?.videoOrientation
    }
    
    func applyDefaultLayerConfiguration() {
        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.masksToBounds = true
    }
    
    func attachPreviewLayer(to captureSession: AVCaptureSession) {
        videoPreviewLayer.session = captureSession
    }
    
    func insertInto(_ superView: UIView) {
        self.frame = superView.bounds
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.translatesAutoresizingMaskIntoConstraints = true
        superView.addSubview(self)
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        guard let window = window else { return }
        
        updateOrientation(in: window)
    }
    
    func updateOrientation() {
        
        guard let window = self.window else {
            Logger().log("\(#file) Updating the videoOrientation before the view is visible")
            return
        }
        
        updateOrientation(in: window)
    }
    
    func updateOrientation(in window: UIWindow) {
        
        guard let scene = window.windowScene else { return }
        
        updateOrientation(to: scene.interfaceOrientation)
    }
    
    func updateOrientation(to interfaceOrientation: UIInterfaceOrientation) {
        
        let orientation =  interfaceOrientation.videoOrientation
        
        videoPreviewLayer.connection?.videoOrientation = orientation
    }
}
