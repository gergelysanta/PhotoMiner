//
//  Configuration.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 08/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class Configuration: NSObject {
	
	// With the dynamic modifier, the messages sent to the array can be intercepted by the system (KVO)
	dynamic var lookupFolders = [String]()
	
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
	
	func defaultFileList() -> [String] {
		let desktopPaths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
		let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let picturesPaths = NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true)
		
		var folders = [String]()
		folders.append(desktopPaths.first != nil ? desktopPaths.first! : String(format: "%@/Desktop", NSHomeDirectory()))
		folders.append(documentsPaths.first != nil ? documentsPaths.first! : String(format: "%@/Documents", NSHomeDirectory()))
		folders.append(picturesPaths.first != nil ? picturesPaths.first! : String(format: "%@/Pictures", NSHomeDirectory()))
		
		return folders
	}
	
	func saveConfiguration() {
		UserDefaults.standard.set(lookupFolders, forKey: "lookupFolders")
		UserDefaults.standard.synchronize()
	}
	
}
