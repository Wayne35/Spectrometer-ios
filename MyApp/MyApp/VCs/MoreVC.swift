//
//  MoreVC.swift
//  Spectrometer
//
//  Created by HUAHUA on 2022/1/13.
//

import UIKit

class MoreVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var dataArray: Array<String> = ["About AiLab", "研究内容", "研究团队"]
    var image: UIImage?
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            if let url = URL(string: "http://www.ailabcqu.com"){
                UIApplication.shared.open(url)
            }
        case 1:
            if let url = URL(string: "http://www.ailabcqu.com/page112"){
            UIApplication.shared.open(url)
            }
        case 2:
            if let url = URL(string: "http://www.ailabcqu.com/page105"){
            UIApplication.shared.open(url)
            }
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cellID")
        cell.textLabel?.text = dataArray[indexPath.row]
        //cell.imageView?. image = image
        return cell
    }
}
