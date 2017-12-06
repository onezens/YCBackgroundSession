//
//  YCSessionTask.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/4.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

@objc public protocol YCSessionTaskDelegate: NSObjectProtocol {
    @objc optional func downloadStatusChanged(task: YCSessionTask) -> Void
    @objc optional func downloadProgress(downloadSize: Int64, fileSize: Int64)
}

@objc enum YCSessionTaskStatus: Int {
    case waiting
    case downloading
    case paused
    case failed
    case finished
}

public class YCSessionTask: YCoderObject {

    @objc dynamic var url: String
    @objc dynamic var fileId: String?
    @objc dynamic weak var delegate: YCSessionTaskDelegate?
    @objc dynamic var downloadTask: URLSessionDownloadTask?
    @objc dynamic var uploadTask: URLSessionUploadTask?
    @objc dynamic var status: YCSessionTaskStatus = .waiting
    @objc dynamic var fileSize: Int64 = 0
    @objc dynamic var completedSize: Int64 = 0
    @objc dynamic var resumeData: Data?
    @objc dynamic var suggestName: String?
    @objc dynamic var tmpName: String? //decode resumeData
    @objc dynamic var uploadFilePath: String?

    // MARK: - init
    init(url: String, delegate: YCSessionTaskDelegate?, fileId: String?) {
        self.url = url
        self.delegate = delegate
        self.fileId = fileId
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.url = aDecoder.decodeObject(forKey: "url") as! String
        super.init(coder: aDecoder)
    }
    
    override func getIgnoreKey() -> [String] {
        return ["delegate", "downloadTask", "uploadTask"]
    }
    
    // MARK: - private
    

    // MARK: - public
    @objc func updateInfo(response: HTTPURLResponse?) {
        suggestName = response?.suggestedFilename
        fileSize = response?.expectedContentLength ?? 0
        print(self.savePath())
    }
    
    @objc func savePath() -> String{
        return YCSessionTask.saveDir() + "/" + saveName()
    }
    
    @objc func saveName() -> String {
        let name = YCSessionTask.downloadId(url: self.url, fileId: self.fileId)
        if let pathExtension = url.components(separatedBy: ".").last {
            return (name + pathExtension)
        }
        if let pathExtension = suggestName?.components(separatedBy: ".").last {
            return (name + pathExtension)
        }
        return name
    }
    
    
    @objc func resume(){
        _ = YCBackgroundSession.bgSession.resumeDownloadFile(task: self)
    }
    
    @objc func pause(){
        _ = YCBackgroundSession.bgSession.pauseDownloadFile(task: self)
    }
    
    @objc func remove(){
        YCBackgroundSession.bgSession.removeDownload(task: self)
    }
    
    @objc class func downloadId(url: String, fileId: String?) -> String {
        
        let name = url + (fileId ?? "")
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



