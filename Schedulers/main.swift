/*
 * Copyright (c) 2014-2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import RxSwift

fileprivate func getThreadName() -> String {
    if Thread.current.isMainThread {
        return "Main Thread"
    } else if let name = Thread.current.name {
        if name == "" {
            return "Anonymous Thread"
        }
        return name
    } else {
        return "Unknown Thread"
    }
}

print("\n\n\n===== Schedulers =====\n")

let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
let bag = DisposeBag()
let animal = BehaviorSubject(value: "[dog]")


animal
    .subscribeOn(MainScheduler.instance)
    .dump()
    .observeOn(globalScheduler)
    .dumpingSubscription()
    .disposed(by: bag)

let fruit = Observable<String>.create { observer in
    print("create - \(getThreadName())")
    // 如果这里明确指定了线程, subscribeOn 也无法改变线程
    // subscribeOn, 改变的是 create 闭包执行的线程
//    DispatchQueue.main.async {
//        observer.onNext("main - [apple]")
//    }
    // 默认: 在什么地方订阅(subscribe), 就在什么地方观察(observe)
    observer.onNext("[apple]")
    sleep(2)
    observer.onNext("[pineapple]")
    sleep(2)
    observer.onNext("[strawberry]")
    return Disposables.create()
}

// 冷热 Observable 的区别决定了 subscribeOn 是否能控制 Observable 计算事件的线程
// 冷 Observable : subscribeOn 可以控制 Observable 计算事件的线程
// 热 Observable : subscribeOn 不能控制 Observable 计算事件的线程
let animalsThread = Thread {
    sleep(3)
    animal.onNext("[cat]")
    sleep(3)
    animal.onNext("[tiger]")
    sleep(3)
    animal.onNext("[fox]")
    sleep(3)
    animal.onNext("[leopard]")
}
animalsThread.name = "Animals Thread"
animalsThread.start()

fruit
    .subscribeOn(globalScheduler)
    .dump()
    .observeOn(MainScheduler.instance)
    .dumpingSubscription()
    .disposed(by: bag)

RunLoop.main.run(until: Date(timeIntervalSinceNow: 13))
