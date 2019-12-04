//
//  PhotoLibraryManager.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 04/12/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import AVFoundation
import Foundation
import Photos

final class PhotoLibraryManager {
    var onProcessFinished: DefaultHandler?

    func savePhoto(uniformTypeIdentifier: String?, photoData: Data) {
        checkAuthorizationStatus {
            let onSave = {
                let options = PHAssetResourceCreationOptions()
                let creationRequest = PHAssetCreationRequest.forAsset()

                options.uniformTypeIdentifier = uniformTypeIdentifier
                creationRequest.addResource(with: .photo, data: photoData, options: options)
            }

            let onCompletion: (Bool, Error?) -> Void = { [weak self] _, error in
                if let error = error {
                    print("Error occurred while saving photo to photo library: \(error)")
                }

                self?.onProcessFinished?()
            }

            PHPhotoLibrary.shared().performChanges(onSave, completionHandler: onCompletion)
        }
    }

    private func checkAuthorizationStatus(onSavePhoto: @escaping DefaultHandler) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard .authorized == status else {
                self?.onProcessFinished?()
                return
            }

            onSavePhoto()
        }
    }
}
