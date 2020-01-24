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
    @IBOutlet weak var imageView: UIImageView!
    let URLS: [URL] = [ URL(string: "http://www.familydent.waw.pl/static/b24/2017/02/439b22b2d63fb9922ebf396afe424f27.jpeg")!
                ]
    var imageTaskList: [ImageDownloadTask] = []
    let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
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
            logToTextView(message: " - Start downloading image from url: \(url.absoluteString)")
        }
    }

    @IBAction func resetButton(_ sender: Any) {
        textView.text = ""
    }
    
    let fileManager = FileManager.default
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let id = downloadTask.taskIdentifier
        
        if let foundObj = imageTaskList.first(where: { $0.id == id }) {
            logToTextView(message: " - Downloading \(foundObj.fileName) finished. Temporary directory: \(location.absoluteString)")
            
            let dstUrl = URL(string: "file://\(docDir)\(foundObj.fileName)")!
            let srcUrl = location
            if (fileManager.fileExists(atPath: docDir + foundObj.fileName)){
                do {
                    try fileManager.removeItem(at: dstUrl)
                } catch (let error){
                    logToTextView(message: " - Cannot remove file at \(dstUrl.absoluteString): \(error)")
                }
            }
            
            do {
                try fileManager.copyItem(at: srcUrl, to: dstUrl)
                logToTextView(message: " - Copied file to documents directory \n \(dstUrl.absoluteString)")
            }
            catch (let error) {
                logToTextView(message: " - Cannot copy file at \(srcUrl.absoluteString) to \n \(dstUrl.absoluteString): \(error)")
            }
            
            DispatchQueue.main.async {
                self.imageView.image = UIImage(contentsOfFile: self.docDir + foundObj.fileName)
                self.detect();
            }
            
        }
        imageTaskList.removeAll(where: { $0.id == id })
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress: Double = round(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 10.00)
        let id = downloadTask.taskIdentifier
        if let foundObj = imageTaskList.first(where: { $0.id == id}) {
            if (foundObj.setProgress(progress: progress)) {
                logToTextView(message: " - Downloading \(foundObj.fileName), \(foundObj.progress * 10) % done... ")
            }
        }
        
    }
    
    func logToTextView(message: String){
        DispatchQueue.main.async {
            self.textView.text += message + "\n"
        }
    }
    
    func detect() {
        logToTextView(message: " - Start face detection.")
        guard let personciImage = CIImage(image: self.imageView.image!) else {
            return
        }
        
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector!.features(in: personciImage)
        
        for face in faces as! [CIFaceFeature] {
            
            print("Found bounds are \(face.bounds)")
            
            let faceBox = UIView(frame: face.bounds)
            
            faceBox.layer.borderWidth = 30
            faceBox.layer.borderColor = UIColor.red.cgColor
            self.imageView.addSubview(faceBox)
        }
        logToTextView(message: " - Finish face detection. Found \(faces.count) face.")
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
    
    func setProgress(progress: Double) -> Bool {
        if (progress > self.progress) {
            self.progress = progress
            return true
        }
        return false
    }
}




