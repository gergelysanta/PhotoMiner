//
//  MainSplitView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 24/01/2018.
//  Copyright © 2018 Gergely Sánta. All rights reserved.
//

import Cocoa

class MainSplitView: NSSplitView {

    override func holdingPriorityForSubview(at subviewIndex: Int) -> NSLayoutConstraint.Priority {
        if subviewIndex == 1 {
            return NSLayoutConstraint.Priority.init(rawValue: 400)
        }
        return NSLayoutConstraint.Priority.defaultLow
    }

}
