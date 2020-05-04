//
//  SubjectSubscription.swift
//  Knot
//
//  Created by 苏杨 on 2020/4/18.
//  Copyright © 2020 SUYANG. All rights reserved.
//

import Foundation

typealias SubjectListener<T> = (_: T?, _: T?) -> ()

class Subject<T> {
    private let lock = DispatchSemaphore(value: 1)
    private var listeners = [Subscription<T>]()
    private(set) var value: T?
    
    init(value: T? = nil) {
        self.value = value
    }
    
    private func sync<F>(_ task: () -> (F)) -> F {
        lock.wait();
        let r = task()
        lock.signal()
        return r
    }
    
    func publish(_ newValue: T?) {
        sync {
            let old = value
            value = newValue
            listeners.forEach({ $0.notifyListener(new: newValue, old: old) })
        }
    }
    
    func listen(_ listener: @escaping SubjectListener<T>, needNotify: Bool = true) -> Subscription<T> {
        return sync {
            let subscription = Subscription(listener: listener) { [weak self] (subscription) in
                self?.sync({
                    self?.listeners.removeAll(where: { $0 === subscription })
                })
            }
            listeners.append(subscription)
            
            if (needNotify) {
                listener(nil, value)
            }
            
            return subscription
        }
    }
}

class Subscription<T> {
    
    private var cancelBlock: ((Subscription<T>) -> ())?
    private var listener: SubjectListener<T>?
    
    fileprivate init(listener: @escaping SubjectListener<T>, cancelBlock: @escaping (Subscription<T>) -> ()) {
        self.listener = listener
        self.cancelBlock = cancelBlock
    }
    
    fileprivate func notifyListener(new: T?, old: T?) {
        listener?(new, old)
    }
    
    func cancel() {
        cancelBlock?(self)
        listener = nil
        cancelBlock = nil
    }
    
    deinit {
        cancel()
    }
}
