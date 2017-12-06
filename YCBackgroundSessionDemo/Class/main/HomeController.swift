//
//  HomeController.swift
//  YCBackgroundSession
//
//  Created by wz on 2017/12/6.
//  Copyright © 2017年 cc.onezen. All rights reserved.
//

import UIKit

class HomeController: UIViewController {

    private lazy var tableView = { () -> UITableView in
        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        return tableView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "YCBackgroundSession"
        view.backgroundColor = UIColor.white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
    }
}

extension HomeController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellId = "cellId"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellId)
        }
        if indexPath.row == 0 {
            cell?.textLabel?.text = "download"
            cell?.accessoryType = .disclosureIndicator
        }else if indexPath.row == 1{
            cell?.textLabel?.text = "upload"
            cell?.accessoryType = .disclosureIndicator
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.navigationController?.pushViewController(DownloadController.myController(), animated: true)
        }else if indexPath.row == 1{
            self.navigationController?.pushViewController(UploadController(), animated: true)
        }
    }
    
}
