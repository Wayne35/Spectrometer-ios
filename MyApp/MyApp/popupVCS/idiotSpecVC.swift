//
//  idiotSpecVC.swift
//  Spectrometer
//
//  Created by HUAHUA on 2022/8/9.
//

import UIKit
import AVFoundation
import GMStepper
import Charts
import EasySocialButton
import NVActivityIndicatorView

class idiotSpecVC: UIViewController{
    
    //定义最后坐标的起始位置和范围
    var start:Double = 0
    var len:Double = 100
    //判断有没有放样品
    var stage1:Bool = true
    var stage2:Bool = false
    var stage3:Bool = false
    var initComplete:Bool = false
    var Sample:Bool = false
    //缓存区和缓存区长度
    var isDenoiseEnable: Bool = true
    var show:Bool = false
    var len_buffer: Int = 15
    var gray_buffer: [[Double]]! = [[]]
    var basic_buffer: [[Double]]! = [[]]
    //初始化位置需要用到两个数组
    var init1:[Double]! = []
    var init2:[Double]! = []
    var init1_buffer:[[Double]]! = [[]]
    var init2_buffer:[[Double]]! = [[]]
    //定义数据数组
    var gray: [Double]! = []
    var basic_gray: [Double]! = []
    //定义图表
    var chartView: LineChartView!
    // 音视频采集会话
    let captureSession = AVCaptureSession()
    // 当前正在使用的设备
    var currentDevice: AVCaptureDevice?
    // 静止图像输出端
    var stillImageOutput: AVCaptureStillImageOutput?
    // 相机预览图层
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    //照片拍摄后预览视图
    var activityIndicatorView: NVActivityIndicatorView!
    //定义计时器
    var timer: Timer?
    //文字框
    var textview: UITextView!
    var inittext: UITextView!
    @IBOutlet weak var SPECView: UIView!
    @IBOutlet weak var pushYes: AZSocialButton!
    override func viewDidLoad() {
        super.viewDidLoad()
         //获取设备，创建UI
        chartView = LineChartView()
        CreateUI()
        initRange()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        TorchOff()
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: Notification.Name("processed"), object: nil)
    }
    
    func processImage() {
        // 获得音视频采集设备的连接
           let videoConnection = stillImageOutput?.connection(with: AVMediaType.video)
           // 输出端以异步方式采集静态图像
           stillImageOutput?.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { (imageDataSampleBuffer, error) -> Void in
                // 获得采样缓冲区中的数据
               if imageDataSampleBuffer != nil{
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)

             // 将数据转换成UIImage
               if let stillImage = UIImage(data: imageData!){
                   self.fillArray(averageNum: 10, interval: 4, image: stillImage)
                    }
               }
          })
    }
    func fillArray(averageNum: Int, interval: Int,image:UIImage){
        gray.removeAll()
        //basic_gray.removeAll()
        //init1.removeAll()
       // init2.removeAll()
        var r_collect = [Double]()
        var row_max = [Int]()
        //获取图片data
        let provider = image.cgImage!.dataProvider
        let providerData = provider!.data
        let data = CFDataGetBytePtr(providerData)
        //获取所有行的数据
        for i in 0..<AnalyseVC.height/interval{
            var sum:Double = 0
            for j in 0..<AnalyseVC.width/interval{
                let x = interval*j
                let y = Int(interval*i) < AnalyseVC.height-1 ? Int(interval*i) : AnalyseVC.height-1
                sum += CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4])/1.0
            }
            r_collect.append(sum)
        }
        //获取最亮的几行
            if averageNum<AnalyseVC.height/interval{
                for _ in 0..<averageNum{
                    var max = 0
                    var index = 0
                    for j in 0..<(AnalyseVC.height/interval-averageNum){
                        if r_collect[j]>Double(max){
                            max = Int(r_collect[j])
                            index = j
                        }
                    }
                    row_max.append(index)
                    r_collect[index] = 0
                }
            }else{
                return
            }
        //将最亮的几行均值化处理
         for i in 0..<AnalyseVC.width{
             var r:Double = 0
             var g:Double = 0
             var b:Double = 0
             for j in 0..<averageNum{
                 let x = i
                 let y = interval*row_max[j] < AnalyseVC.height-1 ? interval*row_max[j] : AnalyseVC.height-1
                 r += CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4])/1.0
                 g += CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4 + 1])/1.0
                 b += CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4 + 2])/1.0
             }
             var sum:Double = 0
             sum += r*30
             sum += g*59
             sum += b*11 + 50
             sum = sum/Double((100*averageNum))
              if(!initComplete && stage1){
                 init1.append(sum)
             }else if(!initComplete && stage2){
                 init2.append(sum)
             }else if(Sample && initComplete){
                 gray.append(sum)
             }else if(!Sample && initComplete){
                 basic_gray.append(sum)
             }
         }
        if(!initComplete && stage1){
            init1_buffer.append(init1)
            init1_buffer.removeFirst()
        }else if(!initComplete && stage2){
            init2_buffer.append(init2)
            init2_buffer.removeFirst()
        }else if(Sample && initComplete){
            gray_buffer.append(gray)
            gray_buffer.removeFirst()
            print("???1")
        }else if(!Sample && initComplete){
            basic_buffer.append(basic_gray)
            basic_buffer.removeFirst()
            print("???2")
        }
    }
    //MARK: - 获取设备,创建自定义视图
    func CreateUI(){
        //文字显示
        textview = UITextView(frame: CGRect(x: 20, y: 470, width: 230, height: 100))
        self.view.addSubview(textview)
        textview.font = UIFont.systemFont(ofSize: 20)
        textview.text = "请在确定没放置样品的情况下按“确定”"
        inittext = UITextView(frame: CGRect(x: 110, y: 470, width: 230, height: 100))
        self.view.addSubview(inittext)
        inittext.font = UIFont.systemFont(ofSize: 20)
        inittext.text = "初始化中，请稍等"
       // analyse.isHidden = true
        textview.isHidden = true
        pushYes.isHidden = true
        //
        activityIndicatorView =  NVActivityIndicatorView(frame: CGRect(x: self.view.center.x - 40, y:  self.view.center.y - 40, width: 80, height: 80), type: .ballSpinFadeLoader, color: UIColor(red: 0, green: 10, blue: 200, alpha: 0.5), padding: 0)
        self.view.addSubview(activityIndicatorView)
        //创建缓存区
        for _ in 1...len_buffer{
            var row = [Double]()
            for _ in 1...AnalyseVC.width{
                row.append(0)
            }
            gray_buffer.append(row)
            basic_buffer.append(row)
            init1_buffer.append(row)
            init2_buffer.append(row)
        }
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
        currentDevice?.exposureMode = .locked
        currentDevice?.setExposureModeCustom(duration: CMTimeMake(value: 1, timescale: 10000), iso: 421, completionHandler: nil)
        currentDevice?.setFocusModeLocked(lensPosition: 0, completionHandler: nil)
        currentDevice?.unlockForConfiguration()
          do {
                // 当前设备输入端
             let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
              self.stillImageOutput = AVCaptureStillImageOutput()
            // 输出图像格式设置
              self.stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
              
            self.captureSession.addInput(captureDeviceInput)
            self.captureSession.addOutput(self.stillImageOutput!)
            }catch {
             print(error)
              return
            }
           // 创建预览图层
        // self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // self.view.layer.addSublayer(cameraPreviewLayer!)
        //self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
       // self.cameraPreviewLayer?.connection?.videoOrientation = .portraitUpsideDown
         //self.cameraPreviewLayer?.frame = CGRect(x: 20, y: 88, width: 210, height: 280)
        // 启动音视频采集的会话
        self.captureSession.startRunning()
        //打开闪光灯
        TorchOn()
        //放大
        zoom(zoomFactor: 5.0)
    }
    
    @objc func drawSpec(){
        chartView.clear()
                   // 获取指定像素颜色
        chartView.frame = CGRect(x: 0, y: 0, width: SPECView.frame.width, height:SPECView.frame.height)
        SPECView.addSubview(chartView)
       
              //设置交互样式
        chartView.noDataText = "请稍等。。。"
        chartView.scaleYEnabled = true //取消Y轴缩放
        chartView.scaleXEnabled = true
        chartView.pinchZoomEnabled = true
        chartView.doubleTapToZoomEnabled = false //双击缩放
        chartView.dragEnabled = true //启用拖动手势
        chartView.dragDecelerationEnabled = true //拖拽后是否有惯性效果
        chartView.dragDecelerationFrictionCoef = 0.9 //拖拽后惯性效果摩擦系数(0~1)越小惯性越不明显
        //x轴定义
        chartView.xAxis.labelPosition = .bottom
        //y轴定义
        let leftAxis = chartView.leftAxis
        chartView.rightAxis.drawLabelsEnabled = false
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 2
 
        var dataEntries = [ChartDataEntry]()
            dataEntries.removeAll()

        var spec = [Double]()
        if(!initComplete){
        for i in 0..<AnalyseVC.width{
            var init1_sum:Double =  0
            var init2_sum:Double = 0
              for k in 0..<len_buffer{
                  init1_sum += init1_buffer[k][i]/Double(len_buffer)
                  init2_sum += init2_buffer[k][i]/Double(len_buffer)
              }
             spec.append(init1_sum/init2_sum)
        }
            start = Double(findRange(spec: spec, len: Int(self.len)))
            print(start)
            chartView.xAxis.axisMinimum = 480
            chartView.xAxis.axisMaximum = 620
            inittext.isHidden = true
        }else{
      for i in 0..<AnalyseVC.width{
            var sum: Double = 0
          var basic_sum: Double = 0
            for k in 0..<len_buffer{
                sum += gray_buffer[k][i]/Double(len_buffer)
                basic_sum += basic_buffer[k][i]/Double(len_buffer)
            }
            let entry = ChartDataEntry.init(x: (480/start)*Double(i), y:sum/basic_sum)
            dataEntries.append(entry)
      }}

        //let xValues = ["480nm","490nm","500nm","510nm","520nm","530nm","540nm","550nm","560nm",
       //                "570nm","580nm","590nm","600nm","610nm","620nm","630nm","640nm","650nm"]
        let formatter = NumberFormatter()
        formatter.positiveSuffix = "nm"
        formatter.formatterBehavior
        chartView.xAxis.valueFormatter = DefaultAxisValueFormatter(formatter: formatter)
        let chartDataSet = LineChartDataSet(entries: dataEntries, label: "吸收光谱")
        chartDataSet.drawValuesEnabled = false //不显示拐点文字
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .cubicBezier //贝塞尔曲线
        chartDataSet.drawFilledEnabled = false //开启填充色绘制
        //折线样式
        chartDataSet.fillColor = .gray //设置填充色
        chartDataSet.fillAlpha = 1 //设置填充色透明度
        chartDataSet.lineWidth = 2.0 //折线宽度
        chartDataSet.colors = [.black]
        let chartData = LineChartData(dataSets: [chartDataSet])
        if(initComplete){chartView.data = chartData
            utils.successInfo(msg: "")
        }
      }
    
    @IBAction func pushYes(_ sender: Any) {
        var cnt:Int = 0
        if(!Sample){
            Thread.detachNewThread {
                self.activityIndicatorView.startAnimating()
            }
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { Timer in
                self.processImage()
                cnt += 1
                if(cnt>self.len_buffer*5){
                    self.Sample = true
                    cnt = 0
                    self.timer?.invalidate()
                    self.activityIndicatorView.stopAnimating()
                    self.textview.text = "请在放置样品后再按“确认”，过程中轻拿轻放。"
                }
            })
        }else if(Sample){
            NotificationCenter.default.addObserver(self, selector: #selector(drawSpec), name: Notification.Name("processed"), object: nil)
            Thread.detachNewThread {
                self.activityIndicatorView.startAnimating()
            }
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { Timer in
                self.processImage()
                cnt += 1
                if(cnt>self.len_buffer*5){
                    self.timer?.invalidate()
                    self.activityIndicatorView.stopAnimating()
                    self.textview.text = "可以更换样品后再按“确认”，过程中轻拿轻放。"
                    //self.textview.isHidden = true
                    //self.pushYes.isHidden = true
                    NotificationCenter.default.post(name: Notification.Name("processed"), object: nil)
                }
            })
        }
    }
    func initRange(){
        NotificationCenter.default.addObserver(self, selector: #selector(drawSpec), name: Notification.Name("initiated"), object: nil)
        var cnt:Int = 0
            Thread.detachNewThread {
                self.activityIndicatorView.startAnimating()
            }
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { Timer in
                self.processImage()
                cnt += 1
                if(cnt>self.len_buffer*10){
                    self.timer?.invalidate()
                    NotificationCenter.default.post(name: Notification.Name("initiated"), object: nil)
                    self.activityIndicatorView.stopAnimating()
                    self.textview.isHidden = false
                    self.pushYes.isHidden = false
                    self.initComplete = true
                }else if(cnt>self.len_buffer*5){
                    self.stage1 = false
                    self.stage2 = true
                }
            })
        }
    func findRange(spec:[Double],len:Int)->Int{
        var start:Int = 0
        var Var:Double = 1000000
        if(spec.count<=len){
            return 0
        }
        for i in 0..<spec.count-len{
            let arr = Array(spec[i..<i+len])
            if(utils.deviationVar(sets: arr)<Var){
                Var = utils.deviationVar(sets: arr)
                start = i
            }
        }
        return start
    }
}


extension idiotSpecVC: UITextFieldDelegate,AVCapturePhotoCaptureDelegate{
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
}
