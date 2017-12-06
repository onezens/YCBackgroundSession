//
//  UploadController.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/6.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

class UploadController: UIViewController {

    let uploadHost = "http://localhost:3004/upload/stream"
    let uploadHostForm = "http://localhost:3004/upload"
    var uploadTask:YCUploadTask?
    
    
    @IBOutlet weak var progressLbl: UILabel!
    @IBOutlet weak var statusLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
    }
    
    class func myController() -> UIViewController {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        return sb.instantiateViewController(withIdentifier: "UploadController")
    }
    
    func uploadFileStream() {
        let path = Bundle.main.path(forResource: "1.jpg", ofType: nil)!
        uploadTask = YCBackgroundSession.bgSession.uploadFileStream(url: uploadHost, localPath: path, headers: ["UploadAgent":"YCDownloadSession"], delegate: nil)

    }
    
    func uploadFormStream() {
        //
        let path = Bundle.main.path(forResource: "1.jpg", ofType: nil)!
        uploadTask = YCBackgroundSession.bgSession.uploadFormStream(url: uploadHostForm, localPath: path, params: ["name":"xiaoming", "age":"20"], headers:  ["UploadAgent":"YCDownloadSession"], delegate: nil, uploadFileKey: "sampleFile")
    }

    @IBAction func start(_ sender: Any) {
        uploadFormStream()
    }
    
    @IBAction func pause(_ sender: Any) {
        
    }
    
    @IBAction func resume(_ sender: Any) {
        
    }
    
    @IBAction func remove(_ sender: Any) {
    }
}
