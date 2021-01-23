//
//  ThumbnailViewItem.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol ThumbnailViewItemDelegate {
    func thumbnailClicked(_ thumbnail: ThumbnailViewItem, with event: NSEvent)
    func thumbnailRightClicked(_ thumbnail: ThumbnailViewItem, with event: NSEvent)
}

class ThumbnailViewItem: NSCollectionViewItem {

    var delegate:ThumbnailViewItemDelegate? = nil

    @IBOutlet private var tag: NSTextField!

    override var isSelected:Bool {
        didSet {
            updateBackground()
        }
    }

    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            updateBackground()
        }
    }

    private(set) var hasBorder = false {
        didSet {
            updateBackground()
        }
    }

    override var representedObject:Any? {
        didSet {
            if let object = representedObject as? ImageData {
                object.setThumbnail(inQueue: AppData.shared.imageOperationQueue)
                hasBorder = Configuration.shared.highlightPicturesWithoutExif ? !object.hasExif : false

                self.textField?.stringValue = object.imageName
                if Configuration.shared.creationDateAsLabel {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    self.textField?.stringValue = formatter.string(from: object.creationDate)
                }

                if object.isMovie {
                    self.tag.isHidden = false
                    self.tag.stringValue = "🎦"
                } else {
                    self.tag.isHidden = true
                }

                self.imageView?.bind(NSBindingName(rawValue: "value"), to: object, withKeyPath: "imageThumbnail", options: nil)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        view.layer?.backgroundColor = Colors.Thumbnail.frameColor.cgColor
        view.layer?.cornerRadius = 4.0

        // We re-set the representedObject for the case it was set before this function call
        let object = self.representedObject
        self.representedObject = object

        updateBackground()
    }

    func updateBackground() {
        if isSelected || (highlightState == .forSelection){
            view.layer?.backgroundColor = Colors.Thumbnail.frameColorSelected.cgColor
            view.layer?.borderColor = Colors.Thumbnail.borderColorSelected.cgColor
            textField?.textColor = Colors.Thumbnail.textColorSelected
        }
        else {
            view.layer?.backgroundColor = Colors.Thumbnail.frameColor.cgColor
            view.layer?.borderColor = Colors.Thumbnail.borderColor.cgColor
            textField?.textColor = Colors.Thumbnail.textColor
        }
        view.layer?.borderWidth = hasBorder ? 2.0 : 0.0
    }

    // MARK: - Mouse events
    //

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        self.delegate?.thumbnailClicked(self, with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        self.delegate?.thumbnailRightClicked(self, with: event)
    }

}
