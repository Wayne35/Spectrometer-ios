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

class idiotTenseVC: UIViewController{
    
    //缓存区和缓存区长度
    var isDenoiseEnable: Bool = true
    var show:Bool = false
    var len_buffer: Int = 15
    var gray_buffer: [[Double]]! = [[]]
    var r_buffer: [[Double]]! = [[]]
    var g_buffer: [[Double]]! = [[]]
    var b_buffer: [[Double]]! = [[]]
    //定义数据数组
    var gray: [Double]! = []
    var red: [Double]! = []
    var green: [Double]! = []
    var blue: [Double]! = []
    
    //定义图表
    var chartView: LineChartView!
    var chartView2: LineChartView!
    // 音视频采集会话
    let captureSession = AVCaptureSession()
    // 当前正在使用的设备
    var currentDevice: AVCaptureDevice?
    // 静止图像输出端
    var stillImageOutput: AVCaptureStillImageOutput?
    // 相机预览图层
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    //rgb位置峰值显示
   
    @IBOutlet weak var r_pos: UILabel!
    @IBOutlet weak var r_tense: UILabel!
    
    @IBOutlet weak var g_pos: UILabel!
    @IBOutlet weak var g_tense: UILabel!
    @IBOutlet weak var b_pos: UILabel!
    @IBOutlet weak var b_tense: UILabel!
    
    @IBOutlet weak var warn: UITextView!
    
