//
//  AnalyseVC.swift
//  Spectrometer
//
//  Created by HUAHUA on 2022/1/13.
//

import UIKit
import GMStepper
import VerticalSlider
import EasySocialButton
import Charts
import SwiftMessages
import NVActivityIndicatorView

class AnalyseVC: UIViewController{
       
//定义数据数组
    var dataEntries = [ChartDataEntry]()
    var dataEntries_R = [ChartDataEntry]()
    var dataEntries_G = [ChartDataEntry]()
    var dataEntries_B = [ChartDataEntry]()
    //定义加载条
    var activityIndicatorView: NVActivityIndicatorView!
    
    var red: [Double]! = []
    var blue: [Double]! = []
    var green: [Double]! = []
    var gray: [Double]! = []
    //定义存储名字
    var fileName: String?
    //  文件存档的文件夹, 类似: /Users/angcyo/Library 这样的路径
   
    var image: UIImage?
    var chartView: LineChartView!
    var flag: Bool?
    static let width = 480
    static let height = 640
    
    @IBOutlet weak var ButtonGray: AZSocialButton!
    @IBOutlet weak var ButtonSave: AZSocialButton!
    @IBOutlet weak var RGBView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var slider: VerticalSlider!
    @IBOutlet weak var stepper: GMStepper!
    @IBOutlet weak var Red: UILabel!
    @IBOutlet weak var Green: UILabel!
    @IBOutlet weak var Blue: UILabel!
    
    override func viewDidLoad() {
        //通知
        super.viewDidLoad()
        chartView = LineChartView()
        NotificationCenter.default.addObserver(self, selector: #selector(setImageOnImageView), name: Notification.Name("ToDo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(drawRGB), name: Notification.Name("imageAcquired"), object: nil)
        load()
    }
    
    @IBAction func clickButtonSave(_ sender: AZSocialButton) {
        fillArray(averageNum: 5, interval: 1)
        let dialog = UIAlertController(title: "文件命名", message: "为您保存的数据进行命名", preferredStyle: .alert)
        dialog.addTextField  {
            (textField: UITextField!) -> Void in
            textField.placeholder = "请输入名称"
        }
        let cancel = UIAlertAction(title: "取消", style: .default, handler: nil)
        let ok = UIAlertAction(title: "确认", style: .default) { UIAlertAction in
            var Title: String = " Data_"
            if ((dialog.textFields?.first?.text?.count) == 0){
                utils.warningInfo(msg: "数据名字不能为空")
            }else{
                Title.append((dialog.textFields?.first?.text)!)
                self.fileName = Title
            //创建一个模型对象
                let rgbData = specFile(red: self.red,green: self.green,blue:self.blue,gray: self.gray)
                let isSuccessSave = NSKeyedArchiver.archiveRootObject(rgbData, toFile: utils.DocumentDirectory.appendingPathComponent(self.fileName!)!.path)
                if isSuccessSave {
                    utils.successInfo(msg: "成功保存为"+Title)
                } else {
                    print("no")
                }
                let defaults = UserDefaults.standard
                self.gray = utils.smooth(window: 5, array: self.gray)
                defaults.set(self.gray, forKey: self.fileName!+"_gray")
            }
        }
        dialog.addAction(cancel)
        dialog.addAction(ok)
        self.present(dialog, animated: true, completion: nil)
    }

    
    @objc func drawRGB(){
        chartView.clear()
                 // 获取指定像素颜色
        chartView.frame = CGRect(x: 0, y: 0, width: RGBView.frame.width, height: RGBView.frame.height)
        RGBView.addSubview(chartView)
     
            //设置交互样式
        chartView.noDataText = "没有数据"
            chartView.scaleYEnabled = true //取消Y轴缩放
            chartView.scaleXEnabled = true
            chartView.pinchZoomEnabled = true
            chartView.doubleTapToZoomEnabled = false //双击缩放
            chartView.dragEnabled = true //启用拖动手势
            chartView.dragDecelerationEnabled = true //拖拽后是否有惯性效果
            chartView.dragDecelerationFrictionCoef = 0.9 //拖拽后惯性效果摩擦系数(0~1)越小惯性越不明显
            //chartView.setVisibleYRangeMinimum(1,axis: chartView.leftAxis.axisDependency)
        chartView.animate(yAxisDuration: 0.5)
        //x轴定义
        chartView.xAxis.labelPosition = .bottom
        //y轴定义
        let leftAxis = chartView.leftAxis
        chartView.rightAxis.drawLabelsEnabled = false
         leftAxis.axisMinimum = 0
         leftAxis.axisMaximum = 256
        var position = Int(100 - slider.value)*AnalyseVC.height/100
        //获取图片的data
        let provider = image?.cgImage!.dataProvider
        let providerData = provider!.data
        let data = CFDataGetBytePtr(providerData)
    
        //折线图描述文字和样式
        dataEntries_R.removeAll()
        for i in 0..<AnalyseVC.width{
            let x = i
            let y = Int(position) < AnalyseVC.height-1 ? Int(position) : AnalyseVC.height-1
            let value = CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4])/1.0
            let entry = ChartDataEntry.init(x: Double(i), y: Double(value))
            dataEntries_R.append(entry)
        }

