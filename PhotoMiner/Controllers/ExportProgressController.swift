//
//  ExportProgressController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 22/02/2020.
//  Copyright © 2020 TriKatz. All rights reserved.
//

import Cocoa

class ExportProgressController: NSViewController {

    @IBOutlet var progressBar: NSProgressIndicator!

    @IBAction func cancelButtonPressed(_ sender: NSButton) {
        guard let window = self.view.window else { return }

        if let sheetParent = window.sheetParent {
            // Progress is displayed as a sheet
            sheetParent.endSheet(window, returnCode: .cancel)
        } else {
            // Progress is displayed as window
            window.close()
        }
    }

    deinit {
        #if DEBUG
        NSLog("-- ExportProgressController RELEASED")
        #endif
    }

}
