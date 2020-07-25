//
//  ImageData.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa
import AVKit

/// Class representing an image on the disk
class ImageData: NSObject, Codable {

    /// Absolute path to the image
    private(set) var imagePath:String!

    /// Name of the image (file name)
    private(set) var imageName:String!

    /// Thumbnail
    @objc dynamic private(set) var imageThumbnail:NSImage?

    /// Date when image was created (from EXIF or file creation date)
    private(set) var creationDate:Date = Date()

    /// Image dimensions
    private(set) var dimensions:NSSize = NSZeroSize

    /// Is this image a landscape?
    private(set) var isLandscape:Bool = false

    /// Is this a movie file?
    private(set) var isMovie:Bool = false

    /// EXIF data of the image
    private(set) var exifData = [String: AnyObject]()

    /// GPS data of the image
    private(set) var gpsData = [String: AnyObject]()

    /// Has this image EXIF data?
    var hasExif:Bool {
        return exifData.keys.count > 0
    }

    /// Has this image GPS data?
    var hasGPS:Bool {
        return gpsData.keys.count > 0
    }

    /// Dispatch queue used for generating thumbnail
    private let thumbnailQueue = DispatchQueue(label: "com.trikatz.thumbnailQueue", qos: .utility)

    /// Flag indicating whether image properties were already parsed
    private var imagePropertiesParsed = false

    //
    // MARK: - Class/Type methods and arguments
    //

