//
//  RWLocked.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2022.
//  Copyright © 2022 Gergely Sánta. All rights reserved.
//

import Foundation

/// A property wrapper that makes all property accesses thread safe by using an RW lock.
///
/// Important: The enclosing class must call `destroy()` on all `RWLocked` properties in its `deinit`.
@propertyWrapper
struct RWLocked<Value> {

    private let rwLock: UnsafeMutablePointer<pthread_rwlock_t> = {
        var rwLock = UnsafeMutablePointer<pthread_rwlock_t>.allocate(capacity: 1)
        pthread_rwlock_init(rwLock, nil)
        return rwLock
    }()

    private var _wrappedValue: Value

    var wrappedValue: Value {
        mutating get {
            pthread_rwlock_rdlock(rwLock)
            defer { pthread_rwlock_unlock(rwLock) }
            return _wrappedValue
        }
        set {
            pthread_rwlock_wrlock(rwLock)
            defer { pthread_rwlock_unlock(rwLock) }
            return _wrappedValue = newValue
        }
        _modify {
            pthread_rwlock_wrlock(rwLock)
            defer { pthread_rwlock_unlock(rwLock) }
            yield &_wrappedValue
        }
    }

    init(wrappedValue: Value) {
        _wrappedValue = wrappedValue
    }

    func destroy() {
        pthread_rwlock_destroy(rwLock)
        rwLock.deallocate()
    }

}
