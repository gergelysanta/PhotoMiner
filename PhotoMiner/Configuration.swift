//
//  Configuration.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 08/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class Configuration: NSObject {
	
	var lookupFolders = [String]()
	let ignoreImagesBelowSize = 51200		// 50kB (50 * 1024 = 51200)

	var creationDateAsLabel = true {
		didSet {
			self.saveConfiguration()
		}
	}
	
	var removeMustBeConfirmed = true {
		didSet {
			self.saveConfiguration()
		}
	}
	
	var removeAlsoEmptyDirectories = true {
		didSet {
			self.saveConfiguration()
		}
	}
	
	override init() {
		super.init()
		creationDateAsLabel = UserDefaults.standard.bool(forKey: "creationDateAsLabel")
		removeMustBeConfirmed = UserDefaults.standard.bool(forKey: "removeMustBeConfirmed")
		removeAlsoEmptyDirectories = UserDefaults.standard.bool(forKey: "removeAlsoEmptyDirectories")
	}
	
	func setLookupDirectories(_ pathList: [String]) -> Bool {
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
	
	func saveConfiguration() {
		UserDefaults.standard.set(creationDateAsLabel, forKey: "creationDateAsLabel")
		UserDefaults.standard.set(removeMustBeConfirmed, forKey: "removeMustBeConfirmed")
		UserDefaults.standard.set(removeAlsoEmptyDirectories, forKey: "removeAlsoEmptyDirectories")
		UserDefaults.standard.synchronize()
	}
	
}
