//
//  CameraManager.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 28/11/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import AVFoundation
import UIKit

final class CameraManager {

    let captureSession = AVCaptureSession()
    weak var previewLayer: AVCaptureVideoPreviewLayer?

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

    // MARK: - Private methods

    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        guard setupInput(for: captureSession) && setupOutput(for: captureSession) else { return }
        captureSession.commitConfiguration()

        previewLayer?.session = captureSession

        DispatchQueue.main.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    private func setupInput(for session: AVCaptureSession) -> Bool {
        // add input
        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .front),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            session.canAddInput(videoDeviceInput) else { return false }

        session.addInput(videoDeviceInput)
        return true
    }

    private func setupOutput(for session: AVCaptureSession) -> Bool {
        // add output
        let photoOutput = AVCapturePhotoOutput()
        guard session.canAddOutput(photoOutput) else { return false }
        session.sessionPreset = .photo
        session.addOutput(photoOutput)

        return true
    }
}
