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
    private lazy var downloadTasksDictM = { () -> [String: YCDownloadTask] in return self.getDownloadTasks() }()

    // MARK: - init
    override init() {
        super.init()
    }

    // MARK: - download public
    @objc func downloadFile(url: String, fileId: String?, delegate: YCDownloadTaskDelegate?) -> YCDownloadTask{
        
        let downloadId = YCDownloadTask.downloadId(url: url, fileId: fileId)
        var task = downloadTasksDictM[downloadId]
        if task?.status == .downloading { return task! }
        if task != nil && task?.resumeData != nil{
            task?.delegate = delegate
            resumeDownload(task: task!)
            return task!
        }
        task = YCDownloadTask(url: url, delegate: delegate, fileId: fileId)
        if currentTaskCount() < tasksCount {
            startDownload(task: task!)
            downloadStatusChanged(task: task, status: .downloading)
        }else{
            downloadStatusChanged(task: task, status: .waiting)
        }
        downloadTasksDictM[downloadId] = task
        return task!
    }
    
    @objc func pauseDownloadFile(task: YCDownloadTask) -> YCDownloadTask {
        
        if task.status == .paused { return task }
        if let task =  downloadTasksDictM[YCDownloadTask.downloadId(url: task.url, fileId: task.fileId)] {
            self.pauseDownload(task: task)
            self.downloadStatusChanged(task: task, status: .paused)
        }
        return task
    }
    
    @objc func resumeDownloadFile(task: YCDownloadTask) -> YCDownloadTask {
        
        if task.status == .downloading { return task}
        
        if let task =  downloadTasksDictM[YCDownloadTask.downloadId(url: task.url, fileId: task.fileId)] {
            resumeDownload(task: task)
            self.downloadStatusChanged(task: task, status: .downloading)
        }
        return task
        
    }
    
    @objc func removeDownload(task: YCDownloadTask) {
        if let task =  downloadTasksDictM[YCDownloadTask.downloadId(url: task.url, fileId: task.fileId)] {
            stopDownload(task: task)
        }
    }
    
    // MARK: - upload public
    @objc func uploadFileStream(url: String, localPath: String, headers: [String: String]? , delegate: YCUploadTaskDelegate?) -> YCUploadTask {
        let task = YCUploadTask(url: url, localPath: localPath, headers: headers, delegate: delegate)
        startUploadFileStream(task: task)
        return task
    }
    
    @objc func uploadFormStream(url: String, localPath: String, params: [String: String]?, headers: [String: String]? , delegate: YCUploadTaskDelegate?, uploadFileKey: String = "file") -> YCUploadTask {
        let task = YCUploadTask(url: url, localPath: localPath, headers: headers, params: params, delegate: delegate, uploadFileKey: uploadFileKey)
        startUploadFormStream(task: task)
        return task
    }
    
    @objc func pauseUpload(task: YCSessionTask) {
        
    }
    
    @objc func resumeUpload(task: YCSessionTask) {
        
    }
    
    @objc func removeUpload(task: YCSessionTask) {
        
    }
    
    // MARK: - download private
    private func startDownload(task: YCDownloadTask) {
        let request = URLRequest(url: URL(string: task.url)!)
        let sessionTask = downloadSession.downloadTask(with: request)
        sessionTask.resume()
        task.downloadTask = sessionTask
    }
    
    private func pauseDownload(task: YCDownloadTask) {
        //resumeData save at urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
        task.downloadTask?.cancel(byProducingResumeData: { (resumeData) in })
    }
    
    private func resumeDownload(task: YCDownloadTask) {
        
        if let resumeData = task.resumeData {
            task.downloadTask = downloadSession.downloadTask(withResumeData: resumeData)
            task.downloadTask?.resume()
            downloadStatusChanged(task: task, status: .downloading)
            return
        }
        
        self.startDownload(task: task)
    }
    
    private func stopDownload(task: YCDownloadTask) {
        task.downloadTask?.cancel()
        removeDiskFile(task: task)
        downloadTasksDictM.removeValue(forKey: YCDownloadTask.downloadId(url: task.url, fileId: task.fileId))
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
    
    private func downloadStatusChanged(task: YCDownloadTask?, status: YCSessionTaskStatus){
        task?.status = status
        saveDownloadInfo()
        if ((task?.delegate) != nil) && (task?.delegate?.responds(to: #selector(YCDownloadTaskDelegate.downloadStatusChanged(task:))))! {
            task?.delegate?.downloadStatusChanged!(task: task!)
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
    
    private func removeDiskFile(task: YCDownloadTask) {
        try? FileManager.default.removeItem(atPath: task.savePath())
    }
    
    // MARK: - upload private
    private func startUploadFileStream(task: YCUploadTask){
        let url = URL(string: task.url)!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        if let headers = task.headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        //session create upload task and internal generate request headers
        let sessionTask = uploadSession.uploadTask(with: request as URLRequest, fromFile: URL(fileURLWithPath: task.localPath))
        task.uploadTask = sessionTask
        sessionTask.resume()
    }
    
    private func startUploadFormStream(task: YCUploadTask){
        let url = URL(string: task.url)!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        //generate inputstream with form data
        let uploadData = uploadFormStreamData(task: task)
        //must set request header: Content-Type Content-Length ,otherwise upload request can`t continue
        request.addValue(task.contentType(), forHTTPHeaderField: "Content-Type")
        request.addValue("\((uploadData as NSData).length)", forHTTPHeaderField: "Content-Length")
        request.httpBodyStream = InputStream(data: uploadData)
        if let headers = task.headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        let sessionTask = uploadSession.uploadTask(withStreamedRequest: request as URLRequest)
        task.uploadTask = sessionTask
        sessionTask.resume()
    }
    
    private func uploadFormStreamData(task: YCUploadTask) -> Data {
        
        let data = NSMutableData()
        let startStr = NSMutableString()
        let utf8Encode = String.Encoding.utf8.rawValue
        startStr.append("--" + task.boundary() + "\r\n")
        startStr.append("Content-Disposition: form-data; name=\"\(task.uploadFileKey)\"; filename=\"\(task.fileName())\"\r\n\r\n")
        data.append(startStr.data(using: utf8Encode)!)
        let fileData = (try? Data(contentsOf: URL(fileURLWithPath: task.localPath))) ?? ("error file data".data(using: .utf8))!
        data.append(fileData)
//        data.append("fileData".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)
        if let formParmaters = task.formParmaters {
            for (key, value) in formParmaters {
                let otherStr = NSMutableString()
                otherStr.append("--" + task.boundary() + "\r\n")
                otherStr.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                otherStr.append(value + "\r\n")
                data.append(otherStr.data(using: utf8Encode)!)
            }
        }
        let endStr = NSMutableString()
        endStr.append("--\(task.boundary())--")
        data.append(endStr.data(using: utf8Encode)!)
//        print(String(data: data as Data, encoding: .utf8)!)
        return data as Data
    }
    
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
    
    private func getDownloadTasks() -> [String: YCDownloadTask] {
        
        let path = YCSessionTask.saveDir() + "/download.data"
        let downloadData = NSKeyedUnarchiver.unarchiveObject(withFile: path)
        if let downloadTasks = downloadData as? [String: YCDownloadTask]{
            return downloadTasks
        }
        return [String: YCDownloadTask]()
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
    
    private func taskForUrlSessionTask(sessionTask: URLSessionTask) -> YCDownloadTask? {
        
        let request = (sessionTask.originalRequest != nil) ? sessionTask.originalRequest : sessionTask.currentRequest
        if let taskUrl = request?.url?.absoluteString {
            var downloadTask: YCDownloadTask?
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
       
        if let task = taskForUrlSessionTask(sessionTask: downloadTask){
            let fileMgr = FileManager.default
            let tmpFileInfo = try? fileMgr.attributesOfItem(atPath: location.path)
            let fileSize = tmpFileInfo?[FileAttributeKey.size] as? NSNumber
            if fileSize?.int64Value == task.fileSize && task.fileSize>0 {
                var moveFileSuccess = true
                do {
                    try fileMgr.moveItem(atPath: location.path, toPath: task.savePath())
                }catch {
                    print(error)
                    moveFileSuccess = false
                }
                if moveFileSuccess {
                    downloadStatusChanged(task: task, status: .finished)
                    print("download finished success !")
                    return
                }
            }
            task.downloadTask = nil
            downloadStatusChanged(task: task, status: .failed)
            print("download finished error !")
        }else{
            print("download finished error , YCDownloadTask not found !!!!!")
        }
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
        if ((task?.delegate) != nil) && (task?.delegate?.responds(to: #selector(YCDownloadTaskDelegate.downloadProgress(downloadSize:fileSize:))))! {
            task?.delegate?.downloadProgress!(downloadSize: totalBytesWritten, fileSize: totalBytesExpectedToWrite)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if task.isKind(of: URLSessionDownloadTask.self) {
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
        }else if task.isKind(of: URLSessionUploadTask.self){
            print("upload didCompleteWithError: " + error.debugDescription)
        }

    }
    
    // MARK:upload
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        print("upload progress: \(Float(totalBytesSent) / Float(totalBytesExpectedToSend))")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        
        completionHandler(task.originalRequest?.httpBodyStream)
    }
}

