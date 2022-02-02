//
//  FileManagerExtension.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 23/02/2020.
//  Copyright © 2020 Gergely Sánta. All rights reserved.
//

import Foundation

extension FileManager {

    /// Check availability of path. Returns the same if path is available (file or directory do not exists) or a path modified by index if it's not.
    /// - Parameter path: Path to be checked
    func nextAvailable(path: URL) -> URL {
        let filePathWithoutExtension = path.deletingPathExtension().path
        let fileExtension = path.pathExtension
        var mutablePath = path.path
        var nextIndex = 2
        while fileExists(atPath: mutablePath) {
            mutablePath = filePathWithoutExtension.appending("_\(nextIndex).\(fileExtension)")
            nextIndex += 1
        }
        return URL(fileURLWithPath: mutablePath)
    }

    /// Remove directory if do not contains any file
    /// - Parameter dirUrl: directory path
    func removeDirIfEmpty(_ dirUrl: URL) {
        do {
            let files = try contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil, options: [.skipsPackageDescendants, .skipsSubdirectoryDescendants])
            if (files.count == 0) ||
               ((files.count == 1) && (files.first!.lastPathComponent == ".DS_Store"))
            {
                try removeItem(at: dirUrl)
                removeDirIfEmpty(dirUrl.deletingLastPathComponent())
            }
        } catch {
        }
    }

}
