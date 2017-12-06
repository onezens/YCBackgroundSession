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
    
    // MARK: - public properties
    static let bgSession = YCBackgroundSession.init()
    var tasksCount = 3
    
    // MARK: - private properties
    private lazy var uploadSession = { () -> URLSession in return self.getBackgroundSession(type: .upload) }()
    private lazy var downloadSession = { () -> URLSession in return self.getBackgroundSession(type: .download) }()
    private lazy var uploadTasksDictM = { () -> [String: YCSessionTask] in return self.getUploadTasks() }()
    private lazy var downloadTasksDictM = { () -> [String: YCSessionTask] in return self.getDownloadTasks() }()

    // MARK: - init
    override init() {
        super.init()
    }

    // MARK: - download public
    @objc func downloadFile(url: String, fileId: String?, delegate: YCSessionTaskDelegate?) -> YCSessionTask{
        
        let downloadId = YCSessionTask.downloadId(url: url, fileId: fileId)
        var task = downloadTasksDictM[downloadId]
        if task?.status == .downloading { return task! }
        if task != nil && task?.resumeData != nil{
            task?.delegate = delegate
            resumeDownload(task: task!)
            return task!
        }
        task = YCSessionTask(url: url, delegate: delegate, fileId: fileId)
        if currentTaskCount() < tasksCount {
            startDownload(task: task!)
            downloadStatusChanged(task: task, status: .downloading)
        }else{
            downloadStatusChanged(task: task, status: .waiting)
        }
        downloadTasksDictM[downloadId] = task
        return task!
    }
    
    @objc func pauseDownloadFile(task: YCSessionTask) -> YCSessionTask {
        
        if task.status == .paused { return task }
        if let task =  downloadTasksDictM[YCSessionTask.downloadId(url: task.url, fileId: task.fileId)] {
            self.pauseDownload(task: task)
            self.downloadStatusChanged(task: task, status: .paused)
        }
        return task
    }
    
    @objc func resumeDownloadFile(task: YCSessionTask) -> YCSessionTask {
        
        if task.status == .downloading { return task}
        
        if let task =  downloadTasksDictM[YCSessionTask.downloadId(url: task.url, fileId: task.fileId)] {
            resumeDownload(task: task)
            self.downloadStatusChanged(task: task, status: .downloading)
        }
        return task
        
    }
    
    @objc func removeDownload(task: YCSessionTask) {
        if let task =  downloadTasksDictM[YCSessionTask.downloadId(url: task.url, fileId: task.fileId)] {
            stopDownload(task: task)
        }
    }
    
    // MARK: - upload public
    
    
    // MARK: - download private
    private func startDownload(task: YCSessionTask) {
        let request = URLRequest(url: URL(string: task.url)!)
        let sessionTask = downloadSession.downloadTask(with: request)
        sessionTask.resume()
        task.downloadTask = sessionTask
    }
    
    private func pauseDownload(task: YCSessionTask) {
        //resumeData save at urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
        task.downloadTask?.cancel(byProducingResumeData: { (resumeData) in })
    }
    
    private func resumeDownload(task: YCSessionTask) {
        
        if let resumeData = task.resumeData {
            task.downloadTask = downloadSession.downloadTask(withResumeData: resumeData)
            task.downloadTask?.resume()
            downloadStatusChanged(task: task, status: .downloading)
            return
        }
        
        self.startDownload(task: task)
    }
    
    private func stopDownload(task: YCSessionTask) {
        task.downloadTask?.cancel()
        removeDiskFile(task: task)
        downloadTasksDictM.removeValue(forKey: YCSessionTask.downloadId(url: task.url, fileId: task.fileId))
        saveDownloadInfo()
    }
    
    private func stopAllDownload() {
        for (_, task) in downloadTasksDictM {
            task.downloadTask?.cancel()
            removeDiskFile(task: task)
        }
        downloadTasksDictM.removeAll()
        saveDownloadInfo()
    }
    
    private func downloadStatusChanged(task: YCSessionTask?, status: YCSessionTaskStatus){
        task?.status = status
        saveDownloadInfo()
        if ((task?.delegate) != nil) && (task?.delegate?.responds(to: #selector(YCSessionTaskDelegate.downloadStatusChanged(task:))))! {
            task?.delegate?.downloadStatusChanged(task: task!)
        }
        startNextDownload()
    }
    
    private func startNextDownload() {
        
        if currentTaskCount() < tasksCount {
            for (_, task) in self.downloadTasksDictM {
                if task.status == .waiting {
                    startDownload(task: task)
                    break
                }
            }
        }
    }
    
    private func removeDiskFile(task: YCSessionTask) {
        try? FileManager.default.removeItem(atPath: task.savePath())
    }
    
    // MARK: - upload private
    
    // MARK: - task init private
    private func getBackgroundSession(type: YCBackgroundSessionType) -> URLSession{
        
        let bundleId = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
        let identifier = type == .upload ? bundleId+".UploadSession" : bundleId+".DownloadSession"
        let sessionConf = URLSessionConfiguration.background(withIdentifier: identifier)
        let bgUrlSession = URLSession(configuration: sessionConf, delegate: self, delegateQueue: OperationQueue.main)
        return bgUrlSession
    }
    
    private func recreateSession(type: YCBackgroundSessionType) {
        
    }
    
    private func getUploadTasks() -> [String: YCSessionTask] {
        
        let path = YCSessionTask.saveDir() + "/upload.data"
        let uploadData = NSKeyedUnarchiver.unarchiveObject(withFile: path)
        if let uploadTask = uploadData as? [String: YCSessionTask]{
            return uploadTask
        }
        return [String: YCSessionTask]()
    }
    
    private func getDownloadTasks() -> [String: YCSessionTask] {
        
        let path = YCSessionTask.saveDir() + "/download.data"
        let downloadData = NSKeyedUnarchiver.unarchiveObject(withFile: path)
        if let downloadTasks = downloadData as? [String: YCSessionTask]{
            return downloadTasks
        }
        return [String: YCSessionTask]()
    }
    
    private func saveDownloadInfo() {
        
        let downloadPath = YCSessionTask.saveDir() + "/download.data"
        NSKeyedArchiver.archiveRootObject(self.downloadTasksDictM, toFile: downloadPath)

    }
    
    private func saveUploadInfo() {
        let uploadPath = YCSessionTask.saveDir() + "/upload.data"
        NSKeyedArchiver.archiveRootObject(self.uploadTasksDictM, toFile: uploadPath)
    }
    
    
    private func currentTaskCount() -> Int {
        if let tasksDictM = self.downloadSession.value(forKey: "tasks") as? NSMutableDictionary {
            return tasksDictM.count
        }
        return 0
    }
    
    private func taskForUrlSessionTask(sessionTask: URLSessionTask) -> YCSessionTask? {
        
        let request = (sessionTask.originalRequest != nil) ? sessionTask.originalRequest : sessionTask.currentRequest
        
        if let taskUrl = request?.url?.absoluteString {
            var downloadTask: YCSessionTask?
            for (_, task) in self.downloadTasksDictM {
                if task.url == taskUrl {
                    downloadTask = task
                    break
                }
            }
            return downloadTask
        }
        return nil
        
    }
    
    
}


