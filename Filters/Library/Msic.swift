//
//  Msic.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 03/12/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import Foundation

typealias DefaultHandler = () -> Void

enum FilterName: String, CaseIterable {
    case noFilter = ""
    case gaussianBlur = "CIGaussianBlur"
    case comicEffect = "CIComicEffect"
    case crystallize = "CICrystallize"
}

enum Direction {
    case next
    case previous
}
