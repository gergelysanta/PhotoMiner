//
//  ImageCollection.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 28/02/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

/// Class representing collection of images on the disk
class ImageCollection: NSObject, Codable {

    /// Directories where collection are images are located (directories which were scanned)
    private(set) var rootDirs = [String]()

    /// Dictionary of images grouped in months (keys are representing months)
    private(set) var dictionary = [String:[ImageData]]()

    // Arranged keys of image collection keys (months)
    private(set) var arrangedKeys = [String]()

    /// Count of all objects in dictionary
    private(set) var count:Int = 0

    /// Inner array caching arranged array of all images when requested
    private var allImagesArray = [ImageData]()

    /// Flag indicating if inner array of all images is actualized
    private var allImagesArrayActualized = false

    /// Queue for synchronizing database management. Implements multiple reads and exclusive write operation.
    private let syncQueue = DispatchQueue(label: "ImageCollectionSyncQueue", attributes: .concurrent)

    /// Array of all images in arranged order (arranged by months)
    var allImages:[ImageData] {
        get {
            syncQueue.sync { [unowned self] in
                if !self.allImagesArrayActualized {
                    self.allImagesArray = [ImageData]()
                    for monthKey in self.arrangedKeys {
                        if let imagesOfMonth = self.dictionary[monthKey] {
                            for storedImage in imagesOfMonth {
                                self.allImagesArray.append(storedImage)
                            }
                        }
                    }
                    self.allImagesArrayActualized = true
                }
            }
            return allImagesArray
        }
    }

    //
    // MARK: - Serialization
    //

    /// Keys for serializing this object
    public enum CodingKeys: String, CodingKey {
        case rootDirs = "root"
        case dictionary = "images"
        case arrangedKeys = "ordered"
        case count = "count"
    }

