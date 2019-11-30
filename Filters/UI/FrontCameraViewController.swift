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

    @IBOutlet private var cameraPreviewView: CameraPreviewLayer!

    // MARK: - Public properties

    let cameraManager = CameraManager()

    // MARK: - View controller lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
    }

    // MARK: - Private methods

    private func configureViewController() {
        cameraManager.previewLayer = cameraPreviewView.videoPreviewLayer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.cameraManager.checkAuthorizationStatus()
        }
    }
}