// MARK: - URLSessionDelegate
extension YCBackgroundSession:URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("didFinishDownloadingTo")
    }
    
   
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("urlSessionDidFinishEvents")
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("didBecomeInvalidWithError : " + error.debugDescription)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("download progress: \(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))")
        let task = taskForUrlSessionTask(sessionTask: downloadTask)
        task?.completedSize = totalBytesWritten
        if task?.fileSize == 0 {
            task?.updateInfo(response: downloadTask.response as? HTTPURLResponse)
        }
        if ((task?.delegate) != nil) && (task?.delegate?.responds(to: #selector(YCSessionTaskDelegate.downloadProgress(downloadSize:fileSize:))))! {
            task?.delegate?.downloadProgress(downloadSize: totalBytesWritten, fileSize: totalBytesExpectedToWrite)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        let downloadTask = taskForUrlSessionTask(sessionTask: task)
        if let err = error{
            let errInfo = (err as NSError).userInfo
            let resumeData = errInfo["NSURLSessionDownloadTaskResumeData"]
            if let data = resumeData as? Data{
                downloadTask?.resumeData = data
                downloadStatusChanged(task: downloadTask, status: .paused)
                print("pause success! resumeDataLength: \((resumeData as! NSData).length)")
                return
            }
        }
        print("didCompleteWithError : " + error.debugDescription)
        downloadStatusChanged(task: downloadTask, status: .failed)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        print("upload progress: \(Float(totalBytesSent) / Float(totalBytesExpectedToSend))")
    }
    
}

