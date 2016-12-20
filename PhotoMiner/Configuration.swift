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

	override init() {
		super.init()
		if let directories = UserDefaults.standard.stringArray(forKey: "lookupFolders") {
			lookupFolders = directories
		}
		else {
			lookupFolders = defaultFileList()
			saveConfiguration()
		}
	}
	
	func homeDirectory() -> String {
		return NSHomeDirectory()
	}
	
	func searchPath(forDirectories directory:FileManager.SearchPathDirectory, inDomains domainMask:FileManager.SearchPathDomainMask) -> String? {
		return NSSearchPathForDirectoriesInDomains(directory, domainMask, true).first
	}
	
	func defaultFileList() -> [String] {
		var folders = [String]()
		
		// $HOME/Desktop
		if let desktopPath = searchPath(forDirectories: .desktopDirectory, inDomains: .userDomainMask) {
			folders.append(desktopPath)
		} else {
			folders.append(String(format: "%@/Desktop", homeDirectory()))
		}
		
		// $HOME/Documents
		if let documentsPath = searchPath(forDirectories: .documentDirectory, inDomains: .userDomainMask) {
			folders.append(documentsPath)
		} else {
			folders.append(String(format: "%@/Documents", homeDirectory()))
		}
		
		// $HOME/Pictures
		if let picturesPath = searchPath(forDirectories: .picturesDirectory, inDomains: .userDomainMask) {
			folders.append(picturesPath)
		} else {
			folders.append(String(format: "%@/Pictures", homeDirectory()))
		}
		
		return folders
	}
	
	func saveConfiguration() {
		UserDefaults.standard.set(lookupFolders, forKey: "lookupFolders")
		UserDefaults.standard.synchronize()
	}
	
}
