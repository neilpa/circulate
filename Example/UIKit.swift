//
//  UIKit.swift
//  Circulate
//
//  Created by Neil Pankey on 6/18/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import UIKit
import ReactiveCocoa

public func associatedProperty(host: AnyObject, keyPath: StaticString) -> MutableProperty<String> {
    let initial  = { host.valueForKeyPath(keyPath.stringValue) as? String ?? "" }
    let setter: String -> () = { host.setValue($0, forKeyPath: keyPath.stringValue) }
    return associatedProperty(host, keyPath.utf8Start, initial, setter)
}

public func associatedProperty<T: AnyObject>(host: AnyObject, keyPath: StaticString, placeholder: () -> T) -> MutableProperty<T> {
    let initial  = { host.valueForKeyPath(keyPath.stringValue) as? T ?? placeholder() }
    let setter: T -> () = { host.setValue($0, forKeyPath: keyPath.stringValue) }
    return associatedProperty(host, keyPath.utf8Start, initial, setter)
}

public func associatedProperty<T>(host: AnyObject, key: UnsafePointer<()>, initial: () -> T, setter: T -> ()) -> MutableProperty<T> {
    return associatedObject(host, key) {
        let property = MutableProperty(initial())
        property.producer.start(next: setter)
        return property
    }
}

private func associatedObject<T: AnyObject>(host: AnyObject, key: UnsafePointer<()>, initial: () -> T) -> T {
    var value = objc_getAssociatedObject(host, key) as? T
    if value == nil {
        value = initial()
        objc_setAssociatedObject(host, key, value, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
    }
    return value!
}

extension UILabel {
    public var rac_text: MutableProperty<String> {
        return associatedProperty(self, "text")
    }
}
