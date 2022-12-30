//
//  Configuration.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 08/12/2016.
//  Copyright © 2016 Gergely Sánta. All rights reserved.
//

import Cocoa

/// Application configuratio singleton
class Configuration: NSObject {

    /// Shared object
    static let shared = Configuration()

    /// Ignore images smaller than this size
    let ignoreImagesBelowSize = 51200              // 50kB (50 * 1024 = 51200)

    /// Minimum width of sidepanel
    let sidepanelMinWidth = 150

    /// Maximum width of sidepanel
    let sidePanelMaxWidth = 500

    /// Extension of exported scan file
    let saveDataExtension = "pms"

    /// Use date of image creation as thumbnail label
    @StoredConfig(key: "creationDateAsLabel", defaultValue: true)
    @objc dynamic var creationDateAsLabel: Bool

    /// Ask for confirmation if old scan exists and new scan was requested
    @StoredConfig(key: "newScanMustBeConfirmed", defaultValue: true)
    @objc dynamic var newScanMustBeConfirmed: Bool

    /// Ask for confirmation before removing images
    @StoredConfig(key: "removeMustBeConfirmed", defaultValue: true)
    @objc dynamic var removeMustBeConfirmed: Bool

    /// Remove also directory after removing an image if this was the last file in it
    @StoredConfig(key: "removeAlsoEmptyDirectories", defaultValue: false)
    @objc dynamic var removeAlsoEmptyDirectories: Bool

    /// Hightlight images which have no EXIF data
    @StoredConfig(key: "highlightPicturesWithoutExif", defaultValue: false)
    @objc dynamic var highlightPicturesWithoutExif: Bool

    /// Collapse groups by clicking header (not just the arrow on the left side)
    @StoredConfig(key: "collapseByClickingHeader", defaultValue: false)
    @objc dynamic var collapseByClickingHeader: Bool

    /// Search for images
    @StoredConfig(key: "searchForImages", defaultValue: true)
    @objc dynamic var searchForImages: Bool

    /// Search for movie files
    @StoredConfig(key: "searchForMovies", defaultValue: true)
    @objc dynamic var searchForMovies: Bool

    /// Display warning if previous scan was parsed from a file (warning about needing to drag&drop the directories to the app)
    @StoredConfig(key: "displayWarningForParsedScans", defaultValue: true)
    var displayWarningForParsedScans: Bool

    /// Remove original image after it was exported
    @StoredConfig(key: "removeOriginalAfterExportingImages", defaultValue: false)
    @objc dynamic var removeOriginalAfterExportingImages: Bool

    // Flag indication if collapsing section is available on this system (available only from 10.12)
    @objc dynamic var isSectionCollapseAvailable:Bool {
        get {
            if #available(OSX 10.12, *) {
                return true
            }
            return false
        }
    }

}
