//
//  ForwardingScrollView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 26/01/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

class ForwardingScrollView: NSScrollView {

    override func scrollWheel(with event: NSEvent) {
        var shouldForwardScroll = false

        if usesPredominantAxisScrolling {
            if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
                // Horizontal scroll
                if !hasHorizontalScroller {
                    shouldForwardScroll = true
                }
            }
            else {
                // Vertical scroll
                if !hasVerticalScroller {
                    shouldForwardScroll = true
                }
            }
        }

        if shouldForwardScroll {
            nextResponder?.scrollWheel(with: event)
        }
        else {
            super.scrollWheel(with: event)
        }
    }

}
