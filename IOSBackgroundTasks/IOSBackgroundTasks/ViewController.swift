//
//  ViewController.swift
//  IOSBackgroundTasks
//
//  Created by Student on 24/01/2020.
//  Copyright © 2020 ms. All rights reserved.
//

import UIKit

class ViewController: UIViewController, URLSessionDownloadDelegate {

    @IBOutlet weak var textView: UITextView!
    let URLS: [URL] = [ URL(string: "https://tinyjpg.com/images/social/website.jpg")!
                ]
    var imageTaskList: [ImageDownloadTask] = []
    
    override func viewDidLoad() {

        super.viewDidLoad()
        textView.text = ""
    }

    @IBAction func startButton(_ sender: Any) {
        let urlSession: URLSession = {
            let config = URLSessionConfiguration.background(withIdentifier: "MySession")
            config.isDiscretionary = true
            config.sessionSendsLaunchEvents = true
            return URLSession(configuration: config, delegate: self, delegateQueue: nil)
        }()
        
        for url in URLS {
            let backgroundTask = urlSession.downloadTask(with: url)
            let img = ImageDownloadTask(id: backgroundTask.taskIdentifier, fileName: url.lastPathComponent, progress: 0.00)
            imageTaskList.append(img)
            backgroundTask.resume()
            logToTextView(message: "start downloading image: \(img.id)")
        }
    }

    @IBAction func resetButton(_ sender: Any) {
        textView.text = ""
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        logToTextView(message: "Downloading finished")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress: Double = round(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100.00)
        let id = downloadTask.taskIdentifier
        if let foundObj = imageTaskList.first(where: { $0.id == id}) {
            foundObj.progress = progress
            logToTextView(message: "Printing \(foundObj.id) image with progress: \(foundObj.progress) %% ")
        }
        
    }
    
    func logToTextView(message: String){
        DispatchQueue.main.async {
            self.textView.text += message + "\n"
        }
    }
    
}

class ImageDownloadTask {
    var id: Int
    var fileName: String
    var progress: Double
    
    init(id: Int, fileName: String, progress: Double) {
        self.id = id
        self.fileName = fileName
        self.progress = progress
    }
    
    func setProgress(progress: Double) {
        
    }
}




