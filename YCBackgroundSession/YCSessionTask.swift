//
//  YCSessionTask.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/4.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

@objc public protocol YCDownloadTaskDelegate: NSObjectProtocol {
    @objc optional func downloadStatusChanged(task: YCDownloadTask) -> Void
    @objc optional func downloadProgress(downloadSize: Int64, fileSize: Int64)
}

@objc public protocol YCUploadTaskDelegate: NSObjectProtocol {

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
    @objc dynamic var status: YCSessionTaskStatus = .waiting
    @objc dynamic var fileSize: Int64 = 0
    @objc dynamic var completedSize: Int64 = 0
    
    init(url: String) {
        self.url = url
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.url = aDecoder.decodeObject(forKey: "url") as! String
        super.init(coder: aDecoder)
    }

    @objc class func saveDir() -> String{
        
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/YCBackgroundSession"
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }
}

public class YCDownloadTask: YCSessionTask {
    @objc dynamic var fileId: String?
    @objc dynamic var downloadTask: URLSessionDownloadTask?
    @objc dynamic var resumeData: Data?
    @objc dynamic var suggestName: String?
    @objc dynamic var tmpName: String? //decode resumeData
    @objc dynamic weak var delegate: YCDownloadTaskDelegate?
    
    // MARK: - init
    init(url: String, delegate: YCDownloadTaskDelegate?, fileId: String?) {
        super.init(url: url)
        self.delegate = delegate
        self.fileId = fileId
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func getIgnoreKey() -> [String] {
        return ["delegate", "downloadTask", "uploadTask"]
    }
    
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
        let name = YCDownloadTask.downloadId(url: self.url, fileId: self.fileId)
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
}


public class YCUploadTask: YCSessionTask {
    @objc dynamic var localPath: String
    /// post upload form file key default is file
    @objc dynamic var uploadFileKey: String = "file"
    @objc dynamic var uploadTask: URLSessionUploadTask?
    @objc dynamic weak var delegate: YCUploadTaskDelegate?
    @objc dynamic var headers: [String:String]?
    @objc dynamic var formParmaters: [String:String]?
    
    init(url: String, localPath: String, headers:[String:String]?, params: [String:String]? = nil, delegate: YCUploadTaskDelegate?, uploadFileKey: String = "file") {
        self.localPath = localPath
        super.init(url: url)
        self.headers = headers
        self.formParmaters = params
        self.uploadFileKey = uploadFileKey
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.localPath = aDecoder.decodeObject(forKey: "localPath") as! String
        super.init(coder: aDecoder)
    }
    
    // MARK: - public
    @objc func boundary() -> String {
        return "--YCBGSFormBoundary" + MD5(localPath)
    }
    
    @objc func contentType() -> String {
        return "multipart/form-data; charset=utf-8;boundary=\(boundary())"
    }
    @objc func fileName() -> String {
        return localPath.components(separatedBy: "/").last ?? "unkown.filename"
    }
}



