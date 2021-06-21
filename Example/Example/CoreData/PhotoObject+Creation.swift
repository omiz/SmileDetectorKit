//
//  PhotoObject+Creation.swift
//  Example
//
//  Created by Omar Allaham on 6/17/21.
//

import Foundation
import CoreGraphics
import CoreData
import UIKit
import QuickLookThumbnailing

extension PhotoObject {
    
    fileprivate static func folder() throws -> URL {
        let manager = FileManager.default
        var url = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        url.appendPathComponent("PhotoObject")
        
        try manager.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        
        return url
    }
    
    fileprivate static func fileURL(for object: PhotoObject) throws -> URL? {
     
        guard let id = object.id else { return nil }
        
        let url = try folder()
            .appendingPathComponent(id)
            .appendingPathExtension("png")
        
        return url
    }
    
    static func create(using image: CGImage) throws {
        
        guard let data = image.pngData else {
            throw CocoaError(.fileReadUnknown)
        }
        
        try createForImage(pngData: data)
    }
    
    static func create(using image: UIImage) throws {
        
        guard let data = image.pngData() else {
            throw CocoaError(.fileReadUnknown)
        }
        
        try createForImage(pngData: data)
    }
    
    static func createForImage(pngData d: Data) throws {
        
        let context = CoreDataManger.shared.persistentContainer.newBackgroundContext()
        
        var _error: Error?
        
        context.performAndWait {
            do {
                try createForImage(pngData: d, in: context)
            } catch {
                _error = error
            }
        }
        
        if let error = _error {
            throw error
        }
    }
    
    static func createForImage(pngData: Data, in context: NSManagedObjectContext) throws {
        
        let object = PhotoObject(context: context)
        object.id = UUID().uuidString
        object.creationDate = Date()
        object.modificationDate = object.creationDate
        
        if let url = try fileURL(for: object) {
            object.filePath = url.path
            
            try pngData.write(to: url, options: .atomic)
        }
        
        try context.save()
    }
    
    func thumbnailRequest(size: CGSize) -> QLThumbnailGenerator.Request? {
        
        guard let path = filePath, !path.isEmpty else { return nil }
        
        let url = URL(fileURLWithPath: path)
        
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: 1, representationTypes: .thumbnail)
        
        return request
    }
}

extension CGImage {
    var pngData: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
