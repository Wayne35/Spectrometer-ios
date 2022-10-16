//
//  FirstVC.swift
//
//
//  Created by HUAHUA on 2022/1/13.
//

import UIKit
import EasySocialButton

class FirstVC: UIViewController {
    
    var image: UIImage?
   
    @IBOutlet weak var ButtonCamera: AZSocialButton!
    @IBOutlet weak var ButtonPresent: AZSocialButton!


    var scrollView: UIScrollView!
    var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       load()

       // imageView = UIImageView(image:UIImage(named: "noPhoto"))
        NotificationCenter.default.addObserver(self, selector: #selector(showImageJustTaken), name: Notification.Name("photoTaken"), object: nil)
    }
    
    func load(){
        scrollView = UIScrollView(frame: CGRect(x: additionalSafeAreaInsets.left, y:88, width: self.view.bounds.width, height: self.view.bounds.height - 250))
        scrollView.contentSize = CGSize(width: 2*self.view.bounds.width, height: 2*self.view.bounds.height)
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.0
        scrollView.bounces = true
        scrollView.backgroundColor = .gray
        scrollView.delegate = self
        imageView = UIImageView(image:UIImage(named: "noPhoto"))
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapImageView)))
        imageView.frame =  scrollView.bounds
        scrollView.addSubview(imageView)
        self.view.addSubview(scrollView)
    
    }
    
    @objc func showImageJustTaken(noti: Notification){
        imageView.image = noti.object as? UIImage
        image = imageView.image
    }
    @IBAction func clickButtonCamera(_ sender: AZSocialButton) {
        let cameraVC = LCCaremaViewController()
        self.navigationController?.pushViewController(cameraVC, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendImage"{
            let vc = segue.destination as! TabbarVC
            vc.image = sender as? UIImage
        }
    }
    
    @IBAction func clickPresent(_ sender: AZSocialButton) {
        performSegue(withIdentifier: "sendImage", sender: image)
    }

@objc func tapImageView(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
       present(picker, animated: true, completion: nil)
    }
}
extension FirstVC:UIScrollViewDelegate{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      return  imageView
    }
}
extension FirstVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        imageView.image = info[.originalImage] as? UIImage
        image = imageView.image
    }
}
extension UIImage{
    func crop(startPoint: CGPoint,customSize: CGSize) -> UIImage{
        var newSize: CGSize
        newSize = CGSize(width: size.width < customSize.width ? size.width : customSize.width, height:  size.height < customSize.height ? size.height : customSize.height)
        let rect = CGRect(x: startPoint.x, y: startPoint.y, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContext(newSize)
        draw(in: rect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
}
