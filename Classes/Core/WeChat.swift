//
//  WeChat.swift
//  RxWeChat
//
//  Created by 邓锋 on 2019/4/13.
//  Copyright © 2019 raisechestnut. All rights reserved.
//

import Foundation
import Action
import RxSwift

///用于保持请求和回调的状态，授权请求后原样带回给第三方。该参数可用于防止csrf攻击（跨站请求伪造攻击），建议第三方带上该参数，可设置为简单的随机数加session进行校验
fileprivate let AuthState = "\(Date.init())"
public class WeChat : NSObject{
    
    var appid = ""
    var secret : String? = nil
    
    public static let `default` = WeChat()
    
    let disposeBag = DisposeBag()
    private override init(){
        super.init()
        
        ///应用切到前台两秒后，如果codeAction还在进行中，那就以超时结束
        NotificationCenter.default
            .rx
            .notification(UIApplication.willEnterForegroundNotification)
            .delay(2, scheduler: MainScheduler.instance)
            .bind {[weak self] (noti) in
                let error = NSError.init(domain: "WeChatAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey : "微信登录超时"])
                self?.codeObserver?.onError(error)
        }.disposed(by: disposeBag)
        
        
    }
    
    ///是否安装了微信
    public var isInstalled : Bool{
        return WXApi.isWXAppInstalled()
    }
    
    ///默认开启mta
    public func registerApp(_ appid:String,secret:String? = nil,enableMTA:Bool = true)->Bool{
        self.secret = secret
        self.appid = appid
        return WXApi.registerApp(appid, enableMTA: enableMTA)
    }
    
    ///拦截回调
    public func handleOpen(_ url:URL)->Bool{
        return WXApi.handleOpen(url, delegate: self)
    }
    
    ///codeAction 内部信号
    private var codeObserver: AnyObserver<String>?
    ///获取code的action
    public lazy var codeAction : Action<Void,String> = {
        let observable = Observable<String>.create({[weak self] (ob) -> Disposable in
            self?.codeObserver = ob
            let req = SendAuthReq.init()
            req.scope = "snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact"
            req.state = AuthState
            WXApi.send(req)
            return Disposables.create()
        })
        return Action{
            ///如果应用跳到前台2s后，还没有收到微信的回调，那就结束授权action 在 init里做了监听
            return observable
        }
    }()
    
}

extension WeChat{
    
    ///处理code授权
    fileprivate func handleSendAuthResp(resp:SendAuthResp){
        if resp.state != AuthState{
            ///遭受了攻击，state不一致
            let error = NSError.init(domain: "WeChatAuthError", code: Int(resp.errCode), userInfo: [NSLocalizedDescriptionKey : "auth state不一致"])
            codeObserver?.onError(error)
            return
        }
        if resp.errCode == 0,let code = resp.code{
            codeObserver?.onNext(code)
            codeObserver?.onCompleted()
        }else{
            let error = NSError.init(domain: "WeChatAuthError", code: Int(resp.errCode), userInfo: [NSLocalizedDescriptionKey : resp.errStr])
            codeObserver?.onError(error)
        }
    }
    
}


///WXApiDelegate
extension WeChat : WXApiDelegate{
    public func onReq(_ req: BaseReq) {
        
    }
    
    public func onResp(_ resp: BaseResp) {
        ///code返回
        if let resp = resp as? SendAuthResp{
            self.handleSendAuthResp(resp: resp)
        }
    }
}
