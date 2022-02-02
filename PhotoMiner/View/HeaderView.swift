//
//  HeaderView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 01/03/2017.
//  Copyright © 2017 Gergely Sánta. All rights reserved.
//

import Cocoa

protocol HeaderViewDelegate {
    func headerToggleCollapse(_ headerView: HeaderView)
}

class HeaderView: NSView {

    @IBOutlet private weak var sectionTitle: NSTextField!
    @IBOutlet private weak var sectionInfo: NSTextField!

    // Don't make reference of toggleCollapseButton 'weak'
    // This button will be removed on systems where collapsing is not supported (10.11-)
    // For that case it must be strongly referenced
    // weak reference will be released after removing from superview and this will result invalid reference later (and crash)
    @IBOutlet var toggleCollapseButton: NSButton!

    // Helper property to track mouse up/down inside header view
    private var mouseButtonDown = false
    private var mouseButtonDownPosition = NSZeroPoint
    private let minimumAllowedMouseDragDistance:Double = 5.0

    var headerDelegate:HeaderViewDelegate?

    private(set) var isCollapsed = false {
        didSet {
            if isCollapsed {
                toggleCollapseButton.image = NSImage(named: "SectionCollapsed")
            }
            else {
                toggleCollapseButton.image = NSImage(named: "SectionExpanded")
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Fill view with a top-down gradient
        let gradient:NSGradient?
        if #available(OSX 10.13, *) {
            gradient = NSGradient(starting: NSColor(named: "SectionHeaderFromColor")!,
                                  ending: NSColor(named: "SectionHeaderToColor")!)
        } else {
            gradient = NSGradient(starting: NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 1.0),
                                  ending: NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 0.8))
        }
        gradient?.draw(in: self.bounds, angle: -90.0)
    }

    func setTitle(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMMyyyy", options: 0, locale: nil)
        self.sectionTitle.stringValue = formatter.string(from: date)
    }

    func setTitle(year: Int, andMonth month: Int) {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month], from: Date())
        dateComponents.year = year
        dateComponents.month = month

        if let headerDate = calendar.date(from: dateComponents) {
            self.setTitle(date: headerDate)
        }
        else {
            self.sectionTitle.stringValue = String(format: "%lu %02lu", year, month)
        }
    }

    func setPictureCount(_ count: Int) {
        if count < 0 {
            sectionInfo.stringValue = ""
        }
        else {
            let countLabel = (count > 1)
                    ? NSLocalizedString("pictures", comment: "Picture count: >1 pictures")
                    : NSLocalizedString("picture", comment: "Picture count: 1 picture")
            sectionInfo.stringValue = String(format: "%d %@", count, countLabel)
        }
    }

    private func toggleCollapse() {
        if let delegate = self.headerDelegate,
           Configuration.shared.isSectionCollapseAvailable
        {
            delegate.headerToggleCollapse(self)
            isCollapsed = !isCollapsed
        }
    }

    @IBAction func toggleCollapseButtonClicked(_ sender: NSButton) {
        self.toggleCollapse()
    }

    override func mouseDown(with event: NSEvent) {
        // Don't call super.mouseDown(with: event) here
        // it will clear selection in collectionView
        mouseButtonDown = true
        mouseButtonDownPosition = self.convert(event.locationInWindow, from: nil)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        if mouseButtonDown && Configuration.shared.collapseByClickingHeader {
            self.toggleCollapse()
        }
        mouseButtonDown = false
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let mouseDragPosition = self.convert(event.locationInWindow, from: nil)
        if mouseButtonDown &&
            ((fabs(Double(mouseDragPosition.x - mouseButtonDownPosition.x)) > minimumAllowedMouseDragDistance) ||
            (fabs(Double(mouseDragPosition.y - mouseButtonDownPosition.y)) > minimumAllowedMouseDragDistance))
        {
            mouseButtonDown = false
        }
    }

}
