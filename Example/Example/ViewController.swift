//
//  ViewController.swift
//  Example
//
//  Created by Omar Allaham on 6/17/21.
//

import UIKit
import SmileDetectorKit
import Combine
import CoreData
import QuickLookThumbnailing

class ViewController: UIViewController {
    
    var thumbnailGenerator = QLThumbnailGenerator()
    
    @IBOutlet weak var imageView: UIImageView!
    
    var detector: SmileDetector?
    
    lazy var addSmileViaCameraAction: UIAction = .init(
        title: NSLocalizedString("Add Smile", comment: ""),
        image: UIImage(systemName: ""),
        discoverabilityTitle: NSLocalizedString("Uses the camera to capture the smile", comment: ""),
        handler: presentSmileDetector(sender:)
    )
    
    lazy var smileDetectorMenu: UIMenu = .init(
        children: [addSmileViaCameraAction]
    )
    
    lazy var addButtonItem: UIBarButtonItem = .init(
        systemItem: .add,
        primaryAction: addSmileViaCameraAction,
        menu: smileDetectorMenu
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationItem()
    }
    
    func configureNavigationItem() {
        
        navigationItem.title = NSLocalizedString("Smiles", comment: "")
        
        navigationItem.rightBarButtonItems = [addButtonItem]
    }

    func presentSmileDetector(sender: Any?) {
        
        detector = SmileDetector()
        
        detector?.start(using: .camera, from: self, delegate: self)
    }
    
    func presentErrorAlert(_ error: Error) {
        
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                presentErrorAlert(error)
            }
            
            return
        }
        
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""),
                                      style: .default))
        
        present(alert, animated: true)
    }
}

extension ViewController: DetectionDelegate {
    
    func detector(_ detector: SmileDetector, didFinishWith result: DetectionResult?) {
        
        detector.dismissActiveSession { [weak self] in
            self?.detector = nil
            
            switch result {
                case .failure(let error):
                    self?.presentErrorAlert(error)
                case .success((let image, _)):
                    self?.createNewObject(using: image)
                case .none:
                    break
            }
        }
    }
    
    func createNewObject(using ciImage: CIImage) {
        
        let uiImage = UIImage(ciImage: ciImage)
        
        imageView?.image = uiImage
    }
}

