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
    var task: YCSessionTask?
    
    @IBOutlet weak var progressLbl: UILabel!
    @IBOutlet weak var statusLbl: UILabel!
    
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
        task = YCBackgroundSession.bgSession.downloadFile(url: downloadUrl, fileId: nil, delegate: self)
    }
    
    @IBAction func pause(_ sender: Any) {
        if let task = self.task {
            task.pause()
        }
    }
    @IBAction func resume(_ sender: Any) {
         if let task = self.task {
            task.delegate = self
            task.resume()
        }
        
    }
    @IBAction func remove(_ sender: Any) {
        if let task = self.task {
            task.remove()
        }
        
    }
}

extension ViewController: YCSessionTaskDelegate {
    func downloadStatusChanged(task: YCSessionTask) {
        var statusTxt = "NA"
        switch task.status {
        case .waiting:
            statusTxt = "waiting"
            break
        case .downloading:
            statusTxt = "downloading"
            break
        case .paused:
            statusTxt = "paused"
            break
        case .finished:
            statusTxt = "finished"
            break
        case .failed:
            statusTxt = "failed"
            break
        }
        
        statusLbl.text = statusTxt
    }
    
    func downloadProgress(downloadSize: Int64, fileSize: Int64) {
        self.progressLbl.text = "\(Float(downloadSize) / Float(fileSize))"
    }
    
    
}

