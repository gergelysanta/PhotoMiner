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
	
	private(set) var lookupFolders = [String]()
	
	// Set containing directory names which were already scanned
	// therefore access was already granted (user already requested access)
	private var accessGrantedFolders:Set<String> = []
	
	private var accessDeniedFolders:Set<String> = []

	// Path to the opened scan if scan was loaded from a .pms file
	// nil if scan started by user (drag&drop)
	var openedFileUrl:URL? {
		didSet {
			openedFileChanged = false
		}
	}
	var openedFileChanged = false
	
	// --------------------------------------------
	
	private override init() {
		super.init()
	}
	
	@discardableResult func setLookupDirectories(_ pathList: [String]) -> Bool {
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
			openedFileUrl = nil
		}
		return haveValidPath
	}
	
	func addGrantedDirectories(_ directories: [String]) {
		accessGrantedFolders = accessGrantedFolders.union(directories)
	}
	
	func wasDirectoryGranted(_ directory: String) -> Bool {
		return accessGrantedFolders.contains(directory)
	}
	
}
