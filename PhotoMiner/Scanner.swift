//
//  Scanner.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 20/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class Scanner: NSObject {
	
	let scanQueue = DispatchQueue(label: "com.trikatz.scanQueue", qos: .utility)
	let mainQueue = DispatchQueue.main
	
	var running = false
	
	override init() {
		super.init()
	}
	
	func start() {
		if running {
			return
		}
		
		scanQueue.async {
			self.running = true
			
			#if DEBUG
			NSLog("ScanQueue: Start scanning...")
			#endif
			
			var imagesDict = [String: String]()
			
			var folders = [String]()
			var minSize = 0
			if let appDelegate = NSApp.delegate as? AppDelegate {
				folders = appDelegate.configuration.lookupFolders
				minSize = appDelegate.configuration.ignoreImagesBelowSize
			}
			
			// Remove folders which are subfolders of other ones in the same list
			for folder1 in folders {
				let needle = folder1.hasSuffix("/") ? folder1 : folder1 + "/"
				for (index2, folder2) in folders.enumerated() {
					if folder1 == folder2 {
						continue
					}
					if folder2.hasPrefix(needle) {
						// Remove folder2 form array
						folders.remove(at: index2)
					}
				}
			}
			
			// Scan folders
			for directoryToScan in folders {
				#if DEBUG
				NSLog("ScanQueue:   ...scanning %@", directoryToScan)
				#endif
				
				let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .isReadableKey, .fileSizeKey, .typeIdentifierKey]
				let dirEnumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: directoryToScan),
				                                                   includingPropertiesForKeys: Array(resourceKeys))
				while let fileURL = dirEnumerator?.nextObject() as? URL {
					let filePath = fileURL.path
					do {
						let resource = try fileURL.resourceValues(forKeys: resourceKeys)
						
						let isRegularFile = (resource.isRegularFile == nil) ? false : resource.isRegularFile!
						let isReadable = (resource.isReadable == nil) ? false : resource.isReadable!
						let fileSize = (resource.fileSize == nil) ? 0 : resource.fileSize!
						var fileType = (resource.typeIdentifier == nil) ? "" : resource.typeIdentifier!
						
						if (isRegularFile && isReadable) {
							var fileName = fileURL.lastPathComponent
							
							// We're not interested in Photos application's thumbnails.
							// Exclude paths containing ".photoslibrary/Thumbnails/"
							if filePath.contains(".photoslibrary/Thumbnails/") {
								// Jump to next file/direcory
								continue
							}
							
							let typePrefix = "public."
							if fileType.hasPrefix(typePrefix) {
								fileType.removeSubrange(fileType.startIndex..<fileType.index(fileType.startIndex, offsetBy: typePrefix.characters.count))
							}
							else {
								fileType = fileURL.pathExtension
							}
							
							// Check UTI file type (file must be an image)
							if let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileType as CFString, nil)?.takeRetainedValue() {
								if !UTTypeConformsTo(fileUTI, kUTTypeImage) {
									#if DEBUG
//									NSLog("- [%@] %@", fileType, fileName)
									#endif
									
									// File is not an image, go to next one
									continue
								}
							}
							
							// Check size
							if (fileSize < minSize) {
								continue
							}
							
							// Check if file with same name exists
							if imagesDict[fileName] != nil {
								// Key already exists
								let fileExtension = fileURL.pathExtension
								
								var key = fileName
								var index = 1
								
								while imagesDict[key] != nil {
									if fileExtension.isEmpty {
										key = String(format: "%@_PM%lu", fileName, index)
									}
									else {
										let fileNameWithoutExtension = fileURL.deletingPathExtension().lastPathComponent
										key = String(format: "%@_PM%lu.%@", fileNameWithoutExtension, index, fileExtension)
									}
									index += 1
								}
								fileName = key;
							}
							
							imagesDict[fileName] = filePath
						}
					} catch {
					}
				}
			}
			
			#if DEBUG
			NSLog("ScanQueue: Scan ended, %lu objects found", imagesDict.count)
			#endif
			self.running = false
		}
	}
	
}
