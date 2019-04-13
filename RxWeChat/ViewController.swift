//
//  ViewController.swift
//  RxWeChat
//
//  Created by 邓锋 on 2019/4/13.
//  Copyright © 2019 raisechestnut. All rights reserved.
//

import UIKit
import Action
import RxSwift

class ViewController: UIViewController {
    
    let dispose = DisposeBag()
    private var codeObserver: AnyObserver<String>?
    public lazy var action : Action<Void,String> = {
        let observable = Observable<String>.create({[weak self] (ob) -> Disposable in
            self?.codeObserver = ob
            return Disposables.create()
        })
        return Action{
            return observable.takeUntil(NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification).delay(2, scheduler: MainScheduler.instance))
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.action.elements.bind { (s) in
            print(s)
        }.disposed(by: dispose)
        
        self.action.errors.bind { (err) in
            print(err)
        }.disposed(by: dispose)
        
        self.action.executing.bind { (isRun) in
            print("isRun:\(isRun)")
        }.disposed(by: dispose)
        
        self.action.execute()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            self.codeObserver?.onNext("112222")
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4) {
            self.codeObserver?.onNext("4444")
        }
        
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 6) {
//            self.codeObserver?.onCompleted()
//        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 8) {
            self.codeObserver?.onNext("333333")
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 12) {
            self.codeObserver?.onNext("12")
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 16) {
            self.codeObserver?.onNext("16")
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 20) {
            self.codeObserver?.onNext("16")
        }
        
    }


}

