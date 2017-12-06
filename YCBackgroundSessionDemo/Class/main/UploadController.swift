//
//  UploadController.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/6.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

class UploadController: UIViewController {

    @IBOutlet weak var progressLbl: UILabel!
    @IBOutlet weak var statusLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
    }
    
    class func myController() -> UIViewController {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        return sb.instantiateViewController(withIdentifier: "UploadController")
    }

    @IBAction func start(_ sender: Any) {
    }
    
    @IBAction func pause(_ sender: Any) {
    }
    
    @IBAction func resume(_ sender: Any) {
    }
    
    @IBAction func remove(_ sender: Any) {
    }
}
