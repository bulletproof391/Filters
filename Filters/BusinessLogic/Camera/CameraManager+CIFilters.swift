//
//  CameraManager+CIFilters.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 03/12/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import CoreImage

protocol ImageFiltering: AnyObject {
    func initFilters(with names: [String])
    func applyFilter(direction: Direction)
}

extension CameraManager: ImageFiltering {

    func initFilters(with names: [String]) {
        let ciContext = CIContext()
        ciFilters = names.map { .init(ciContext: ciContext, filterName: $0) }

        guard !ciFilters.isEmpty else { return }
        currentFilter = ciFilters[filterIndex]
    }

    func applyFilter(direction: Direction) {
        let newIndex: Int

        switch direction {
        case .next:
            newIndex = filterIndex + 1
        case .previous:
            newIndex = filterIndex - 1
        }

        guard newIndex > -1 && newIndex < ciFilters.count else { return }

        filterIndex = newIndex
        currentFilter = ciFilters[newIndex]
    }
}
