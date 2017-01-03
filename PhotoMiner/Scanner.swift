//
//  Scanner.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 20/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

protocol ScannerDelegate {
	func scanSubResult(scanner: Scanner)
	func scanFinished(scanner: Scanner)
}

class Scanner: NSObject {
	
	var refreshScanResultsIntervalInSecs:TimeInterval = 1.0
	var delegate:ScannerDelegate? = nil
	
	private(set) var isRunning = false
	private(set) var scannedImages = [ImageData]()
	
	private let scanQueue = DispatchQueue(label: "com.trikatz.scanQueue", qos: .utility)
	private let mainQueue = DispatchQueue.main
	
	func start(pathsToScan lookupFolders: [String], bottomSizeLimit: Int) -> Bool {
		if isRunning {
			return false
		}
		
		scanQueue.async {
			self.isRunning = true
			
			#if DEBUG
			NSLog("ScanQueue: Start scanning...")
			#endif
			
			var referenceDate = Date()
			self.scannedImages = []
			
			// Copy folders array, we're going to modify it if needed
			var folders = lookupFolders
			
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
//									NSLog("- [%@] %@", fileType, fileURL.lastPathComponent)
									#endif
									
									// File is not an image, go to next one
									continue
								}
							}
							
							// Check size
							if (fileSize < bottomSizeLimit) {
								continue
							}
							
							// Create and add image to database
							self.scannedImages.append(ImageData(path: filePath))
							
							// Check if refresh needed
							let now = Date()
							if now.timeIntervalSince(referenceDate) > self.refreshScanResultsIntervalInSecs {
								referenceDate = now
								self.mainQueue.sync {
									objc_sync_enter(self)
									if let delegate = self.delegate {
										delegate.scanSubResult(scanner: self)
									}
									objc_sync_exit(self)
								}
							}
						}
					} catch {
					}
				}
			}
			
			#if DEBUG
			NSLog("ScanQueue: Scan ended, %lu objects found", self.scannedImages.count)
			#endif
			
			self.mainQueue.sync {
				objc_sync_enter(self)
				if let delegate = self.delegate {
					delegate.scanFinished(scanner: self)
				}
				objc_sync_exit(self)
			}
			
			self.isRunning = false
		}
		
		return true
	}
	
}
