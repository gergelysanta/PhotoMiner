//
//  ExportAccessoryController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 20/02/2020.
//  Copyright © 2020 TriKatz. All rights reserved.
//

import Cocoa

class ExportAccessoryController: NSViewController {

	@objc dynamic var removeAfterExporting: Bool = false

    override func viewWillAppear() {
        super.viewWillAppear()

        // Set default value from global configuration
        // This can be changed individually for each export but new export will offer default again
        removeAfterExporting = Configuration.shared.removeOriginalAfterExportingImages
    }

}
