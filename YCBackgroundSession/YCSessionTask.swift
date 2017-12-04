//
//  YCSessionTask.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/4.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

enum YCSessionTaskStatus {
    case waiting
    case downloading
    case pause
    case stop
    case finished
}

class YCSessionTask: YCoderObject {

    var url: String
    var fileId: String?
    var filePath: String?
    var delegate: Any?
    var downloadTask: URLSessionDownloadTask?
    var uploadTask: URLSessionUploadTask?
    var taskStatus: YCSessionTaskStatus = .waiting
    var fileSize: UInt64 = 0
    var completedSize: UInt64 = 0
    var resumeData: Data?
    
    init(url: String, delegate: Any?, fileId: String?) {
        self.url = url
        self.delegate = delegate
        self.fileId = fileId
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.url = aDecoder.value(forKey: "_url") as! String
        super.init(coder: aDecoder)
    }
    
    // MARK: private
    
    
    // MARK: public
    @objc func savePath() -> String{
        return ""
    }
    
    @objc func saveName() -> String {
        return ""
    }

    @objc class func saveDir() -> String{
        
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, false).first! + "/YCBackgroundSession"
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        
        return path
    }
}



