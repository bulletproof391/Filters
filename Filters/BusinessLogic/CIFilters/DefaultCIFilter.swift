//
//  DefaultCIFilter.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 03/12/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import AVFoundation
import Photos

class DefaultCIFilter {

    // MARK: - Public properties

    var isPrepared = false
    private(set) var outputFormatDescription: CMFormatDescription?
    private(set) var inputFormatDescription: CMFormatDescription?
    private(set) var filter: CIFilter?

    // MARK: - Private properties

    private var ciContext: CIContext
    private var outputColorSpace: CGColorSpace?
    private var outputPixelBufferPool: CVPixelBufferPool?

    init(ciContext: CIContext, filterName: String) {
        self.ciContext = ciContext
        self.filter = CIFilter(name: filterName)
    }

    // MARK: - Public methods

    // Filter CoreImage
    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        reset()

        (outputPixelBufferPool,
         outputColorSpace,
         outputFormatDescription) = BufferAllocationHelper.allocateOutputBufferPool(
            with: formatDescription,
            outputRetainedBufferCountHint: outputRetainedBufferCountHint
        )

        guard outputPixelBufferPool != nil else { return }
        inputFormatDescription = formatDescription
        isPrepared = true
    }

    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let filter = filter, isPrepared else {
            return pixelBuffer
        }

        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        filter.setValue(sourceImage, forKey: kCIInputImageKey)

        guard let filteredImage = filter.outputImage else {
            print("CIFilter failed to render image")
            return nil
        }

        var pbuf: CVPixelBuffer?
        guard let outputPixelBufferPool = outputPixelBufferPool else { return nil }

        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool, &pbuf)
        guard let outputPixelBuffer = pbuf else {
            print("Allocation failure")
            return nil
        }

        // Render the filtered image out to a pixel buffer (no locking needed, as CIContext's render method will do that)
        ciContext.render(filteredImage,
                         to: outputPixelBuffer,
                         bounds: filteredImage.extent,
                         colorSpace: outputColorSpace)

        return outputPixelBuffer
    }

    // MARK: - Private methods

    private func reset() {
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        isPrepared = false
    }
}
