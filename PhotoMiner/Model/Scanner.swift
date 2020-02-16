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

/// Object for scanning disk
class Scanner: NSObject {

	/// Delegate scan results regularly in time intervals specified by this property
	var refreshScanResultsIntervalInSecs:TimeInterval = 1.0

	/// Object for delegating scan results
	var delegate:ScannerDelegate? = nil

	/// Is scanner running?
	private(set) var isRunning = false

	/// Actually scanned image collection
	private(set) var scannedCollection = ImageCollection(withDirectories: [])

	/// Dispatch queue used for scanning
	private let scanQueue = DispatchQueue(label: "com.trikatz.scanQueue", qos: .utility)

	/// Flag for stopping scan
	private var stopRequested = false

	/// Start scanner
	/// - Parameters:
	///   - lookupFolders: array of folders to be scanned
	///   - bottomSizeLimit: files of size below this limit will be ignored
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
			self.scannedCollection = ImageCollection(withDirectories: lookupFolders)

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
				var directoryWasEmpty = true

				let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .isReadableKey, .fileSizeKey, .typeIdentifierKey, .creationDateKey, .contentModificationDateKey]
				let dirEnumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: directoryToScan),
				                                                   includingPropertiesForKeys: Array(resourceKeys))
				while let fileURL = dirEnumerator?.nextObject() as? URL {
					let filePath = fileURL.path

					if self.stopRequested {
						self.stopRequested = false
						break
					}

					do {
						let resource = try fileURL.resourceValues(forKeys: resourceKeys)

						let isRegularFile = (resource.isRegularFile == nil) ? false : resource.isRegularFile!
						let isReadable = (resource.isReadable == nil) ? false : resource.isReadable!
						let fileSize = (resource.fileSize == nil) ? 0 : resource.fileSize!
						var fileType = (resource.typeIdentifier == nil) ? "" : resource.typeIdentifier!
						let creationDate = (resource.creationDate == nil) ? Date() : resource.creationDate!
						let modifyDate = (resource.contentModificationDate == nil) ? Date() : resource.contentModificationDate!

						let imageDate = (modifyDate.compare(creationDate) == .orderedAscending) ? modifyDate : creationDate;

						if (isRegularFile && isReadable) {
							// We're not interested in Photos application's thumbnails.
							// Exclude paths containing ".photoslibrary/Thumbnails/"
							if filePath.contains(".photoslibrary/Thumbnails/") {
								// Jump to next file/direcory
								continue
							}

							let typePrefix = "public."
							if fileType.hasPrefix(typePrefix) {
								fileType.removeSubrange(fileType.startIndex..<fileType.index(fileType.startIndex, offsetBy: typePrefix.count))
							}
							else {
								fileType = fileURL.pathExtension
							}

							// Check UTI file type (file must be an image or movie)
							var isMovie = false
							if let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileType as CFString, nil)?.takeRetainedValue() {
								let isImage = UTTypeConformsTo(fileUTI, kUTTypeImage)
								isMovie = UTTypeConformsTo(fileUTI, kUTTypeMovie)
								if (!isImage && !isMovie) ||
								   (isImage && !Configuration.shared.searchForImages) ||
								   (isMovie && !Configuration.shared.searchForMovies)
								{
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

							// Create and add image to collection
							if self.scannedCollection.addImage(ImageData(path: filePath, creationDate: imageDate, isMovie: isMovie)) {

								directoryWasEmpty = false

								// Check if refresh needed
								let now = Date()
								if now.timeIntervalSince(referenceDate) > self.refreshScanResultsIntervalInSecs {
									referenceDate = now
									DispatchQueue.main.sync {
										objc_sync_enter(self)
										self.delegate?.scanSubResult(scanner: self)
										objc_sync_exit(self)
									}
								}
							}
						}
					} catch {
					}
				}

				if directoryWasEmpty {
					self.scannedCollection.removeDirectory(directoryToScan)
				}
			}

			#if DEBUG
			NSLog("ScanQueue: Scan ended, %lu objects found", self.scannedCollection.count)
			#endif

			DispatchQueue.main.sync {
				objc_sync_enter(self)
				self.delegate?.scanFinished(scanner: self)
				objc_sync_exit(self)
			}

			self.isRunning = false
		}

		return true
	}

	/// Stop scanning
	func stop() {
		if !isRunning { return }

		DispatchQueue(label: "com.trikatz.stopScanQueue", qos: .utility).async {
			#if DEBUG
				NSLog("ScanQueue: Stop scanning...")
			#endif

			self.stopRequested = true
		}
	}

}
