//
//  PhotoCollectionView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 04/03/2017.
//  Copyright © 2017 Gergely Sánta. All rights reserved.
//

import Cocoa

protocol PhotoCollectionViewDelegate {
    func keyPress(_ collectionView: PhotoCollectionView, with event: NSEvent) -> Bool
    func preReloadData(_ collectionView: PhotoCollectionView)
    func postReloadData(_ collectionView: PhotoCollectionView)
    func drag(_ collectionView: PhotoCollectionView, session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation)
}

class PhotoCollectionView: NSCollectionView {

    var keyDelegate:PhotoCollectionViewDelegate? = nil

    private var lastAppearanceName = NSAppearance.Name(rawValue: "unknown")

    override func keyDown(with event: NSEvent) {
        var eventHandled = false
        if let delegate = self.keyDelegate {
            eventHandled = delegate.keyPress(self, with: event)
        }
        if !eventHandled {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if #available(OSX 10.14, *) {
            // Check if appearance changed (light->dark, or dark->light)
            let appearanceName = NSApp.effectiveAppearance.name
            if lastAppearanceName != appearanceName {
                // Refresh background for all thumbnails
                #if DEBUG
                    NSLog("Appearance changed to '\(appearanceName.rawValue)', update thumbnails")
                #endif
                for item in self.visibleItems() {
                    if let thumbnailItem = item as? ThumbnailViewItem {
                        thumbnailItem.updateBackground()
                    }
                }
                lastAppearanceName = appearanceName
            }
        }
    }

    override func reloadData() {
        keyDelegate?.preReloadData(self)
        super.reloadData()
        keyDelegate?.postReloadData(self)
    }

    override func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        switch(context) {
        case .outsideApplication:
            return [ .copy, .link, .generic, .delete, .move ]
        case .withinApplication:
            return []
        @unknown default:
            #if DEBUG
            NSLog("Unknown dragging context: \(context)")
            #endif
            return []
        }
    }

    override func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        super.draggingSession(session, endedAt: screenPoint, operation: operation)
        keyDelegate?.drag(self, session: session, endedAt: screenPoint, operation: operation)
    }

}