    // Lazy initialization of dateFormatter
    // This initialization will be called only once, when static variable is used first-time
    static let dateFormatter:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }()

    //
    // MARK: - Serialization
    //

    /// Keys for serializing this object
    public enum CodingKeys: String, CodingKey {
        case imagePath = "path"
        case imageName = "name"
        case creationDate = "date"
        case dimensions
        case isLandscape = "landscape"
    }

    /// Encode object to serialized data
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imagePath, forKey: .imagePath)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(dimensions, forKey: .dimensions)
        try container.encode(isLandscape, forKey: .isLandscape)
    }

    /// Initializing object from serialized data
    required init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        imagePath = try values.decode(String.self, forKey: .imagePath)
        imageName = try values.decode(String.self, forKey: .imageName)
        creationDate = try values.decode(Date.self, forKey: .creationDate)
        dimensions = try values.decode(NSSize.self, forKey: .dimensions)
        isLandscape = try values.decode(Bool.self, forKey: .isLandscape)
    }


    //
    // MARK: - Instance methods
    //

    // Disable default constructor (by making it private)
    private override init() {
        super.init()
    }

    convenience init (path:String, creationDate:Date, isMovie:Bool = false) {
        self.init()
        self.imagePath = path
        self.imageName = URL(fileURLWithPath: path).lastPathComponent
        self.creationDate = creationDate
        self.isMovie = isMovie
        parseImageProperties()
    }

    convenience init (path:String) {
        self.init(path:path, creationDate:Date())
    }

    private func createImageSource() -> CGImageSource? {

        // Compose absolute URL to file
        let sourceURL = URL(fileURLWithPath: imagePath)

        // Create a CGImageSource from the URL
        if let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) {
            if CGImageSourceGetType(imageSource) != nil {
                return imageSource
            }
        }

        return nil
    }

    /// Parse image properties only (works only for images, not movies)
    func parseImageProperties() {
        if imagePropertiesParsed { return }
        imagePropertiesParsed = true

        if let imageSource = self.createImageSource() {
            let options:CFDictionary = [ kCGImageSourceShouldCache as String : false ] as CFDictionary
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options) as? [String: AnyObject] {
                guard let width = imageProperties[kCGImagePropertyPixelWidth as String]?.doubleValue else { return }
                guard let height = imageProperties[kCGImagePropertyPixelHeight as String]?.doubleValue else { return }

                if let orientation = imageProperties[kCGImagePropertyOrientation as String]?.int8Value {
                    if orientation <= 4 {
                        self.dimensions = NSSize(width: width, height: height)
                    }
                    else {
                        self.dimensions = NSSize(width: height, height: width)
                    }
                }
                else {
                    self.dimensions = NSSize(width: width, height: height)
                }

                if self.dimensions.width > self.dimensions.height {
                    self.isLandscape = true
                }

                if let gpsDictionary = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: AnyObject] {
                    gpsData = gpsDictionary
                }

                if let exifDictionary = imageProperties[kCGImagePropertyExifDictionary as String] as? [String: AnyObject] {
                    exifData = exifDictionary
                    if let dateTakenString = exifData[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                        if let exifCreationDate = ImageData.dateFormatter.date(from: dateTakenString) {
                            self.creationDate = exifCreationDate
                        }
                    }
                }
            }
        }
    }

    //
    // MARK: - Load thumbnail in operation queue
    //

    /* Many kinds of image files contain prerendered thumbnail images that can be quickly loaded without having to decode
     * the entire contents of the image file and reconstruct the full-size image.
     * The ImageIO framework's CGImageSource API provides a means to do this, using the CGImageSourceCreateThumbnailAtIndex() function.
     * For more information on CGImageSource objects and their capabilities, see the CGImageSource reference
     * on the Apple Developer Connection website,
     * at http://developer.apple.com/documentation/GraphicsImaging/Reference/CGImageSource/Reference/reference.html
     */

    func setThumbnail() {
        thumbnailQueue.async {
            if self.isMovie {
                self.setMovieThumbnail()
            } else {
                self.setImageThumbnail()
            }
        }
    }

    /// Generate thumbnail of an image and store it in property `imageThumbnail`
    private func setImageThumbnail() {
        if let imageSource = self.createImageSource() {
            let options:CFDictionary = [
                    // Ask ImageIO to create a thumbnail from the file's image data, if it can't find
                    // a suitable existing thumbnail image in the file.  We could comment out the following
                    // line if only existing thumbnails were desired for some reason (maybe to favor
                    // performance over being guaranteed a complete set of thumbnails).
                    kCGImageSourceCreateThumbnailFromImageIfAbsent as String : true,
                    kCGImageSourceCreateThumbnailWithTransform as String : true,
                    kCGImageSourceThumbnailMaxPixelSize as String : 148
                ] as CFDictionary
            if let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) {
                let image = NSImage(cgImage: thumbnail, size: NSZeroSize)
                DispatchQueue.main.sync {
                    self.willChangeValue(forKey: "imageThumbnail")
                    self.imageThumbnail = image
                    self.didChangeValue(forKey: "imageThumbnail")
                }
            }
        }
    }

    /// Generate thumbnail of a movie and store it in property `imageThumbnail`
    private func setMovieThumbnail() {
        // Create asset
        let asset = AVURLAsset(url: URL(fileURLWithPath: self.imagePath))
        let assetGenerator = AVAssetImageGenerator(asset: asset)
        assetGenerator.appliesPreferredTrackTransform = true
        assetGenerator.maximumSize = CGSize(width: 320, height: 320)

        let time = CMTime(seconds: Double(asset.duration.value / 2), preferredTimescale: 600)

        assetGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { (requestedTime: CMTime, image: CGImage?, actualTime: CMTime, result: AVAssetImageGenerator.Result, error: Error?) in
            if let generateError = error {
                #if DEBUG
                NSLog("ERROR Generating movie thumbnail: \(generateError.localizedDescription)")
                #endif
                return
            }

            if result != .succeeded {
                #if DEBUG
                NSLog("ERROR Generating movie thumbnail")
                #endif
                return
            }

            guard let cgImage = image else {
                #if DEBUG
                NSLog("ERROR Generating movie thumbnail: No image")
                #endif
                return
            }
            let thumbnailImage = NSImage(cgImage: cgImage, size: .zero)

            DispatchQueue.main.sync {
                self.willChangeValue(forKey: "imageThumbnail")
                self.imageThumbnail = thumbnailImage
                self.didChangeValue(forKey: "imageThumbnail")
            }
        }
    }

}
