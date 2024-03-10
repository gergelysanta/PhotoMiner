//
//  URLExtension.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 04/01/2023.
//  Copyright © 2023 Gergely Sánta. All rights reserved.
//

import Foundation

extension URL {

    var exists: Bool {
        withUnsafeFileSystemRepresentation { access($0, F_OK) == 0 }
    }

    var hasReadAccess: Bool {
        withUnsafeFileSystemRepresentation { access($0, R_OK) == 0 }
    }

}
