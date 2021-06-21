//
//  File.swift
//  
//
//  Created by Omar Allaham on 6/16/21.
//

import Foundation

public enum DetectionSource: Hashable {
    
    case camera
    
    @available(*, unavailable)
    case videoFile(url: URL)
}
