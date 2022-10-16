//
//  utils.swift
//  Spectrometer
//
//  Created by HUAHUA on 2022/6/7.
//

import Foundation
import UIKit
import SwiftMessages
import AVFoundation

class utils: NSObject{
    //计算方差
    static func deviationVar(sets:[Double])->Double{
        let len = sets.count
        var aver:Double = 0
        var res:Double = 0
        for i in 0..<len{
           aver += sets[i]/Double(len)
        }
        for i in 0..<len{
           res += pow(aver - sets[i], 2)
        }
        return res
    }
    //自动调节感光度
    static func autoISO(device: AVCaptureDevice, image: UIImage){
        var sum:Double = 0
        let provider = image.cgImage!.dataProvider
        let providerData = provider!.data
        let data = CFDataGetBytePtr(providerData)
        //获取所有行的数据
        for i in 0..<AnalyseVC.height{
            for j in 0..<AnalyseVC.width{
                let x = j
                let y = Int(i) < AnalyseVC.height-1 ? Int(i) : AnalyseVC.height-1
                sum += CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4])/1.0
            }
        }
        
        try?  device.lockForConfiguration()
        device.setExposureModeCustom(duration: CMTimeMake(value: 1, timescale: 10000), iso: 611, completionHandler: nil)
        device.exposureMode = .locked
        device.unlockForConfiguration()
    }
    static var DocumentDirectory: NSURL {
        //文件管理对象
        let fileManager = FileManager.default
        //获取DocumentationDirectory对应的文件夹, 类似/Users/angcyo/Library/Documentation/ 这样的
        //当然,你可以创建自定义的文件夹,或者其他文件夹路径...详情参考API文档说明.
        let docPath = fileManager.urls(for: .documentationDirectory, in: .userDomainMask).first!
        //如果文件夹不存在,肯定是不行的. 所以...判断一下.
        if !fileManager.fileExists(atPath: docPath.path) {
            //创建文件夹...
            try! fileManager.createDirectory(atPath: docPath.path, withIntermediateDirectories: true, attributes: nil)
        }
        return docPath as NSURL
        }
    static func smooth(window: Int,array: [Double])->[Double]{
        let length = array.count
        if window == 1{
            return array
        }
        var newArray:[Double]! = []
        for i in 0..<window{
            newArray.append(array[i])
        }
        for i in window - 1..<length{
            var sum:Double = 0
            for j in 0..<window{
                sum += array[i - window + 1 + j]/Double(window)
            }
            newArray.append(Double(sum))
        }
        return newArray
    }
    static func filter(len:Int,center:Int, x: Double,index: Int)->Double{
        var result: Double
        if index < center{
            result = x*pow(Double(index)/Double(center),3)
            print(x,result,index)
            return result
        }else{
            result = x*pow(Double(len - index)/Double(center),3)
            return result
        }
            return x
    }
    static func getAllFilePath(_ dirPath: String) ->[String]{
        var filePaths:[String] = []
        do {
            let array = try FileManager.default.contentsOfDirectory(atPath: dirPath)
            for fileName in array {
                var isDir: ObjCBool = true
                let fullPath = "\(dirPath)/\(fileName)"
                if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir) {
                    if !isDir.boolValue {
                        filePaths.append(fullPath)
                    }
                }
            }
        } catch let error as NSError {
            print("get file path error: \(error)")
        }
        return filePaths
    }
    
    static func deleteFile(filePath: String){
        
        if filePath == nil{
            return
        }
        let dbexist = FileManager.default.fileExists(atPath: filePath)
        if dbexist{
            try! FileManager.default.removeItem(atPath: filePath)
        }
    }
    
    static func successInfo(msg:String){
        var config = SwiftMessages.Config()
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.success)
        view.button?.isHidden = true
        view.configureDropShadow()
        view.configureContent(title: "成功", body: msg)
        view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        config.presentationStyle = .center
        SwiftMessages.show(config: config, view: view)
    }
    static func warningInfo(msg:String){
        var config = SwiftMessages.Config()
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.warning)
        view.button?.isHidden = true
        view.configureDropShadow()
        view.configureContent(title: "警告", body: msg)
        view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        config.presentationStyle = .center
        SwiftMessages.show(config: config, view: view)
    }
}
