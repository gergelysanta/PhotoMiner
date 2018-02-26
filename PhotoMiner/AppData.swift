//
//  AppData.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 21/02/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

class AppData: NSObject {
	
	static let shared = AppData()
	
	static let listOfFoldersRequiringAccessChanged  = Notification.Name("listOfFoldersRequiringAccessChanged")

	private(set) var lookupFolders = [String]()
	
	// Displayed image collection
	var imageCollection = ImageCollection(withDirectories: [])
	
	// Parsed but not yet displayed image collection
	// Loaded collection which have not yet granted access to all of it's directories
	// is stored here until access is not granted
	var parsedImageCollection:ImageCollection?
	
	// Set containing directory names which were already scanned
	// therefore access was already granted (user already requested access)
	private var accessGrantedFolders:Set<String> = []
	
	// Set containing directory names which are needed for displaying parsed image collection
	private(set) var accessNeededForFolders:Set<String> = [] {
		didSet {
			NotificationCenter.default.post(name: AppData.listOfFoldersRequiringAccessChanged, object: self)
		}
	}

	// Path to the opened scan if scan was loaded from a .pms file
	// nil if scan started by user (drag&drop)
	var openedFileUrl:URL? {
		didSet {
			loadedImageSetChanged = false
		}
	}
	var loadedImageSetChanged = false {
		didSet {
			if openedFileUrl == nil {
				// Do not allow to set if there's no opened file
				loadedImageSetChanged = false
			}
		}
	}
	
	// --------------------------------------------
	
	private override init() {
		super.init()
	}
	
	@discardableResult func setLookupDirectories(_ pathList: [String]) -> Bool {
		if lookupFolders.sorted() == pathList.sorted() {
			// The folder list is not going to change, return
			return true
		}
		var newLookupFolders = [String]()
		var isDirectory:ObjCBool = false
		var haveValidPath  = false
		for path in pathList {
			if FileManager.default.fileExists(atPath: path, isDirectory:&isDirectory) {
				if isDirectory.boolValue {
					// Path exists and is a directory -> add to lookupFolders list
					#if DEBUG
						NSLog("Add lookup folder: \(path)")
					#endif
					haveValidPath = true
					newLookupFolders.append(path)
				}
			}
		}
		if haveValidPath {
			lookupFolders = newLookupFolders
		}
		return haveValidPath
	}
	
	func addGrantedDirectories(_ directories: [String]) {
		accessGrantedFolders = accessGrantedFolders.union(directories)
	}
	
	func wasDirectoryGranted(_ directory: String) -> Bool {
		return accessGrantedFolders.contains(directory)
	}
	
	func cacheFolderForRequestingAccess(_ folder: String) {
		accessNeededForFolders = accessNeededForFolders.union([folder])
	}
	
	func grantAccessForCachedFolder(_ folder: String) -> Bool {
		return accessNeededForFolders.remove(folder) != nil
	}
	
	func cleanCachedFolders() {
		accessNeededForFolders = []
	}
	
}