    @IBOutlet weak var yes: AZSocialButton!
    //照片拍摄后预览视图
    var activityIndicatorView: NVActivityIndicatorView!
    @IBOutlet weak var RGBView: UIView!
    @IBOutlet weak var SPECView: UIView!
    //定义计时器
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
         //获取设备，创建UI
        CreateUI()
        chartView = LineChartView()
        chartView2 = LineChartView()
        
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
        red.removeAll()
        green.removeAll()
        blue.removeAll()
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
             gray.append(sum)
             red.append(r/Double(averageNum))
             green.append(g/Double(averageNum))
             blue.append(b/Double(averageNum))
         }
        gray_buffer.append(gray)
        gray_buffer.removeFirst()
        r_buffer.append(red)
        r_buffer.removeFirst()
        g_buffer.append(green)
        g_buffer.removeFirst()
        b_buffer.append(blue)
        b_buffer.removeFirst()
        NotificationCenter.default.post(name: Notification.Name("processed"), object: nil)
    }
    //MARK: - 获取设备,创建自定义视图
    func CreateUI(){
        activityIndicatorView =  NVActivityIndicatorView(frame: CGRect(x: self.view.center.x - 30, y:  self.view.center.y - 30, width: 60, height: 60), type: .ballSpinFadeLoader, color: UIColor(red: 0, green: 10, blue: 200, alpha: 0.2), padding: 0)
        self.view.addSubview(activityIndicatorView)
        //创建缓存区
        for _ in 1...len_buffer{
            var row = [Double]()
            for _ in 1...AnalyseVC.width{
                row.append(0)
            }
            gray_buffer.append(row)
            r_buffer.append(row)
            g_buffer.append(row)
            b_buffer.append(row)
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
         self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
         self.view.layer.addSublayer(cameraPreviewLayer!)
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.cameraPreviewLayer?.connection?.videoOrientation = .portraitUpsideDown
         self.cameraPreviewLayer?.frame = CGRect(x: 20, y: 88, width: 210, height: 280)
         //启动音视频采集的会话
        self.captureSession.startRunning()
        //打开闪光灯
        TorchOn()
        //放大
        zoom(zoomFactor: 5.0)
    }
    
    @IBAction func pushYes(_ sender: Any) {
        cameraPreviewLayer?.isHidden = true
        warn.isHidden = true
        yes.isHidden = true
        var cnt:Int = 0
        NotificationCenter.default.addObserver(self, selector: #selector(drawGray), name: Notification.Name("processed"), object: nil)
        Thread.detachNewThread {
            self.activityIndicatorView.startAnimating()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { Timer in
            self.processImage()
            cnt += 1
            if(cnt>self.len_buffer*5){
                self.timer?.invalidate()
                self.activityIndicatorView.stopAnimating()
                utils.successInfo(msg: "")
                self.show = true
            }
        })
    }
    @objc func drawGray(){
        chartView.clear()
        chartView2.clear()
                   // 获取指定像素颜色
        chartView.frame = CGRect(x: 0, y: 0, width: RGBView.frame.width, height:RGBView.frame.height)
        chartView2.frame = CGRect(x: 0, y: 0, width: SPECView.frame.width, height: SPECView.frame.height)
        RGBView.addSubview(chartView)
        SPECView.addSubview(chartView2)
       
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
        leftAxis.axisMaximum = 256
        
        chartView2.noDataText = "请稍等。。。"
        chartView2.scaleYEnabled = true //取消Y轴缩放
        chartView2.scaleXEnabled = true
        chartView2.pinchZoomEnabled = true
        chartView2.doubleTapToZoomEnabled = false //双击缩放
        chartView2.dragEnabled = true //启用拖动手势
        chartView2.dragDecelerationEnabled = true //拖拽后是否有惯性效果
        chartView2.dragDecelerationFrictionCoef = 0.9 //拖拽后惯性效果摩擦系数(0~1)越小惯性越不明显
        //x轴定义
        chartView2.xAxis.labelPosition = .bottom
        //y轴定义
        let leftAxis2 = chartView2.leftAxis
        chartView2.rightAxis.drawLabelsEnabled = false
        leftAxis2.axisMinimum = 0
        leftAxis2.axisMaximum = 256
          
        var dataEntries = [ChartDataEntry]()
        var dataEntries_r = [ChartDataEntry]()
        var dataEntries_g = [ChartDataEntry]()
        var dataEntries_b = [ChartDataEntry]()
            dataEntries.removeAll()
        dataEntries_r.removeAll()
        dataEntries_g.removeAll()
        dataEntries_b.removeAll()
        var rmax: Double = 0
        var gmax: Double = 0
        var bmax: Double = 0
        var rpos: Double = 0
        var gpos: Double = 0
        var bpos: Double = 0
      for i in 0..<AnalyseVC.width{
            var sum: Double = 0
          var r: Double = 0
          var g: Double = 0
          var b: Double = 0
            for k in 0..<len_buffer{
                sum += gray_buffer[k][i]/Double(len_buffer)
                r += r_buffer[k][i]/Double(len_buffer)
                g += g_buffer[k][i]/Double(len_buffer)
                b += b_buffer[k][i]/Double(len_buffer)
            }
            let entry = ChartDataEntry.init(x: Double(i), y:sum)
            let entryr = ChartDataEntry.init(x: Double(i), y:r)
            let entryg = ChartDataEntry.init(x: Double(i), y:g)
            let entryb = ChartDataEntry.init(x: Double(i), y:b)
          if(rmax<r){rmax = r
              rpos = Double(i)}
          if(gmax<g){gmax = g
              gpos = Double(i)}
          if(bmax<b){bmax = b
              bpos = Double(i)}
            dataEntries.append(entry)
            dataEntries_r.append(entryr)
            dataEntries_g.append(entryg)
            dataEntries_b.append(entryb)
      }
                   
        let chartDataSet = LineChartDataSet(entries: dataEntries, label: "灰度谱")
        chartDataSet.drawValuesEnabled = false //不显示拐点文字
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .cubicBezier //贝塞尔曲线
        chartDataSet.drawFilledEnabled = true //开启填充色绘制
        //折线样式
        chartDataSet.fillColor = .gray //设置填充色
        chartDataSet.fillAlpha = 1 //设置填充色透明度
        chartDataSet.lineWidth = 0.0 //折线宽度
        let chartData = LineChartData(dataSets: [chartDataSet])
        if(show){chartView.data = chartData}
        
        let chartDataSet_R = LineChartDataSet(entries: dataEntries_r, label: "R强度谱")
        chartDataSet_R.drawValuesEnabled = false //不显示拐点文字
        chartDataSet_R.drawCirclesEnabled = false
        chartDataSet_R.mode = .horizontalBezier //贝塞尔曲线
        //chartDataSet_R.drawFilledEnabled = true //开启填充色绘制
        //十字线设置
        chartDataSet_R.highlightEnabled = true
        chartDataSet_R.highlightColor = .blue
        chartDataSet_R.highlightLineWidth = 2
        chartDataSet_R.colors = [.red]
        chartDataSet_R.lineWidth = 2.0 //折线宽度‘
        let chartDataSet_G = LineChartDataSet(entries: dataEntries_g, label: "G强度谱")
        chartDataSet_G.drawValuesEnabled = false //不显示拐点文字
        chartDataSet_G.drawCirclesEnabled = false
        chartDataSet_G.mode = .horizontalBezier //贝塞尔曲线
        //chartDataSet_G.drawFilledEnabled = true //开启填充色绘制
        //十字线设置
        chartDataSet_G.highlightEnabled = true
        chartDataSet_G.highlightColor = .blue
        chartDataSet_G.highlightLineWidth = 2
        chartDataSet_G.colors = [.green]
        chartDataSet_G.lineWidth = 2.0 //折线宽度‘
        let chartDataSet_B = LineChartDataSet(entries: dataEntries_b, label: "B强度谱")
        chartDataSet_B.drawValuesEnabled = false //不显示拐点文字
        chartDataSet_B.drawCirclesEnabled = false
        chartDataSet_B.mode = .horizontalBezier //贝塞尔曲线
        //chartDataSet_B.drawFilledEnabled = true //开启填充色绘制
        //十字线设置
        chartDataSet_B.highlightEnabled = true
        chartDataSet_B.highlightColor = .blue
        chartDataSet_B.highlightLineWidth = 2
        chartDataSet_B.colors = [.blue]
        chartDataSet_B.lineWidth = 2.0 //折线宽度‘
        let chartData2 = LineChartData(dataSets: [chartDataSet_R, chartDataSet_G, chartDataSet_B])
        if(show){chartView2.data = chartData2
            r_pos.text = String(afterDecimal(value: rpos, places: 0))
            g_pos.text = String(afterDecimal(value: gpos, places: 0))
            b_pos.text = String(afterDecimal(value: bpos, places: 0))
            r_tense.text = String( afterDecimal(value: chartDataSet_R.yMax, places: 1))
            g_tense.text = String( afterDecimal(value: chartDataSet_G.yMax, places: 1))
            b_tense.text = String( afterDecimal(value: chartDataSet_B.yMax, places: 1))
        }
        
      }
}

extension idiotTenseVC: UITextFieldDelegate,AVCapturePhotoCaptureDelegate{
    func afterDecimal(value :Double, places: Int) -> String{
        let divisor = pow(10.0, Double(places))
        return String(round(value * divisor) / divisor)
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
}

