//
//  UIButton+Appearance.swift
//  Filters
//
//  Created by Дмитрий Вашлаев on 30/11/2019.
//  Copyright © 2019 Dmitry Vashlaev. All rights reserved.
//

import UIKit

extension UIButton {
    var states: [UIControl.State] {
        return [.disabled, .normal, .selected, .highlighted]
    }

    func setTitle(_ title: String?) {
        states.forEach { setTitle(title, for: $0) }
    }
}
