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

	// Array of all images in arranged order (arranged by months)
	var allImages:[ImageData] {
		get {
			if !allImagesArrayActualized {
				allImagesArray = [ImageData]()
				for monthKey in arrangedKeys {
					if let imagesOfMonth = dictionary[monthKey] {
						for storedImage in imagesOfMonth {
							allImagesArray.append(storedImage)
						}
					}
				}
				allImagesArrayActualized = true
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

		// Check if we have an array in our dictionary for this month
		if (dictionary[monthKey] == nil) {

			// Create new array for new month section
			dictionary[monthKey] = [ImageData]()

			// Add new key to arranged keys array and re-arrange the array
			arrangedKeys.append(monthKey)
			arrangedKeys.sort { Int($0)! > Int($1)! }
		}

		// Add image to the month array
		if let imagesOfMonth = dictionary[monthKey] {
			var index = 0
			for imageInArray in imagesOfMonth {
				if image.creationDate > imageInArray.creationDate {
					break
				}
				index += 1
			}

			if index >= imagesOfMonth.count {
				dictionary[monthKey]?.append(image)
			}
			else {
				dictionary[monthKey]?.insert(image, at: index)
			}
			count += 1
			allImagesArrayActualized = false
		}

		return true
	}

	/// Remove an image from the collection
	/// - Parameter image: image data
	func removeImage(_ image:ImageData) -> Bool {
		var imageRemoved = false
		for monthKey in arrangedKeys {
			if let imagesOfMonth = dictionary[monthKey] {
				if let imageIndex = imagesOfMonth.firstIndex(of: image) {
					dictionary[monthKey]?.remove(at: imageIndex)
					count -= 1
					allImagesArrayActualized = false
					imageRemoved = true
					break
				}
				if dictionary[monthKey]?.count == 0 {
					dictionary.removeValue(forKey: monthKey)
					if let index = arrangedKeys.firstIndex(of: monthKey) {
						arrangedKeys.remove(at: index)
					}
				}
			}
		}
		return imageRemoved
	}

	/// Remove an image specified by path from the collection
	/// - Parameter path: path to the image
	@discardableResult func removeImage(withPath path:String) -> Bool {
		var imageRemoved = false
		for monthKey in arrangedKeys {
			if let imagesOfMonth = dictionary[monthKey] {
				for (index, storedImage) in imagesOfMonth.enumerated() where storedImage.imagePath == path {
					dictionary[monthKey]?.remove(at: index)
					count -= 1
					allImagesArrayActualized = false
					imageRemoved = true
					break
				}
				if dictionary[monthKey]?.count == 0 {
					dictionary.removeValue(forKey: monthKey)
					if let index = arrangedKeys.firstIndex(of: monthKey) {
						arrangedKeys.remove(at: index)
					}
				}
			}
		}
		return imageRemoved
	}

	/// Find an image in the collection by it's name
	/// - Parameter name: image name
	func image(withName name: String) -> ImageData? {
		for monthKey in arrangedKeys {
			if let imagesOfMonth = dictionary[monthKey] {
				for storedImage in imagesOfMonth {
					if name == storedImage.imageName {
						return storedImage
					}
				}
			}
		}
		return nil
	}

	/// Find an image in the collection by it's path
	/// - Parameter path: image path
	func image(withPath path: String) -> ImageData? {
		for monthKey in arrangedKeys {
			if let imagesOfMonth = dictionary[monthKey] {
				for storedImage in imagesOfMonth {
					if path == storedImage.imagePath {
						return storedImage
					}
				}
			}
		}
		return nil
	}

	/// Find an image in the collection by it's index path
	/// - Parameter indexPath: index path
	func image(withIndexPath indexPath: IndexPath) -> ImageData? {
		if indexPath.section < arrangedKeys.count {
			let monthKey = arrangedKeys[indexPath.section]
			if let imagesOfMonth = dictionary[monthKey] {
				if indexPath.item < imagesOfMonth.count {
					return imagesOfMonth[indexPath.item]
				}
			}
		}
		return nil
	}

	/// Get index path of an image
	/// - Parameter image: image data
	func indexPath(of image:ImageData) -> IndexPath? {
		for section in 0..<arrangedKeys.count {
			let monthKey = arrangedKeys[section]
			if let imagesOfMonth = dictionary[monthKey] {
				for item in 0..<imagesOfMonth.count {
					if imagesOfMonth[item] == image {
						return IndexPath(item: item, section: section)
					}
				}
			}
		}
		return nil
	}

	private var exportRunning = false

	func exportStart(toDirectory: URL, removeOriginals: Bool = false, reportProgress: @escaping (_ sourcePath: String, _ destinationPath: String, _ percentComplete: Double)->Void, onCompletion: @escaping ()->Void) {
		exportRunning = true
		DispatchQueue(label: "new.quque").async {
			for percent in (1...100) {
				guard self.exportRunning == true else {
					break
				}
				DispatchQueue.main.sync {
					reportProgress("", "", Double(percent))
				}
				usleep(100000)
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
