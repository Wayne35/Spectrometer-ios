//
//  specFile.swift
//  Spectrometer
//
//  Created by HUAHUA on 2022/5/30.
//

import Foundation
import Charts

class specFile: NSObject, NSCoding{
    
    var red: [Double]!
    var blue: [Double]!
    var green: [Double]!
    var gray: [Double]!
    
    func encode(with coder: NSCoder) {
        coder.encode([Double](), forKey: "red")
        coder.encode([Double](), forKey: "green")
        coder.encode([Double](), forKey: "blue")
        coder.encode([Double](), forKey: "gray")
    }
    
    required init?(coder: NSCoder) {
        red = coder.decodeObject(forKey: "red") as? [Double]
        green = coder.decodeObject(forKey: "green") as? [Double]
        blue = coder.decodeObject(forKey: "blue") as? [Double]
        gray = coder.decodeObject(forKey: "gray") as? [Double]
    }
    
     init(red:[Double],green:[Double],blue:[Double],gray:[Double]) {
        self.red = red
         self.green = green
         self.blue = blue
         self.gray = gray
         super.init()
    }
}
