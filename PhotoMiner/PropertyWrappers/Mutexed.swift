//
//  Mutexed.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2022.
//  Copyright © 2022 Gergely Sánta. All rights reserved.
//

import Foundation

/// A property wrapper that makes all property accesses thread safe by using a mutex.
///
/// Important: The enclosing class must call `destroy()` on all `Mutexed` properties in its `deinit`.
@propertyWrapper
struct Mutexed<Value> {

    private let mutex: UnsafeMutablePointer<pthread_mutex_t> = {
        var mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        pthread_mutex_init(mutex, nil)
        return mutex
    }()

    private var _wrappedValue: Value

    var wrappedValue: Value {
        mutating get {
            pthread_mutex_lock(mutex)
            defer { pthread_mutex_unlock(mutex) }
            return _wrappedValue
        }
        set {
            pthread_mutex_lock(mutex)
            defer { pthread_mutex_unlock(mutex) }
            return _wrappedValue = newValue
        }
        _modify {
            pthread_mutex_lock(mutex)
            defer { pthread_mutex_unlock(mutex) }
            yield &_wrappedValue
        }
    }

    init(wrappedValue: Value) {
        _wrappedValue = wrappedValue
    }

    func destroy() {
        pthread_mutex_destroy(mutex)
        mutex.deallocate()
    }

}
