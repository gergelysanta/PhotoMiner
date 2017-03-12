//
//  ImageCollection.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 28/02/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

class ImageCollection: NSObject {

	private(set) var dictionary = [String:[ImageData]]()	// Dictionary have unarranged keys
	private(set) var arrangedKeys = [String]()				// So we're storing arranged keys here
	private(set) var count = 0								// Count of all objects in dictionary
	
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
	
	func addImage(_ image:ImageData) -> Bool {
		
		// Construct key for creation month of the new image
		let dateComponents = Calendar.current.dateComponents([.year, .month], from:image.creationDate)
		let monthKey = String(format:"%ld%02ld", dateComponents.year!, dateComponents.month!)
		
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