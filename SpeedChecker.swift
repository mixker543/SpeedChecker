//
//  SpeedChecker.swift
//  testSpeed
//
//  Created by Sitichai Chumjai on 7/3/2562 BE.
//  Copyright © 2562 Sitichai Chumjai. All rights reserved.
//

import Foundation

@objc enum NetworkSpeedProviderStatusOBJC: Int {
    case poor
    case moderate
    case good
    case excellent
    case unknown
}

enum NetworkSpeedProviderStatus {
    case poor   // BANDWIDTH IS < 150 Kbps
    case moderate  // BANDWIDTH IS  151  to  550 Kbps
    case good // BANDWIDTH IS  551  to  2000 Kbps
    case excellent // BANDWIDTH IS  > 2000 Kbps
    case unknown // BANDWIDTH IS nil or any Error
}
public class NetworkSpeedProvider:NSObject {
    
    func speedTestWithUrl(_ url:String?,completion:@escaping (_ status:NetworkSpeedProviderStatus?)-> Void) {
        guard let url = url else {return}
        let checker = SpeedProvider()
        checker.checkForSpeedTestWithUrl(url) { (status) in
            completion(status)
        }
    }
    @objc func callspeedTestWithUrl(_ url:NSString , completionHandler: @escaping (NetworkSpeedProviderStatusOBJC) -> Void){
        if url != "" {
            let checker = SpeedProvider()
            checker.checkForSpeedTestWithUrl(url as String) { (status) in
                if let status = status {
                    switch status {
                    case .poor:
                        completionHandler(.poor)
                    case .moderate:
                        completionHandler(.moderate)
                    case .good:
                        completionHandler(.good)
                    case .excellent:
                        completionHandler(.excellent)
                    case .unknown:
                        completionHandler(.unknown)
                    }
                }
            }
        }
    }
    
}
class SpeedProvider: NSObject {
    
    typealias speedTestCompletionHandler = (_ kiobytesPerSecond: Double? , _ error: Error?) -> Void
    var speedTestCompletionBlock : speedTestCompletionHandler?
    
    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!
    
    
    func checkForSpeedTestWithUrl(_ url:String ,completion:@escaping (_ status:NetworkSpeedProviderStatus?)-> Void) {
        
        testDownloadSpeedWithTimout(timeout: 5.0, url: url) { (speed, error) in
            print("Download Speed:", speed ?? "NA")
            print("Speed Test Error:", error ?? "NA")
            if let speed = speed {
                if speed > 2000.0 {
                    completion(.excellent)
                }else if speed < 150.0 {
                    completion(.poor)
                } else if speed <= 550.0 {
                    completion(.moderate)
                } else if speed >= 550.0 {
                    completion(.good)
                }
            }else{
                completion(.unknown)
            }
            
            
        }
        
    }
}


extension SpeedProvider: URLSessionDataDelegate, URLSessionDelegate {
    
    func testDownloadSpeedWithTimout(timeout: TimeInterval, url:String,withCompletionBlock: @escaping speedTestCompletionHandler) {
        
        guard let url = URL(string: url) else { return }
        
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = startTime
        bytesReceived = 0
        
        speedTestCompletionBlock = withCompletionBlock
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession.init(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()
        
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived! += data.count
        stopTime = CFAbsoluteTimeGetCurrent()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        let elapsed = stopTime - startTime
        
        if let aTempError = error as NSError?, aTempError.domain != NSURLErrorDomain && aTempError.code != NSURLErrorTimedOut && elapsed == 0  {
            speedTestCompletionBlock?(nil, error)
            return
        }
        
        let speed = elapsed != 0 ? Double(bytesReceived) / elapsed / 1024.0  : -1
        speedTestCompletionBlock?(speed, nil)
        
    }
}
