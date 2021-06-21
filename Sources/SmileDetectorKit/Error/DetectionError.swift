//
//  DetectionError.swift
//  
//
//  Created by Omar Allaham on 6/17/21.
//

import Foundation

enum DetectionError: LocalizedError {
    case noFaceDetected
    case tooManyFaces
    case eyesAreClosed
    case noSmile
    case faceNotCentered
}

extension DetectionError {

    /// A localized message describing what error occurred.
    var errorDescription: String? {
        return [failureReason, recoverySuggestion]
            .compactMap({ $0 })
            .joined()
    }

    var failureReason: String? {
        switch self {
            case .noFaceDetected:
                return NSLocalizedString("No face detected.", bundle: .module, comment: "")
            case .tooManyFaces:
                return NSLocalizedString("Too many faces.", bundle: .module, comment: "")
            case .eyesAreClosed:
                return NSLocalizedString("Eyes are closed.", bundle: .module, comment: "")
            case .noSmile:
                return NSLocalizedString("No smile.", bundle: .module, comment: "")
            case .faceNotCentered:
                return NSLocalizedString("Face detected was not in the center.", bundle: .module, comment: "")
        }
    }

    var recoverySuggestion: String? {
        switch self {
            case .noFaceDetected:
                return NSLocalizedString("Try to move the camera to your.", bundle: .module, comment: "")
            case .tooManyFaces:
                return NSLocalizedString("One face at a time please.", bundle: .module, comment: "")
            case .eyesAreClosed:
                return NSLocalizedString("Please open both eyes.", bundle: .module, comment: "")
            case .noSmile:
                return NSLocalizedString("Smile Please!", bundle: .module, comment: "")
            case .faceNotCentered:
                return NSLocalizedString("Please move the face to center.", bundle: .module, comment: "")
        }
    }
}
