//
//  YCSessionTask.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/4.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

@objc enum YCSessionTaskStatus: Int {
    case waiting
    case downloading
    case paused
    case failed
    case finished
}

class YCSessionTask: YCoderObject {

    @objc dynamic var url: String
    @objc dynamic var fileId: String?
    @objc dynamic var filePath: String?
    @objc dynamic var delegate: Any?
    @objc dynamic var downloadTask: URLSessionDownloadTask?
    @objc dynamic var uploadTask: URLSessionUploadTask?
    @objc dynamic var taskStatus: YCSessionTaskStatus = .waiting
    @objc dynamic var fileSize: Int64 = 0
    @objc dynamic var completedSize: Int64 = 0
    @objc dynamic var resumeData: Data?
    @objc dynamic var suggestName: String?

    
    init(url: String, delegate: Any?, fileId: String?) {
        self.url = url
        self.delegate = delegate
        self.fileId = fileId
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.url = aDecoder.decodeObject(forKey: "url") as! String
        super.init(coder: aDecoder)
    }
    
    override func getIgnoreKey() -> [String] {
        return ["delegate", "downloadTask", "uploadTask"]
    }
    
    // MARK: private
    
    
    
    // MARK: public
    @objc func updateInfo(request: URLRequest?) {
        
        if let oriRequest = request as NSURLRequest? {
            print(oriRequest.allHTTPHeaderFields)
        }
        print(request?.allHTTPHeaderFields)
        
    }
    
    @objc func savePath() -> String{
        return ""
    }
    
    @objc func saveName() -> String {
        let name = url + (fileId ?? "")
        if let pathExtension = url.components(separatedBy: ".").last {
            return (MD5(name) + "." + pathExtension)
        }
        if let pathExtension = suggestName?.components(separatedBy: ".").last {
            return (MD5(name) + "." + pathExtension)
        }
        return MD5(name)
    }

    @objc class func saveDir() -> String{
        
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/YCBackgroundSession"
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }
    
}



