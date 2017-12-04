//
//  YCBackgroundSession.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/4.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

enum YCBackgroundSessionType {
    case upload
    case download
}

class YCBackgroundSession: NSObject {
    
    // MARK: public properties
    static let backgroundSession = YCBackgroundSession()
    
    // MARK: private properties
    private lazy var uploadSession = { () -> URLSession in return self.getBackgroundSession(type: .upload) }()
    private lazy var downloadSession = { () -> URLSession in return self.getBackgroundSession(type: .download) }()
    private lazy var uploadTasksDictM = { () -> NSMutableDictionary in return self.getUploadTasks() }()
    private lazy var downloadTasksDictM = { () -> NSMutableDictionary in return self.getDownloadTasks() }()
    
    // MARK: init
    override init() {
        super.init()
    }

    // MARK: download public
    @objc func downloadFile(url: String, fileId: String?, delegate: Any?){
        let task = YCSessionTask(url: url, delegate: delegate, fileId: fileId)
        startDownload(task: task)
        
    }
    
    @objc func pauseDownloadFile(url: String) {
        
    }
    
    @objc func resumeDownloadFile(url: String) {
        
    }
    
    @objc func removeDownloadFile(url: String) {
        
    }
    
    // MARK: upload public
    
    
    // MARK: download private
    private func startDownload(task: YCSessionTask) {
        let request = URLRequest(url: URL(string: task.url)!)
        let sessionTask = downloadSession.downloadTask(with: request)
        sessionTask.resume()
        task.downloadTask = sessionTask
    }
    
    private func pauseDownload(task: YCSessionTask) {
        task.downloadTask?.cancel(byProducingResumeData: { (resumeData) in
            task.resumeData = resumeData
        })
    }
    
    private func resumeDownload(task: YCSessionTask) {
        
        if let resumeData = task.resumeData {
            task.downloadTask = downloadSession.downloadTask(withResumeData: resumeData)
            downloadStatusChanged(task: task, status: .downloading)
            return
        }
        self.startDownload(task: task)
    }
    
    private func stopDownload(task: YCSessionTask) {
        
    }
    
    private func downloadStatusChanged(task: YCSessionTask, status: YCSessionTaskStatus){
        task.taskStatus = status
    }
    
    // MARK: upload private
    
    // MARK: task init private
    private func getBackgroundSession(type: YCBackgroundSessionType) -> URLSession{
        
        let bundleId = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
        let identifier = type == .upload ? bundleId+"YCUploadSession" : bundleId+"YCDownloadSession"
        let sessionConf = URLSessionConfiguration.background(withIdentifier: identifier)
        let bgSession = URLSession(configuration: sessionConf, delegate: self, delegateQueue: OperationQueue.main)
        return bgSession
    }
    
    private func recreateSession(type: YCBackgroundSessionType) {
        
    }
    
    private func getUploadTasks() -> NSMutableDictionary {
        
        let path = YCSessionTask.saveDir() + "/upload.data"
        var uploadTasks = NSKeyedUnarchiver.unarchiveObject(withFile: path)
        if (uploadTasks as? NSMutableDictionary) == nil {
            uploadTasks = NSMutableDictionary()
        }
        return uploadTasks as! NSMutableDictionary
    }
    
    private func getDownloadTasks() -> NSMutableDictionary {
        
        let path = YCSessionTask.saveDir() + "/download.data"
        var downloadTasks = NSKeyedUnarchiver.unarchiveObject(withFile: path)
        if (downloadTasks as? NSMutableDictionary) == nil {
            downloadTasks = NSMutableDictionary()
        }
        return downloadTasks as! NSMutableDictionary
    }
    
    
}


// MARK: - URLSessionDelegate
extension YCBackgroundSession:URLSessionDelegate, URLSessionTaskDelegate {
    
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("didBecomeInvalidWithError : " + error.debugDescription)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        print("download progress: \(Float(totalBytesSent) / Float(totalBytesExpectedToSend))")
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let err = error {
            print(err)
        }
        
    }
    
}

