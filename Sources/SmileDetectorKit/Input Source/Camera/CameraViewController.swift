//
//  CameraViewController.swift
//  
//
//  Created by Omar Allaham on 6/16/21.
//

import UIKit
import AVKit
import Vision
import Combine
import os

internal protocol CameraViewControllerDelegate: AnyObject {
    
    func cameraViewController(_ controller: CameraViewController,
                              didFinishWith result: Result<(CIImage, CIFeature), Error>?)
}


final class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    weak var delegate: CameraViewControllerDelegate?
    
    var cancellables: Set<AnyCancellable> = []
    
    var validator: SampleBufferValidator!
    
    var previewView: PreviewView?
    
    var closeButton: UIButton?
    var suggestionButton: UIButton?
    var detectedResults: CurrentValueSubject<Result<(CIImage, CIFeature), Error>?, Never> = .init(nil)
    var suggestionText: CurrentValueSubject<String?, Never> = .init(nil)
    
    var session: AVCaptureSession?
    
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue?
    
    var captureDevice: AVCaptureDevice?
    var captureDeviceResolution: CGSize = CGSize()
    
    // Vision requests
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    // MARK: UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        configureViewHierarchy()
        
        self.session = self.setupAVCaptureSession()
        
        self.session?.startRunning()
        
        listenForResults()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        previewView?.updateOrientation()
    }
    
    func listenForResults() {
        
        detectedResults
            .compactMap({ (try? $0?.get()) == nil ? nil : $0 })
            .dropFirst(50)
            .throttle(for: .seconds(1), scheduler: RunLoop.current, latest: true)
            .compactMap({ $0 })
            .sink(receiveCompletion: { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.cameraViewController(self, didFinishWith: nil)
            }, receiveValue: { [weak self] result in
                guard let self = self else { return }
                self.delegate?.cameraViewController(self, didFinishWith: result)
            }).store(in: &cancellables)
    }

    func configureViewHierarchy() {
        
        let previewView = PreviewView()
        previewView.insertInto(view)
        self.previewView = previewView
        
        configureSuggestionButton()
        
        configureCloseButton()
    }
    
    func configureSuggestionButton() {
        
        let suggestionButton = UIButton(type: .roundedRect)
        suggestionButton.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        suggestionButton.isUserInteractionEnabled = false
        suggestionButton.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        suggestionButton.setTitleColor(.systemYellow, for: .normal)
        suggestionButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        suggestionButton.translatesAutoresizingMaskIntoConstraints = false
        suggestionButton.layer.cornerRadius = 10
        suggestionButton.layer.cornerCurve = .continuous
        view.addSubview(suggestionButton)
        
        view.leadingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: suggestionButton.leadingAnchor, multiplier: 1).isActive = true
        
        suggestionButton.trailingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: view.trailingAnchor, multiplier: 1).isActive = true
        
        suggestionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        suggestionButton.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1).isActive = true
        
        suggestionText
            .throttle(for: 0.3, scheduler: RunLoop.main, latest: true)
            .removeDuplicates()
            .sink(receiveValue: { [unowned self] in
                self.suggestionButton?.setTitle($0, for: .normal)
                self.suggestionButton?.isHidden = $0?.isEmpty ?? true
                self.suggestionButton?.layoutIfNeeded()
            })
            .store(in: &cancellables)
        
        self.suggestionButton = suggestionButton
    }
    
    func configureCloseButton() {
        
        let action = UIAction(
            title: NSLocalizedString("Close", comment: ""),
            image: UIImage(systemName: ""),
            handler: { [unowned self] in
                self.close(sender: $0)
            })
        
        let button = UIButton(type: .close, primaryAction: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        view.trailingAnchor.constraint(equalToSystemSpacingAfter: button.trailingAnchor, multiplier: 1).isActive = true
        
        button.topAnchor.constraint(equalToSystemSpacingBelow: view.layoutMarginsGuide.topAnchor, multiplier: 1).isActive = true
        
        closeButton = button
    }
    
    func close(sender: Any?) {
        
        teardownAVCapture()
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: AVCapture Setup
    
    /// - Tag: CreateCaptureSession
    fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
        
        let captureSession = AVCaptureSession()
        
        do {
            
            let inputDevice = try self.configureFrontCamera(for: captureSession)
            
            self.configureVideoDataOutput(
                for: inputDevice.device,
                resolution: inputDevice.resolution,
                captureSession: captureSession
            )
            self.designatePreviewLayer(for: captureSession)
            
            return captureSession
        
        } catch let executionError as NSError {
            self.presentError(executionError)
        } catch {
            self.presentErrorAlert(message: "An unexpected failure has occurred")
        }
        
        self.teardownAVCapture()
        
        return nil
    }
    
    fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> (device: AVCaptureDevice, resolution: CGSize) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }
                
                if let highestResolution = device.highestResolution420Format() {
                    try device.lockForConfiguration()
                    device.activeFormat = highestResolution.format
                    device.unlockForConfiguration()
                    
                    return (device, highestResolution.resolution)
                }
            }
        }
        
        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    /// - Tag: CreateSerialDispatchQueue
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) {
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VisionFaceTrack")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }
        
        self.videoDataOutput = videoDataOutput
        self.videoDataOutputQueue = videoDataOutputQueue
        
        self.captureDevice = inputDevice
        self.captureDeviceResolution = resolution
    }
    
    /// - Tag: DesignatePreviewLayer
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        
        guard let previewView = self.previewView else {
            Logger().log("\(#function) was called before initializing the previewView")
            return
        }

        previewView.applyDefaultLayerConfiguration()
        previewView.attachPreviewLayer(to: captureSession)
    }
    
    // Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownAVCapture() {
        self.videoDataOutput = nil
        self.videoDataOutputQueue = nil
        
        previewView?.removeFromSuperview()
        previewView = nil
        
        detectedResults.send(completion: .finished)
    }
    
    // MARK: Helper Methods for Error Presentation
    
    fileprivate func presentErrorAlert(withTitle title: String = "Unexpected Failure", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alertController, animated: true)
    }
    
    fileprivate func presentError(_ error: NSError) {
        self.presentErrorAlert(withTitle: "Failed with error \(error.code)", message: error.localizedDescription)
    }
    
    // MARK: Helper Methods for Handling Device Orientation & EXIF
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [unowned self] context in
            self.previewView?.updateOrientation()
        }, completion: nil)
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    /// - Tag: PerformRequests
    // Handle delegate method callback on receiving a sample buffer.
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        do {
            let orientation = UIDevice.current.orientation.ciDetectorImageOrientation
            let result = try validator.validate(sampleBuffer, withOrientation: orientation)
            
            detectedResults.send(.success((result.image, result.feature)))
            suggestionText.send(nil)
        } catch {
            let suggestion: String?
            if let e = error as? LocalizedError {
                suggestion = e.recoverySuggestion
            } else {
                suggestion = error.localizedDescription
            }
            suggestionText.send(suggestion)
            detectedResults.send(nil)
        }
    }
    
    deinit {
        teardownAVCapture()
    }
}


