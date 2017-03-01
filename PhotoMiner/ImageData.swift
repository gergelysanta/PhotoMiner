//
//  ImageData.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class ImageData: NSObject {
	
	private(set) var imagePath:String!
	private(set) var imageName:String!
	private(set) var imageThumbnail:NSImage?
	private(set) var creationDate:Date = Date()
	
	private(set) var imageSize:NSSize = NSZeroSize
	private(set) var isLandscape:Bool = false
	
	private let thumbnailQueue = DispatchQueue(label: "com.trikatz.thumbnailQueue", qos: .utility)
	private let mainQueue = DispatchQueue.main
	
	//
	// MARK: Class/Type methods and arguments
	//
	
	// Lazy initialization of dateFormatter
	// This initialization will be called only once, when static variable is used first-time
	static let dateFormatter:DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
		return formatter
	}()
	
	//
	// MARK: Instance methods
	//
	
	// Disable default constructor (by making it private)
	private override init() {
		super.init()
	}

	convenience init (path:String, creationDate:Date) {
		self.init()
		self.imagePath = path
		self.imageName = URL(fileURLWithPath: path).lastPathComponent
		self.creationDate = creationDate
		detectSizeAndCreationDate()
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
	
	private func detectSizeAndCreationDate() {
		if let imageSource = self.createImageSource() {
			let options:CFDictionary = [ kCGImageSourceShouldCache as String : false ] as CFDictionary
			if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options) as? [String: AnyObject] {
				guard let width = imageProperties[kCGImagePropertyPixelWidth as String]?.doubleValue else { return }
				guard let height = imageProperties[kCGImagePropertyPixelHeight as String]?.doubleValue else { return }
				
				if let orientation = imageProperties[kCGImagePropertyOrientation as String]?.int8Value {
					if orientation <= 4 {
						self.imageSize = NSSize(width: width, height: height)
					}
					else {
						self.imageSize = NSSize(width: height, height: width)
					}
				}
				else {
					self.imageSize = NSSize(width: width, height: height)
				}
				
				if self.imageSize.width > self.imageSize.height {
					self.isLandscape = true
				}
				
				if let exifDictionary = imageProperties[kCGImagePropertyExifDictionary as String] {
					if let dateTakenString = exifDictionary[kCGImagePropertyExifDateTimeOriginal as String] as? String {
						if let exifCreationDate = ImageData.dateFormatter.date(from: dateTakenString) {
							self.creationDate = exifCreationDate
						}
					}
				}
			}
		}
	}

	//
	// MARK: Load thumbnail in operation queue
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
					self.mainQueue.sync {
						self.willChangeValue(forKey: "imageThumbnail")
						self.imageThumbnail = image
						self.didChangeValue(forKey: "imageThumbnail")
					}
				}
			}
		}
	}
	
}
