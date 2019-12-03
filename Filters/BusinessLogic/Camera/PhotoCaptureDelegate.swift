//
//  PhotoCaptureDelegate.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 30/11/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

class PhotoCaptureProcessor: NSObject {

    // MARK: - Public properties

    private(set) var requestedPhotoSettings: AVCapturePhotoSettings

    // MARK: - Private properties

    private let willCapturePhotoAnimation: DefaultHandler?
    private let photoProcessingHandler: ((Bool) -> Void)?
    private let completionHandler: (PhotoCaptureProcessor) -> Void

    private var photoData: Data?
    private var maxPhotoProcessingTime: CMTime?
    private var semanticSegmentationMatteDataArray = [Data]()
    private let processingQueue = DispatchQueue(label: "ProcessingQueue",
                                                qos: .userInitiated,
                                                attributes: [],
                                                autoreleaseFrequency: .workItem,
                                                target: nil)

    // MARK: - Initializers

    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         willCapturePhotoAnimation: DefaultHandler? = nil,
         photoProcessingHandler: ((_ isProcessingPhoto: Bool) -> Void)? = nil,
         completionHandler: @escaping (PhotoCaptureProcessor) -> Void) {

        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.photoProcessingHandler = photoProcessingHandler
        self.completionHandler = completionHandler
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {

    // Will begin capture photo
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        processingQueue.async { [weak self] in
            self?.maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start
                                            + resolvedSettings.photoProcessingTimeRange.duration
        }
    }

    // Will capture photo
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        processingQueue.async { [weak self] in
            self?.willCapturePhotoAnimation?()

            // Show a spinner if processing time exceeds one second
            let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)

            guard let maxPhotoProcessingTime = self?.maxPhotoProcessingTime,
                maxPhotoProcessingTime > oneSecond else { return }

            self?.photoProcessingHandler?(true)
        }
    }

    // Did finish processing photo
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }

            self.photoProcessingHandler?(false)

            if let error = error {
                print("Error capturing photo: \(error)")
                return
            }

            // Applying filter
            self.photoData = photo.fileDataRepresentation()
            let filter = CIFilter(name: "CICrystallize")

            guard let dataRepresentation = photo.fileDataRepresentation() else { return }
            filter?.setValue(CIImage(data: dataRepresentation), forKey: kCIInputImageKey)
            guard let renderedCIImage = filter?.outputImage else { return }

            let outputimage = UIImage(ciImage: renderedCIImage, scale: 1, orientation: .right)
            self.photoData = outputimage.jpegData(compressionQuality: 1.0)
        }
    }

    // Did finish capture photo
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            if let error = error {
                print("Error capturing photo: \(error)")
                self.completionHandler(self)
                return
            }

            guard let photoData = self.photoData else {
                print("No photo data resource")
                self.completionHandler(self)
                return
            }

            // Saving photo to library
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        let creationRequest = PHAssetCreationRequest.forAsset()

                        options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                        creationRequest.addResource(with: .photo, data: photoData, options: options)

                    }, completionHandler: { _, error in
                        if let error = error {
                            print("Error occurred while saving photo to photo library: \(error)")
                        }

                        self.completionHandler(self)
                    })
                } else {
                    self.completionHandler(self)
                }
            }
        }
    }
}