        let chartDataSet_R = LineChartDataSet(entries: dataEntries_R, label: "R强度谱")
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
        
        
        //折线图描述文字和样式
        dataEntries_G.removeAll()
        for i in 0..<AnalyseVC.width{
            let x = i
            let y = Int(position) < AnalyseVC.height-1 ? Int(position) : AnalyseVC.height-1
            let value = CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4 + 1])/1.0
            let entry = ChartDataEntry.init(x: Double(i), y: Double(value))
            dataEntries_G.append(entry)
        }

        let chartDataSet_G = LineChartDataSet(entries: dataEntries_G, label: "G强度谱")
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
        
        //折线图描述文字和样式
        dataEntries_B.removeAll()
        for i in 0..<AnalyseVC.width{
            let x = i
            let y = Int(position) < AnalyseVC.height-1 ? Int(position) : AnalyseVC.height-1
            let value = CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4 + 2])/1.0
            let entry = ChartDataEntry.init(x: Double(i), y: Double(value))
            dataEntries_B.append(entry)
        }
        
        let chartDataSet_B = LineChartDataSet(entries: dataEntries_B, label: "B强度谱")
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
        
        let chartData = LineChartData(dataSets: [chartDataSet_R, chartDataSet_G, chartDataSet_B])
        chartView.data = chartData
       
        Red.text = String( afterDecimal(value: chartDataSet_R.yMax, places: 2))
        Green.text = String( afterDecimal(value: chartDataSet_G.yMax, places: 2))
        Blue.text = String( afterDecimal(value: chartDataSet_B.yMax, places: 2))
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func drawGray(){
        chartView.clear()

            // 获取指定像素颜色
        chartView.frame = CGRect(x: 0, y: 0, width: RGBView.frame.width, height: RGBView.frame.height)
        RGBView.addSubview(chartView)
     
            //设置交互样式
            chartView.noDataText = "没有数据"
            chartView.scaleYEnabled = true //取消Y轴缩放
            chartView.scaleXEnabled = true
            chartView.pinchZoomEnabled = true
            chartView.doubleTapToZoomEnabled = false //双击缩放
            chartView.dragEnabled = true //启用拖动手势
            chartView.dragDecelerationEnabled = true //拖拽后是否有惯性效果
            chartView.dragDecelerationFrictionCoef = 0.9 //拖拽后惯性效果摩擦系数(0~1)越小惯性越不明显
            //chartView.setVisibleYRangeMinimum(1,axis: chartView.leftAxis.axisDependency)
        chartView.animate(yAxisDuration: 0.5)
        //x轴定义
        chartView.xAxis.labelPosition = .bottom
        //y轴定义
        let leftAxis = chartView.leftAxis
        chartView.rightAxis.drawLabelsEnabled = false
         leftAxis.axisMinimum = 0
         leftAxis.axisMaximum = 256
        let position = Int(100 - slider.value)*AnalyseVC.height/100
    
        //获取图片的data
        let provider = image?.cgImage!.dataProvider
        let providerData = provider!.data
        let data = CFDataGetBytePtr(providerData)
        //折线图描述文字和样式
        dataEntries.removeAll()
        for i in 0..<AnalyseVC.width{
            let x = i
            let y = Int(position) < AnalyseVC.height-1 ? Int(position) : AnalyseVC.height-1
            let r = CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4])/1.0
            let g = CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4 + 1])/1.0
            let b = CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4 + 2])/1.0
            let value = (r*30+g*59+b*11+50)/100
            let entry = ChartDataEntry.init(x: Double(i), y: Double(value))
            dataEntries.append(entry)
        }

        let chartDataSet = LineChartDataSet(entries: dataEntries, label: "灰度谱")
        chartDataSet.drawValuesEnabled = false //不显示拐点文字
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .horizontalBezier //贝塞尔曲线
        chartDataSet.drawFilledEnabled = true //开启填充色绘制
        //十字线设置
        chartDataSet.highlightEnabled = true
        chartDataSet.highlightColor = .blue
        chartDataSet.highlightLineWidth = 2

        chartDataSet.fillColor = .gray //设置填充色
        chartDataSet.fillAlpha = 1 //设置填充色透明度
        chartDataSet.lineWidth = 0.0 //折线宽度
        let chartData = LineChartData(dataSets: [chartDataSet])
        chartView.data = chartData
    }
     
    func fillArray(averageNum: Int, interval: Int){
        Thread.detachNewThread {
            self.activityIndicatorView.startAnimating()
        }
        var r_collect = [Double]()
        var row_max = [Int]()
        //获取图片的data
        let provider = image?.cgImage!.dataProvider
        let providerData = provider!.data
        let data = CFDataGetBytePtr(providerData)
        for i in 0..<AnalyseVC.height/interval{
            var sum:Double = 0
            for j in 0..<AnalyseVC.width/interval{
                let x = interval*j
                let y = Int(interval*i) < AnalyseVC.height-1 ? Int(interval*i) : AnalyseVC.height-1
                sum += CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4])/1.0
                sum += CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4 + 1])/1.0
                sum += CGFloat(data![((Int(AnalyseVC.height) * x) + y) * 4 + 2])/1.0
            }
            r_collect.append(sum)
        }
            if averageNum<AnalyseVC.height/interval{
                for i in 0..<averageNum{
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
             var value = (r*30+g*59+b*11+50)/100
             value = value/Double(averageNum)
             gray.append(value)
         }
        activityIndicatorView.stopAnimating()
    }
    func load(){
        flag = false //默认情况下画rgb
        let singleTapGesture = UITapGestureRecognizer(target: self, action:#selector(clickImageView))
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.isContinuous = false
        imageView.addGestureRecognizer(singleTapGesture)
        imageView.isUserInteractionEnabled = true
        ButtonGray.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
        ButtonSave.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
        activityIndicatorView =  NVActivityIndicatorView(frame: CGRect(x: self.view.center.x - 30, y:  self.view.center.y - 30, width: 60, height: 60), type: .ballSpinFadeLoader, color: UIColor(red: 0, green: 10, blue: 200, alpha: 0.2), padding: 0)
        self.view.addSubview(activityIndicatorView)
    }
    
    @objc func setImageOnImageView(noti :Notification){
        image = noti.object as? UIImage
        if image == nil{
            return
        }
        var orientation = ((image?.imageOrientation.rawValue)! + 4) % 8
        orientation += orientation%2==0 ? 1 : -1
        let flippedImage = UIImage(cgImage: (image?.cgImage!)!, scale: image!.scale, orientation: UIImage.Orientation(rawValue: orientation)!)
        NotificationCenter.default.post(name: Notification.Name("imageAcquired"), object: nil)
        imageView.image = flippedImage
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func clickButtonGray(_ sender: AZSocialButton) {
        flag = !flag!
        if(!flag!){
            drawRGB()
        }else{
            drawGray()
        }
    }

    @objc func clickImageView(){

    }
    @objc func sliderChanged(){
        stepper.value = Double(roundf(slider.value))
        if(!flag!){drawRGB()
        }else{drawGray()}
    }
    
    @IBAction func clickStepper(_ sender: GMStepper) {
        slider.value = Float(sender.value)
        if(!flag!){drawRGB()
        }else{drawGray()}
    }
    func afterDecimal(value :Double, places: Int) -> String{
        let divisor = pow(10.0, Double(places))
        return String(round(value * divisor) / divisor)
    }
}
