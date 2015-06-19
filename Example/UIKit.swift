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
    println("keypath \(keyPath) pointer \(keyPath.utf8Start) for host \(host)")

    let initial  = { host.valueForKeyPath(keyPath.stringValue) as? String ?? "" }
    let setter: String -> () = { host.setValue($0, forKeyPath: keyPath.stringValue) }
    return associatedProperty(host, keyPath.utf8Start, initial, setter)
}

public func associatedProperty<T: AnyObject>(host: AnyObject, keyPath: StaticString, placeholder: () -> T) -> MutableProperty<T> {
    println("keypath \(keyPath) pointer \(keyPath.utf8Start) for host \(host)")

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

extension Action {
    static var disabled: Action {
        return Action(enabledIf: ConstantProperty(false)) { _ in .empty }
    }
}

extension CocoaAction {
    public static var disabled: CocoaAction {
        return CocoaAction(Action<Any?, (), NoError>.disabled, input: nil)
    }
}

extension UIControl {
    public var rac_enabled: MutableProperty<Bool> {
        return associatedProperty(self, &Keys.enabled, { self.enabled }, { self.enabled = $0 })
    }
}

extension CocoaAction {
    public var enabledProducer: SignalProducer<Bool, NoError> {
        return rex_producerForKeyPath("enabled")
    }

    public var executingProducer: SignalProducer<Bool, NoError> {
        return rex_producerForKeyPath("executing")
    }
}

extension UIButton {
    public var rac_pressed: MutableProperty<CocoaAction> {
        return associatedObject(self, &Keys.pressed, { _ in
            self.addTarget(self, action: "execute", forControlEvents: .TouchUpInside)

            let property: MutableProperty<CocoaAction> = MutableProperty(.disabled)
            self.rac_enabled <~ property.producer |> flatMap(.Latest) { $0.enabledProducer }
            return property
        })
    }

    func execute() {
        // TODO track the disposable and cancel it if we switch actions?
        self.rac_pressed.value.execute(self)
    }
}

private struct Keys {
    static var enabled: UInt8 = 0
    static var pressed: UInt8 = 0
}
