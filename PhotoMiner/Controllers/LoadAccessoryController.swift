//
//  LoadAccessoryController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 15/02/2020.
//  Copyright © 2020 TriKatz. All rights reserved.
//

import Cocoa

class LoadAccessoryController: NSViewController {

    @objc dynamic var includeImages: Bool {
        get {
            return Configuration.shared.searchForImages
        }
        set {
            self.willChangeValue(forKey: "checkImagesEnabled")
            self.willChangeValue(forKey: "checkMoviesEnabled")

            Configuration.shared.searchForImages = newValue

            self.didChangeValue(forKey: "checkImagesEnabled")
            self.didChangeValue(forKey: "checkMoviesEnabled")
        }
    }

    @objc dynamic var includeMovies: Bool {
        get {
            return Configuration.shared.searchForMovies
        }
        set {
            self.willChangeValue(forKey: "checkImagesEnabled")
            self.willChangeValue(forKey: "checkMoviesEnabled")

            Configuration.shared.searchForMovies = newValue

            self.didChangeValue(forKey: "checkImagesEnabled")
            self.didChangeValue(forKey: "checkMoviesEnabled")
        }
    }

    deinit {
        #if DEBUG
        NSLog("-- LoadAccessoryController RELEASED")
        #endif
    }

    @objc dynamic var checkImagesEnabled: Bool {
        return !(includeImages && !includeMovies)
    }

    @objc dynamic var checkMoviesEnabled: Bool {
        return !(includeMovies && !includeImages)
    }

}
