//
//  YCoderObject.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/4.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

class YCoderObject: NSObject, NSCoding {
    
    var ignoreKey = [String]()
    
    //归档
    func encode(with aCoder: NSCoder) {
        
        var count: UInt32 = 0
        
        let ivars = class_copyIvarList(self.classForCoder, &count)
        
        for i in 0..<count {
            
            let ivar = ivars?[Int(i)]
            let name = String.init(cString: ivar_getName(ivar!)!, encoding: .utf8)
            if ignoreKey.contains(name!) { continue }
            if let varName = name {
                aCoder.encode(value(forKey: varName), forKey: varName)
            }
        }
        
        free(ivars)
        
    }
    
    //解档
    required init?(coder aDecoder: NSCoder) {
        
        super.init()
        
        var count: UInt32 = 0
        
        let ivars = class_copyIvarList(self.classForCoder, &count)
        
        for i in 0..<count {
            
            let ivar = ivars?[Int(i)]
            let name = String.init(cString: ivar_getName(ivar!)!, encoding: .utf8)
            if ignoreKey.contains(name!) { continue }
            if let varName = name {
                setValue(aDecoder.decodeObject(forKey: varName), forKey: varName)
            }
        }
        
        free(ivars)
    }
    
    override init() {
        super.init()
    }
    
}
