//
//  Scanner.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 20/12/2016.
//  Copyright © 2016 Gergely Sánta. All rights reserved.
//

import Cocoa

protocol ScannerDelegate {
    func scanSubResult(scanner: Scanner)
    func scanFinished(scanner: Scanner)
}

/// Object for scanning disk
class Scanner: NSObject {

    /// Delegate scan results regularly in time intervals specified by this property
    var refreshScanResultsIntervalInSecs: TimeInterval = 1.0

    /// Object for delegating scan results
    var delegate: ScannerDelegate?

    /// Is scanner running?
    @Mutexed private(set) var isRunning = false

    /// Actually scanned image collection
    private(set) var scannedCollection = ImageCollection(withDirectories: [])

    /// Dispatch queue used for scanning
    private let scanQueue = DispatchQueue(label: "photominer.scanQueue", qos: .utility)

    /// Flag for stopping scan
    @Mutexed private var stopRequested = false

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

            // Filter folders (use only topmost folders)
            let folders = lookupFolders
                .sorted { $0 < $1 }
                .filter { folder in
                    !lookupFolders.contains {
                        // Filter out folders that has one of their parents
                        // already in the list
                        $0 != folder && folder.hasPrefix("\($0)/")
                    }
                }

            // Scan folders
            for directoryToScan in folders {
                #if DEBUG
                NSLog("ScanQueue:   ...scanning %@", directoryToScan)
                #endif
                let directoryScanProfiler = TimeProfiler.begin("ScanDir", description: directoryToScan)
                var directoryWasEmpty = true

                let resourceKeys: Set<URLResourceKey> = [
                    .isRegularFileKey,
                    .isReadableKey,
                    .fileSizeKey,
                    .typeIdentifierKey,
                    .creationDateKey,
                    .contentModificationDateKey
                ]
                let dirEnumerator = FileManager.default.enumerator(
                    at: URL(fileURLWithPath: directoryToScan),
                    includingPropertiesForKeys: Array(resourceKeys)
                )
                while let fileURL = dirEnumerator?.nextObject() as? URL {
                    let filePath = fileURL.path

                    if self.stopRequested {
                        self.stopRequested = false
                        break
                    }

                    let fileScanProfiler = TimeProfiler.begin("ScanFile", description: fileURL.lastPathComponent)

                    do {
                        let resource = try fileURL.resourceValues(forKeys: resourceKeys)

                        let isRegularFile = resource.isRegularFile ?? false
                        let isReadable = resource.isReadable ?? false
                        let fileSize = resource.fileSize ?? 0
                        var fileType = resource.typeIdentifier ?? ""
                        let creationDate = resource.creationDate ?? Date()
                        let modifyDate = resource.contentModificationDate ?? Date()

                        let imageDate = (modifyDate.compare(creationDate) == .orderedAscending) ? modifyDate : creationDate

                        if isRegularFile && isReadable {
                            // We're not interested in Photos application's thumbnails.
                            // Exclude paths containing ".photoslibrary/Thumbnails/"
                            if filePath.contains(".photoslibrary/Thumbnails/") {
                                // Jump to next file/direcory
                                fileScanProfiler?.end()
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
//                                    #if DEBUG
//                                    NSLog("- [%@] %@", fileType, fileURL.lastPathComponent)
//                                    #endif

                                    // File is not an image, go to next one
                                    fileScanProfiler?.end()
                                    continue
                                }
                            }

                            // Check size
                            if (fileSize < bottomSizeLimit) {
                                fileScanProfiler?.end()
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

                    fileScanProfiler?.end()
                }

                if directoryWasEmpty {
                    self.scannedCollection.removeDirectory(directoryToScan)
                }

                directoryScanProfiler?.end()
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

        DispatchQueue(label: "photominer.stopScanQueue", qos: .utility).async {
            #if DEBUG
                NSLog("ScanQueue: Stop scanning...")
            #endif

            self.stopRequested = true
        }
    }

}
