//
//  FrontCameraViewController.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 28/11/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import UIKit

final class FrontCameraViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private var cameraPreviewView: PreviewMetalView!
    @IBOutlet private var captureImageButton: UIButton!

    // MARK: - Public properties

    let cameraManager = CameraManager()

    // MARK: - View controller lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
    }

    // MARK: - Public methods

    @IBAction func captureImage(_ sender: Any) {
        cameraManager.captureImage()
    }

    // MARK: - Private methods

    private func configureViewController() {
        prepareCameraUsage()
        configureButton()
    }

    private func prepareCameraUsage() {
        cameraManager.previewLayer = cameraPreviewView

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.cameraManager.checkAuthorizationStatus()
        }
    }

    private func configureButton() {
        captureImageButton.setTitle(nil)
        captureImageButton.backgroundColor = UIColor.white
        captureImageButton.layer.cornerRadius = captureImageButton.bounds.width / 2
    }
}
