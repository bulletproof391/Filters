//
//  CameraPreviewLayer.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 28/11/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import AVFoundation
import UIKit

// swiftlint:disable force_cast
final class CameraPreviewLayer: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    /// Convenience wrapper to get layer as its statically known type
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
