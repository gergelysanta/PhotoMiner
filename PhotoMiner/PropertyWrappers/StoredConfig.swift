//
//  StoredConfig.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2022.
//  Copyright © 2022 Gergely Sánta. All rights reserved.
//

import Foundation

@propertyWrapper
struct StoredConfig<Value> {
    let key: String
    var container: UserDefaults

    private var _wrappedValue: Value

    var wrappedValue: Value {
        get { _wrappedValue }
        set {
            _wrappedValue = newValue
            store(forKey: key)
            #if DEBUG
            NSLog("Set '\(key)' to '\(_wrappedValue)'")
            #endif
        }
    }

    init(key: String, defaultValue: Value, container: UserDefaults = .standard) {
        self.key = key
        self.container = container
        _wrappedValue = defaultValue

        if let storedValue = restore(forKey: key) {
            _wrappedValue = storedValue
        }

        #if DEBUG
        NSLog("Init '\(key)' to '\(_wrappedValue)'")
        #endif
    }

}

// -----------------------------------------------------------------------------
// MARK: - Store/Restore value
// -----------------------------------------------------------------------------

private extension StoredConfig {

    func store(forKey key: String) {
        if let point = _wrappedValue as? NSPoint {
            container.set(NSStringFromPoint(point), forKey: key)
        } else {
            container.set(_wrappedValue, forKey: key)
        }
    }

    func restore(forKey key: String) -> Value? {
        if _wrappedValue is NSPoint {
            guard let pointString = container.object(forKey: key) as? String else { return nil }
            return NSPointFromString(pointString) as? Value
        } else {
            return container.object(forKey: key) as? Value
        }
    }

}
