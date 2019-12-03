//
//  CameraManager.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 28/11/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

protocol CameraManagerable: AnyObject {
    var previewLayer: PreviewMetalView? { get set }
    func checkAuthorizationStatus()
    func captureImage()
}

final class CameraManager: NSObject, CameraManagerable {

    // MARK: - Private proeprties

    let captureSession = AVCaptureSession()
    weak var previewLayer: PreviewMetalView?
    
    var currentFilter: DefaultCIFilter?
    var ciFilters = [DefaultCIFilter]()
    var filterIndex: Int = 0

    // MARK: - Private proeprties

    private var dataOutputQueue = DispatchQueue(label: "OutputQueue",
                                                qos: .userInitiated,
                                                attributes: [],
                                                autoreleaseFrequency: .workItem)

    private var videoDeviceInput: AVCaptureDeviceInput!
    private var photoOutput: AVCapturePhotoOutput!
    private var videoOutput: AVCaptureVideoDataOutput!
    private var authorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()

    // MARK: - Public methods

    func checkAuthorizationStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // The user has previously granted access to the camera
            case .authorized:
                setupCaptureSession()

            // The user has not yet been asked for camera access
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    guard granted else { return }
                    self?.setupCaptureSession()
                }

            // The user has previously denied access
            case .denied:
                return

            // The user can't grant access due to restrictions
            case .restricted:
                return

        @unknown default:
            assertionFailure("Please supplement switch-case statement")
            return
        }
    }

    func captureImage() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let photoSettings = AVCapturePhotoSettings()
            photoSettings.isHighResolutionPhotoEnabled = true
            photoSettings.photoQualityPrioritization = .balanced

            let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings,
                                                              willCapturePhotoAnimation: self.animatePhotoCapture,
                                                              applyFilterHandler: self.applyFilter,
                                                              completionHandler: self.captureDidFinish)

            let instanceId = photoCaptureProcessor.requestedPhotoSettings.uniqueID
            self.inProgressPhotoCaptureDelegates[instanceId] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }

    // MARK: - Private methods

    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo

        guard setupInput(for: captureSession)
            && setupPhotoOutput(for: captureSession)
            && setupVideoOutput(for: captureSession) else { return }
        captureSession.commitConfiguration()

        DispatchQueue.main.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    private func setupInput(for session: AVCaptureSession) -> Bool {
        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .front),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            session.canAddInput(videoDeviceInput) else { return false }

        self.videoDeviceInput = videoDeviceInput
        session.addInput(videoDeviceInput)
        return true
    }

    private func setupPhotoOutput(for session: AVCaptureSession) -> Bool {
        photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true

        guard session.canAddOutput(photoOutput) else { return false }
        session.addOutput(photoOutput)

        return true
    }

    private func setupVideoOutput(for session: AVCaptureSession) -> Bool {
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)

        guard session.canAddOutput(videoOutput) else { return false }
        session.addOutput(videoOutput)

        return true
    }

    private func animatePhotoCapture() {
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.layer.opacity = 0

            UIView.animate(withDuration: 0.25) {
                self?.previewLayer?.layer.opacity = 1
            }
        }
    }

    private func applyFilter(_ photo: AVCapturePhoto) -> Data? {
        // Applying filter
        let photoData = photo.fileDataRepresentation()
        guard let filter = currentFilter?.filter else { return photoData }

        guard let dataRepresentation = photo.fileDataRepresentation() else { return photoData }
        filter.setValue(CIImage(data: dataRepresentation), forKey: kCIInputImageKey)
        guard let renderedCIImage = filter.outputImage else { return photoData }

        let outputimage = UIImage(ciImage: renderedCIImage, scale: 1, orientation: .right)
        return outputimage.jpegData(compressionQuality: 1.0)
    }

    private func captureDidFinish(_ uniqueID: Int64) {
        // When the capture is complete, remove a reference to
        // the photo capture delegate so it can be deallocated
        inProgressPhotoCaptureDelegates[uniqueID] = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard var videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }

        /*
         outputRetainedBufferCountHint is the number of pixel buffers the renderer retains.
         This value informs the renderer how to size its buffer pool and how many pixel
         buffers to preallocate. Allow 3 frames of latency to cover the dispatch_async call.
         */

        if let currentFilter = currentFilter {
            if !currentFilter.isPrepared {
                currentFilter.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }

            // Send the pixel buffer through the filter
            guard let filteredBuffer = currentFilter.render(pixelBuffer: videoPixelBuffer) else {
                print("Unable to filter video buffer")
                return
            }

            videoPixelBuffer = filteredBuffer
        }

        previewLayer?.pixelBuffer = videoPixelBuffer
    }
}
