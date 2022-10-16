//
//  MainVC.swift
//  Spectrometer
//
//  Created by HUAHUA on 2022/5/27.
//

import UIKit
import EasySocialButton

class MainVC: UIViewController{
    
    @IBOutlet weak var idiotMode: AZSocialButton!
    @IBOutlet weak var proMode: AZSocialButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        load()
    }
   
    func load(){
        //idiotMode外形
        idiotMode.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
        proMode.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
    }
    
    @IBAction func clickIdiot(_ sender: Any) {
        
    }
    
    @IBAction func clickPro(_ sender: Any) {
    
    }
}
