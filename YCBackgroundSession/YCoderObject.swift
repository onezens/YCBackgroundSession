//
//  YCoderObject.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/4.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

public class YCoderObject: NSObject, NSCoding {
    
    //归档
    public func encode(with aCoder: NSCoder) {
        
        var count: UInt32 = 0
        
        let ivars = class_copyIvarList(self.classForCoder, &count)
        
        for i in 0..<count {
            
            let ivar = ivars?[Int(i)]
            let name = String.init(cString: ivar_getName(ivar!)!, encoding: .utf8)
            if let varName = name {
                let ignoreKey = self.getIgnoreKey()
                if ignoreKey.contains(varName) { continue }
                let value = super.value(forKey: varName)
                aCoder.encode(value, forKey: varName)
            }
        }
        
        free(ivars)
        
    }
    
    //解档
    required public init?(coder aDecoder: NSCoder) {
        
        super.init()
        
        var count: UInt32 = 0
        
        let ivars = class_copyIvarList(self.classForCoder, &count)
        
        for i in 0..<count {
            
            let ivar = ivars?[Int(i)]
            let name = String.init(cString: ivar_getName(ivar!)!, encoding: .utf8)
            if let varName = name {
                let ignoreKey = self.getIgnoreKey()
                if ignoreKey.contains(varName) { continue }
                setValue(aDecoder.decodeObject(forKey: varName), forKey: varName)
            }
        }
        
        free(ivars)
    }
    
    override init() {
        super.init()
    }
    
    @objc func getIgnoreKey() -> [String] {
        return [String]()
    }
    

}
