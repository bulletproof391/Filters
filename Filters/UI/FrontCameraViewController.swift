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

    let cameraManager: CameraManagerable & ImageFiltering = CameraManager()

    // MARK: - View controller lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
    }

    // MARK: - User action methods

    @IBAction func captureImage(_ sender: Any) {
        cameraManager.captureImage()
    }

    // MARK: - Private methods

    private func configureViewController() {
        prepareCameraUsage()
        configurePreview()
        configureButton()
    }

    private func prepareCameraUsage() {
        cameraManager.previewLayer = cameraPreviewView
        cameraManager.initFilters(with: FilterName.allCases.map { String($0.rawValue) })

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.cameraManager.checkAuthorizationStatus()
        }
    }

    private func configurePreview() {
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self,
                                                        action: #selector(handleSwipeGesture(gestureRecognizer:)))
        leftSwipeGesture.direction = .left

        let rightSwipeGesture = UISwipeGestureRecognizer(target: self,
                                                         action: #selector(handleSwipeGesture(gestureRecognizer:)))
        rightSwipeGesture.direction = .right

        cameraPreviewView.addGestureRecognizer(leftSwipeGesture)
        cameraPreviewView.addGestureRecognizer(rightSwipeGesture)
        cameraPreviewView.isUserInteractionEnabled = true
    }

    private func configureButton() {
        captureImageButton.setTitle(nil)
        captureImageButton.backgroundColor = UIColor.white
        captureImageButton.layer.cornerRadius = captureImageButton.bounds.width / 2

        let longTapGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongTapGesture(gestureRecognizer:))
        )
        captureImageButton.addGestureRecognizer(longTapGestureRecognizer)
    }

    @objc private func handleSwipeGesture(gestureRecognizer: UISwipeGestureRecognizer) {
        switch gestureRecognizer.direction {
        case .left:
            cameraManager.applyFilter(direction: .next)
        case .right:
            cameraManager.applyFilter(direction: .previous)
        default:
            break
        }
    }

    @objc private func handleLongTapGesture(gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            let enlargeTransform = CGAffineTransform(scaleX: Constant.scalingCoefficient,
                                                     y: Constant.scalingCoefficient)
            scaleButton(duration: Constant.animationDuration, affineTransform: enlargeTransform)

        case .ended:
            scaleButton(duration: Constant.animationDuration, affineTransform: .identity)

        default:
            break
        }
    }

    private func scaleButton(duration: TimeInterval, affineTransform: CGAffineTransform) {
        UIView.animate(withDuration: duration) { [weak self] in
            guard let self = self else { return }
            self.captureImageButton.transform = affineTransform
        }
    }
}

extension FrontCameraViewController {
    enum Constant {
        static let animationDuration: Double = 0.3
        static let scalingCoefficient: CGFloat = 1.5
    }
}
