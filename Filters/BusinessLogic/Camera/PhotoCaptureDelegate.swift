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

final class PhotoCaptureProcessor: NSObject {

    // MARK: - Public properties

    var photoLibraryManager: PhotoLibraryManager?
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings

    // MARK: - Private properties

    private let willCapturePhotoAnimation: DefaultHandler?
    private let photoProcessingHandler: ((Bool) -> Void)?
    private let applyFilterHandler: ((AVCapturePhoto) -> Data?)?
    private let completionHandler: (Int64) -> Void

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
         applyFilterHandler: ((AVCapturePhoto) -> Data?)? = nil,
         completionHandler: @escaping (Int64) -> Void) {

        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.photoProcessingHandler = photoProcessingHandler
        self.applyFilterHandler = applyFilterHandler
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

            self.photoData = self.applyFilterHandler?(photo)
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
                self.completionHandler(self.requestedPhotoSettings.uniqueID)
                return
            }

            guard let photoData = self.photoData else {
                print("No photo data resource")
                self.completionHandler(self.requestedPhotoSettings.uniqueID)
                return
            }

            // Saving photo to library
            let uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
            self.photoLibraryManager?.onProcessFinished = {
                self.completionHandler(self.requestedPhotoSettings.uniqueID)
            }
            self.photoLibraryManager?.savePhoto(uniformTypeIdentifier: uniformTypeIdentifier,
                                                photoData: photoData)
        }
    }
}