    /// Encode object to serialized data
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rootDirs, forKey: .rootDirs)
        try container.encode(dictionary, forKey: .dictionary)
        try container.encode(arrangedKeys, forKey: .arrangedKeys)
        try container.encode(count, forKey: .count)
    }

    /// Initializing object from serialized data
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rootDirs = try values.decode([String].self, forKey: .rootDirs)
        dictionary = try values.decode([String:[ImageData]].self, forKey: .dictionary)
        arrangedKeys = try values.decode([String].self, forKey: .arrangedKeys)
        count = try values.decode(Int.self, forKey: .count)
    }

    //
    // MARK: - Instance methods
    //

    // Disable default constructor (by making it private)
    override private init() {
        super.init()
    }

    convenience init(withDirectories scanDirectories: [String]) {
        self.init()
        rootDirs = scanDirectories
    }

    /// Add a directory to the array of root dirs
    /// - Parameter directory: new directory path
    func removeDirectory(_ directory:String) {
        if let index = rootDirs.firstIndex(of: directory) {
            rootDirs.remove(at: index)
        }
    }

    /// Add an image to the collection. Method will create a new group (months) for this image if that do not yet exists.
    /// - Parameter image: image data
    func addImage(_ image:ImageData) -> Bool {

        // Construct key for creating month of the new image
        let dateComponents = Calendar.current.dateComponents([.year, .month], from:image.creationDate)
        let monthKey = String(format:"%04ld%02ld", dateComponents.year!, dateComponents.month!)

        syncQueue.sync(flags: .barrier) { [unowned self] in
            // Check if we have an array in our dictionary for this month
            if (self.dictionary[monthKey] == nil) {

                // Create new array for new month section
                self.dictionary[monthKey] = [ImageData]()

                // Add new key to arranged keys array and re-arrange the array
                self.arrangedKeys.append(monthKey)
                self.arrangedKeys.sort { Int($0)! > Int($1)! }
            }

            // Add image to the month array
            if let imagesOfMonth = self.dictionary[monthKey] {
                var index = 0
                for imageInArray in imagesOfMonth {
                    if image.creationDate > imageInArray.creationDate {
                        break
                    }
                    index += 1
                }

                if index >= imagesOfMonth.count {
                    self.dictionary[monthKey]?.append(image)
                }
                else {
                    self.dictionary[monthKey]?.insert(image, at: index)
                }
                self.count += 1
                self.allImagesArrayActualized = false
            }
        }

        return true
    }

    /// Remove an image from the collection
    /// - Parameter image: image data
    @discardableResult
    func removeImage(_ image:ImageData) -> Bool {
        var imageRemoved = false
        syncQueue.sync(flags: .barrier) { [unowned self] in
            for monthKey in self.arrangedKeys {
                if let imagesOfMonth = self.dictionary[monthKey] {
                    if let imageIndex = imagesOfMonth.firstIndex(of: image) {
                        self.dictionary[monthKey]?.remove(at: imageIndex)
                        self.count -= 1
                        self.allImagesArrayActualized = false
                        imageRemoved = true
                        break
                    }
                    if self.dictionary[monthKey]?.count == 0 {
                        self.dictionary.removeValue(forKey: monthKey)
                        if let index = self.arrangedKeys.firstIndex(of: monthKey) {
                            self.arrangedKeys.remove(at: index)
                        }
                    }
                }
            }
        }
        return imageRemoved
    }

    /// Remove an image specified by path from the collection
    /// - Parameter path: path to the image
    @discardableResult
    func removeImage(withPath path:String) -> Bool {
        var imageRemoved = false
        syncQueue.sync(flags: .barrier) { [unowned self] in
            for monthKey in self.arrangedKeys {
                if let imagesOfMonth = self.dictionary[monthKey] {
                    for (index, storedImage) in imagesOfMonth.enumerated() where storedImage.imagePath == path {
                        self.dictionary[monthKey]?.remove(at: index)
                        self.count -= 1
                        self.allImagesArrayActualized = false
                        imageRemoved = true
                        break
                    }
                    if self.dictionary[monthKey]?.count == 0 {
                        self.dictionary.removeValue(forKey: monthKey)
                        if let index = self.arrangedKeys.firstIndex(of: monthKey) {
                            self.arrangedKeys.remove(at: index)
                        }
                    }
                }
            }
        }
        return imageRemoved
    }

    /// Find an image in the collection by it's name
    /// - Parameter name: image name
    func image(withName name: String) -> ImageData? {
        var foundImage: ImageData?
        syncQueue.sync { [unowned self] in
            for monthKey in self.arrangedKeys {
                if let imagesOfMonth = self.dictionary[monthKey] {
                    for storedImage in imagesOfMonth {
                        if name == storedImage.imageName {
                            foundImage = storedImage
                            return
                        }
                    }
                }
            }
        }
        return foundImage
    }

    /// Find an image in the collection by it's path
    /// - Parameter path: image path
    func image(withPath path: String) -> ImageData? {
        var foundImage: ImageData?
        syncQueue.sync { [unowned self] in
            for monthKey in self.arrangedKeys {
                if let imagesOfMonth = self.dictionary[monthKey] {
                    for storedImage in imagesOfMonth {
                        if path == storedImage.imagePath {
                            foundImage = storedImage
                            return
                        }
                    }
                }
            }
        }
        return foundImage
    }

    /// Find an image in the collection by it's index path
    /// - Parameter indexPath: index path
    func image(withIndexPath indexPath: IndexPath) -> ImageData? {
        var foundImage: ImageData?
        syncQueue.sync { [unowned self] in
            if indexPath.section < self.arrangedKeys.count {
                let monthKey = self.arrangedKeys[indexPath.section]
                if let imagesOfMonth = self.dictionary[monthKey] {
                    if indexPath.item < imagesOfMonth.count {
                        foundImage = imagesOfMonth[indexPath.item]
                        return
                    }
                }
            }
        }
        return foundImage
    }

    /// Get index path of an image
    /// - Parameter image: image data
    func indexPath(of image:ImageData) -> IndexPath? {
        var foundIndexPath: IndexPath?
        syncQueue.sync { [unowned self] in
            for section in 0..<self.arrangedKeys.count {
                let monthKey = self.arrangedKeys[section]
                if let imagesOfMonth = self.dictionary[monthKey] {
                    for item in 0..<imagesOfMonth.count {
                        if imagesOfMonth[item] == image {
                            foundIndexPath = IndexPath(item: item, section: section)
                            return
                        }
                    }
                }
            }
        }
        return foundIndexPath
    }

    private var exportRunning = false

    func exportStart(toDirectory destination: URL, removeOriginals: Bool = false, reportProgress: @escaping (_ sourcePath: String, _ destinationPath: String, _ percentComplete: Double)->Void, onCompletion: @escaping ()->Void) {
        exportRunning = true
        DispatchQueue(label: "com.trikatz.exportQueue").async {

            let fileManager = FileManager.default

            // Number of already exported images
            var exportCount = 0

            self.syncQueue.sync { [unowned self] in
                // Iterate through months
                for monthKey in self.arrangedKeys {
                    if !self.exportRunning { break }

                    // Split month key into year and month
                    let year = String(monthKey.prefix(4))
                    let month = String(monthKey.suffix(2))

                    // Create directory
                    let monthDir = destination.appendingPathComponent("\(year)/\(month)")
                    do {
                        try fileManager.createDirectory(at: monthDir, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        let errorStr = String.localizedStringWithFormat(NSLocalizedString("Couldn't create directory %@: %@", comment: "Couldn't create directory"), monthDir.path, error.localizedDescription)
                        NSLog(errorStr)
                        DispatchQueue.main.sync {
                            NotificationCenter.default.post(name: AppData.displayAlertDialog, object: nil, userInfo: ["error": errorStr])
                        }
                        self.exportRunning = false
                        continue
                    }

                    // Iterate through images of this month and export them
                    if let imagesOfMonth = self.dictionary[monthKey] {
                        for storedImage in imagesOfMonth {
                            if !self.exportRunning { break }

                            let sourcePath = URL(fileURLWithPath: storedImage.imagePath)
                            let destinationPath = fileManager.nextAvailable(path: monthDir.appendingPathComponent(storedImage.imageName))

                            // Report progress
                            DispatchQueue.main.sync {
                                reportProgress(sourcePath.path, destinationPath.path, (Double(exportCount)/Double(self.count)) * 100.0)
                            }

                            // Copy/move image
                            do {
                                if removeOriginals {
                                    // Move the image
                                    try fileManager.moveItem(at: sourcePath, to: destinationPath)
                                    // Check if source directory was left empty and remove if needed
                                    if Configuration.shared.removeAlsoEmptyDirectories {
                                        fileManager.removeDirIfEmpty(sourcePath.deletingLastPathComponent())
                                    }
                                    // Remove image data from our collection
                                    self.removeImage(storedImage)
                                } else {
                                    try fileManager.copyItem(at: sourcePath, to: destinationPath)
                                }
                            } catch {
                                let errorStr = String.localizedStringWithFormat(NSLocalizedString("Couldn't export image %@: %@", comment: "Couldn't export image"), destinationPath.path, error.localizedDescription)
                                NSLog(errorStr)
                                DispatchQueue.main.sync {
                                    NotificationCenter.default.post(name: AppData.displayAlertDialog, object: nil, userInfo: ["error": errorStr])
                                }
                                self.exportRunning = false
                                continue
                            }

                            exportCount += 1
                        }
                    }
                }
            }
            self.exportRunning = false
            DispatchQueue.main.sync {
                onCompletion()
            }
        }
    }

    func exportStop() {
        exportRunning = false
    }

}
