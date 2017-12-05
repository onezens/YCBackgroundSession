//
//  ViewController.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/4.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let downloadUrl = "http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.0.1.dmg"
    
    @IBOutlet weak var progressLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = "YCBackgroundSession"
    }
    
    class func myController() -> UIViewController {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        return sb.instantiateInitialViewController()!
    }
    
    @IBAction func start(_ sender: Any) {
        YCBackgroundSession.bgSession.download(url: downloadUrl, fileId: nil, delegate: self)
    }
    
    @IBAction func pause(_ sender: Any) {
        YCBackgroundSession.bgSession.pauseDownload(url: downloadUrl)
    }
    @IBAction func resume(_ sender: Any) {
        YCBackgroundSession.bgSession.resumeDownload(url: downloadUrl)
    }
    @IBAction func remove(_ sender: Any) {
        YCBackgroundSession.bgSession.removeDownload(url: downloadUrl)
    }
    
    
}

