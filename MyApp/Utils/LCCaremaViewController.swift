import UIKit
import AVFoundation
import GMStepper

let WIDTH = UIScreen.main.bounds.width
let HEIGHT = UIScreen.main.bounds.height


class LCCaremaViewController: UIViewController{

    // 音视频采集会话
    let captureSession = AVCaptureSession()
    // 后置摄像头
    var backFacingCamera: AVCaptureDevice?
    // 前置摄像头
    var frontFacingCamera: AVCaptureDevice?
    // 当前正在使用的设备
    var currentDevice: AVCaptureDevice?
    // 静止图像输出端
    var stillImageOutput: AVCaptureStillImageOutput?
    // 相机预览图层
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
//    //切换手势
     var dismissGestureRecognizer = UISwipeGestureRecognizer()
//    //放大手势
//    var zoomInGestureRecognizer = UISwipeGestureRecognizer()
//    //缩小手势
//    var zoomOutGestureRecognizer = UISwipeGestureRecognizer()
    //照片拍摄后预览视图
    var photoImageview:UIImageView!
    //照相按钮
    var photoBtn:UIButton!
    //取消按钮/重拍
    var cancel:UIButton!
    //保存按钮
    var save:UIButton!
    //感光度调节
    var iso:GMStepper!
    //放大缩小
    var zoomSlider: UISlider!
    //显示缩放倍数
    var zoomNum: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
         //获取设备，创建UI
        CreateUI()
        //给当前view创建手势
        CreateGestureRecognizer()
        // 创建拍照按钮
        createPhotoBtn()
    }

    @objc func watcher(){
        print(currentDevice?.iso," ",currentDevice?.exposureDuration.value)
    }
    
    //MARK: - 获取设备,创建自定义视图
    func CreateUI(){
         // 将音视频采集会话的预设设置为高分辨率照片--选择照片分辨率
        self.captureSession.sessionPreset = AVCaptureSession.Preset.vga640x480
        // 获取设备
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back){
            self.currentDevice = device
        }else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back){
            self.currentDevice = device
        }else{
            fatalError("missing camera")
        }
        try?  currentDevice?.lockForConfiguration()
          currentDevice?.setExposureModeCustom(duration: CMTimeMake(value: 1, timescale: 10000), iso: 611, completionHandler: nil)
        currentDevice?.exposureMode = .locked
          //currentDevice?.autoFocusRangeRestriction = .near
       // currentDevice?.whiteBalanceMode = .locked
        currentDevice?.unlockForConfiguration()
          do {
                // 当前设备输入端
             let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
              self.stillImageOutput = AVCaptureStillImageOutput()
            // 输出图像格式设置
              self.stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
            self.captureSession.addInput(captureDeviceInput)
            self.captureSession.addOutput(self.stillImageOutput!)
            }
          catch {
             print(error)
              return
            }
           // 创建预览图层
         self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
         self.view.layer.addSublayer(cameraPreviewLayer!)
       // self.cameraPreviewLayer?.connection?.videoOrientation = .portraitUpsideDown
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
         self.cameraPreviewLayer?.frame = view.layer.frame
        
        // 启动音视频采集的会话
        self.captureSession.startRunning()
        //打开闪光灯
        TorchOn()
    }
     //MARK: - 创建手势

    func CreateGestureRecognizer(){
        //self.dismissGestureRecognizer.direction = .down
        //self.dismissGestureRecognizer.addTarget(self, action: #selector(self.dismissCamera))
        //self.view.addGestureRecognizer(dismissGestureRecognizer)
    }

    func createPhotoBtn(){
        //创建缩放
        self.zoomSlider = UISlider.init(frame: CGRect.init(x: WIDTH/2 - 150, y: HEIGHT - 125, width: 300, height: 50))
        self.zoomSlider.maximumValue = 5
        self.zoomSlider.minimumValue = 1
        self.zoomSlider.value = 3
        self.zoomSlider.addTarget(self, action: #selector(ZoomingSlider), for: UIControl.Event.valueChanged)
        self.view.addSubview(self.zoomSlider)
        self.view.bringSubviewToFront(self.zoomSlider)
        //创建缩放倍数显示
        self.zoomNum = UITextField.init(frame: CGRect.init(x: WIDTH/2 - 50, y: 200, width: 100, height: 50))
        self.zoomNum.keyboardType = UIKeyboardType.numberPad
        self.zoomNum.returnKeyType = UIReturnKeyType.done
        self.zoomNum.layer.cornerRadius = 15
        self.zoomNum.layer.borderWidth = 5
        self.zoomNum.layer.borderColor = UIColor.white.cgColor
        self.zoomNum.text = String(4)
        self.zoomNum.font = UIFont.boldSystemFont(ofSize: 30)
        self.zoomNum.textAlignment = NSTextAlignment.center
        self.zoomNum.delegate = self
        self.zoomNum.addTarget(self, action: #selector(didEndEditingZoomNum), for: UIControl.Event.editingDidEnd)
        self.view.addSubview(self.zoomNum)
        self.view.bringSubviewToFront(self.zoomNum)
        //创建感光度调节
        self.iso = GMStepper.init(frame: CGRect.init(x: WIDTH/2 - 100, y: 100, width: 200, height: 50))
        self.iso.addTarget(self, action: #selector(changeExposureModeCustom), for: .valueChanged)
        //self.iso.cornerRadius = 10
        self.iso.value = 30
        self.iso.buttonsBackgroundColor = UIColor.lightGray
        self.iso.labelBackgroundColor = UIColor.gray
        self.view.addSubview(self.iso)
        self.view.bringSubviewToFront(self.iso)
        //创建照相按钮
        self.photoBtn = UIButton.init(frame: CGRect.init(x: WIDTH/2 - 50, y: HEIGHT - 200, width: 100, height: 80))
        self.photoBtn.setImage(UIImage(named:"shot"), for: UIControl.State())
        self.view.addSubview(self.photoBtn)
        self.view.bringSubviewToFront(self.photoBtn)
        self.photoBtn.addTarget(self, action: #selector(self.photoAction), for: .touchUpInside)
        
        //创建取消按钮
        self.cancel = UIButton.init(frame: CGRect.init(x: 50, y: HEIGHT - 200, width: 100, height: 80))
        self.cancel.setImage(UIImage(named:"list"), for: UIControl.State())
       self.cancel.addTarget(self, action: #selector(self.cancelAction), for: .touchUpInside)
        
        //创建保存按钮
        self.save = UIButton.init(frame: CGRect.init(x:WIDTH - 150, y: HEIGHT - 200, width: 100, height: 80))
        self.save.setImage(UIImage(named:"save"), for: UIControl.State())
        self.save.addTarget(self, action: #selector(self.saveAction), for: .touchUpInside)

        // 创建预览照片视图
        self.photoImageview = UIImageView.init(frame: self.view.frame)
        self.photoImageview.isHidden = true
        self.photoImageview.addSubview(self.cancel)
        self.photoImageview.addSubview(self.save)
        self.photoImageview.isUserInteractionEnabled = true
        didEndEditingZoomNum()
        self.view.addSubview(self.photoImageview)
    }
    //输入放大倍数完毕
    @objc func didEndEditingZoomNum(){
        zoomSlider.value = Float(zoomNum.text!)!
        zoom(zoomFactor: Float(zoomNum.text!)!)
    }
    //拖动放大倍数完毕
    @objc func ZoomingSlider(){
        zoomNum.text = afterDecimal(value: Double(zoomSlider.value), places: 2)
        zoom(zoomFactor: Float(zoomNum.text!)!)
    }
    
    func afterDecimal(value :Double, places: Int) -> String{
        let divisor = pow(10.0, Double(places))
        return String(round(value * divisor) / divisor)
    }
    //照相按钮
    @objc func photoAction(){
     // 获得音视频采集设备的连接
        let videoConnection = stillImageOutput?.connection(with: AVMediaType.video)
        // 输出端以异步方式采集静态图像
        stillImageOutput?.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { (imageDataSampleBuffer, error) -> Void in
             // 获得采样缓冲区中的数据
             let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)
          // 将数据转换成UIImage
           if let stillImage = UIImage(data: imageData!) {
               //显示当前拍摄照片
             self.photoImageview.isHidden = false
              self.photoImageview.image = stillImage
       }
       })
    }
  //取消按钮／重拍
  @objc func cancelAction(){
       self.photoImageview.isHidden = true
   }
  //保存按钮-保存到相册
 @objc func saveAction(){
     //关闭闪光灯
     //TorchOff()
      //保存照片到相册
     PhotoAlbumUtil.saveImageInAlbum(image: photoImageview.image!, albumName: "分光图片") { result in
         switch result{
         case .success: break
         case .error: break
         case .denied: break
         }
     }
     NotificationCenter.default.post(name: Notification.Name("photoTaken"), object: self.photoImageview.image)
        self.cancelAction()
     self.dismiss(animated: true, completion: nil)
     }
 }

extension LCCaremaViewController: UITextFieldDelegate,AVCapturePhotoCaptureDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
 
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count != 0{
            if Int(string)! <= 5{
            textField.text = string
            }else{
                textField.text = String(5)
            }
            return false
        }else if string.count == 0{
            textField.text = String(1)
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if Double(textField.text!)! > 5 {
            textField.text = String(5)
        }else if Int(textField.text!)! == 0{
            textField.text = String(1)
        }
    }
    
    //MARK: - 缩放方法
    @objc func zoom(zoomFactor: Float) {
                do {
                    try currentDevice?.lockForConfiguration()
                    currentDevice?.ramp(toVideoZoomFactor: min(10.0,CGFloat(zoomFactor)), withRate: 123.0)
                    currentDevice?.unlockForConfiguration()
            }
             catch {
                     print(error)
                }
    }

    //MARK: - 开启闪光灯
    func TorchOn(){
       try? currentDevice?.lockForConfiguration()
        if ((currentDevice?.isTorchAvailable) != nil) {
            currentDevice?.torchMode = .on
        }
        currentDevice?.unlockForConfiguration()
    }
    
    //MARK: - 关闭闪光灯
    func TorchOff(){
      try?  currentDevice?.lockForConfiguration()
        if ((currentDevice?.isTorchAvailable) != nil) {
            currentDevice?.torchMode = .off
        }
        currentDevice?.unlockForConfiguration()
    }
    
    //MARK: - 关闭闪光灯
    @objc func changeExposureModeCustom(){
      try?  currentDevice?.lockForConfiguration()
        currentDevice?.setExposureModeCustom(duration: CMTimeMake(value: 1, timescale: 10000), iso: 21+Float(self.iso.value)*19, completionHandler: nil)
        currentDevice?.setFocusModeLocked(lensPosition: 0, completionHandler: nil)
       // print("该镜头最小焦距：",currentDevice?.minimumFocusDistance)
        //print("最大感光度: ",currentDevice?.activeFormat.maxISO," 最小感光度: ",currentDevice?.activeFormat.minISO)
        //print("感光度：", currentDevice?.iso)
       // print("曝光模式：", currentDevice?.exposureMode.rawValue)
        //print(currentDevice?.focusMode.rawValue)
        currentDevice?.unlockForConfiguration()
       
    }
    
    //MARK: - 退出方法
     @objc func dismissCamera() {
         self.dismiss(animated: true, completion: nil)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

