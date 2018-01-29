//
//  ImageCollection.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 28/02/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

class ImageCollection: NSObject, Codable {

	private(set) var rootDirs = [String]()					// Scanned directories
	private(set) var dictionary = [String:[ImageData]]()	// Dictionary have unarranged keys
	private(set) var arrangedKeys = [String]()				// So we're storing arranged keys here
	private(set) var count:Int = 0							// Count of all objects in dictionary
	
	private var allImagesArray = [ImageData]()				// Inner array caching arranged array of all images when requested
	private var allImagesArrayActualized = false			// Flag indicating if inner array of all images is actualized
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
	
	public enum CodingKeys: String, CodingKey {
		case rootDirs = "root"
		case dictionary = "images"
		case arrangedKeys = "ordered"
		case count = "count"
	}
	
	// Encode object to serialized data
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(rootDirs, forKey: .rootDirs)
		try container.encode(dictionary, forKey: .dictionary)
		try container.encode(arrangedKeys, forKey: .arrangedKeys)
		try container.encode(count, forKey: .count)
	}
	
	// Initializing object from serialized data
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
	
	func removeDirectory(_ directory:String) {
		if let index = rootDirs.index(of: directory) {
			rootDirs.remove(at: index)
		}
	}
	
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
	
	func removeImage(_ image:ImageData) -> Bool {
		var imageRemoved = false
		for monthKey in arrangedKeys {
			if let imagesOfMonth = dictionary[monthKey] {
				if let imageIndex = imagesOfMonth.index(of: image) {
					dictionary[monthKey]?.remove(at: imageIndex)
					count -= 1
					allImagesArrayActualized = false
					imageRemoved = true
					break
				}
				if dictionary[monthKey]?.count == 0 {
					dictionary.removeValue(forKey: monthKey)
					if let index = arrangedKeys.index(of: monthKey) {
						arrangedKeys.remove(at: index)
					}
				}
			}
		}
		return imageRemoved
	}
	
	func removeImage(withPath path:String) -> Bool {
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
					if let index = arrangedKeys.index(of: monthKey) {
						arrangedKeys.remove(at: index)
					}
				}
			}
		}
		return imageRemoved
	}
	
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
	
}
