//
//  SpecVC.swift
//  Spectrometer
//
//  Created by HUAHUA on 2022/1/13.
//

import UIKit
import Charts

class MyTableViewCell: UITableViewCell{
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    static let reusedIdentifierString = "MyTableViewCell"
}

class SpecVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //定义选中行
    var selectIndex: IndexPath?
    //定义用户标准
    let defaults = UserDefaults.standard
    //
    var filePaths:[String] = []
    var filePath = utils.DocumentDirectory.path
    //定义数据数组
    var gray: [Double]! = []
    var basicGray: [Double]! = []
    var spec:[Double]! = []
    
    var dataEntries = [ChartDataEntry]()
    var dataEntries_R = [ChartDataEntry]()
    var dataEntries_G = [ChartDataEntry]()
    var dataEntries_B = [ChartDataEntry]()
    //定义图表
    var chartView: LineChartView!
    @IBOutlet weak var ButtonSpec: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var RGBView: UIView!
    var table: UITableView! = UITableView()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        table.delegate = self
        tableView.dataSource = self
        table.dataSource = self
        chartView = LineChartView()
        ButtonSpec.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
        //获取目录中所有文件
        filePaths = utils.getAllFilePath(filePath!)
       
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
    func drawSpec(){
        chartView.clear()
                 // 获取指定像素颜色
        chartView.frame = CGRect(x: 0, y: 0, width: RGBView.frame.width, height: RGBView.frame.height)
        RGBView.addSubview(chartView)
     
            //设置交互样式
        chartView.noDataText = "没有数据"
            chartView.scaleYEnabled = false //取消Y轴缩放
            chartView.scaleXEnabled = true
            chartView.pinchZoomEnabled = true
            chartView.doubleTapToZoomEnabled = false //双击缩放
            chartView.dragEnabled = true //启用拖动手势
            chartView.dragDecelerationEnabled = true //拖拽后是否有惯性效果
            chartView.dragDecelerationFrictionCoef = 0.9 //拖拽后惯性效果摩擦系数(0~1)越小惯性越不明显
            //chartView.setVisibleYRangeMinimum(1,axis: chartView.leftAxis.axisDependency)
        chartView.animate(yAxisDuration: 1)
        //x轴定义
        chartView.xAxis.labelPosition = .bottom
        //y轴定义
        let leftAxis = chartView.leftAxis
        chartView.rightAxis.drawLabelsEnabled = false
         leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 1.5
    
        //折线图描述文字和样式
        dataEntries.removeAll()
        spec.removeAll()
        for i in 0..<AnalyseVC.width{
            spec.append(Double(gray[i]/basicGray[i]))
        }
        spec = utils.smooth(window: 3, array: spec)
        for i in 0..<AnalyseVC.width{
            var value: Double
            value = utils.filter(len: AnalyseVC.width, center: 250, x: spec[i], index: i)
            let entry = ChartDataEntry.init(x: Double(i), y: Double(spec[i]))
            dataEntries.append(entry)
        }
        let chartDataSet = LineChartDataSet(entries: dataEntries, label: "透射光谱")
        chartDataSet.drawValuesEnabled = false //不显示拐点文字
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .cubicBezier //贝塞尔曲线
        chartDataSet.drawFilledEnabled = false //开启填充色绘制
        //十字线设置
        chartDataSet.highlightEnabled = true
        chartDataSet.highlightColor = .gray
        chartDataSet.highlightLineWidth = 2
    
        chartDataSet.fillColor = .gray //设置填充色
        chartDataSet.fillAlpha = 1 //设置填充色透明度
        chartDataSet.lineWidth = 2.0 //折线宽度
        chartDataSet.colors = [.black]
        let chartData = LineChartData(dataSets: [chartDataSet])
        chartView.data = chartData
    }
    func drawGray(){
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
        chartView.animate(yAxisDuration: 1)
        //x轴定义
        chartView.xAxis.labelPosition = .bottom
        //y轴定义
        let leftAxis = chartView.leftAxis
        chartView.rightAxis.drawLabelsEnabled = false
         leftAxis.axisMinimum = 0
         leftAxis.axisMaximum = 256
    
        //折线图描述文字和样式
        dataEntries.removeAll()
        for i in 0..<AnalyseVC.width{
            let entry = ChartDataEntry.init(x: Double(i), y: Double(gray[i]))
            dataEntries.append(entry)
        }
        let chartDataSet = LineChartDataSet(entries: dataEntries, label: "灰度谱")
        chartDataSet.drawValuesEnabled = false //不显示拐点文字
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.mode = .cubicBezier //贝塞尔曲线
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
    
    @IBAction func clickButtonSpec(_ sender: UIButton) {
        initDataSheet()
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "删除该数据"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete{
            utils.deleteFile(filePath: filePaths[indexPath.row])
            
            var str =  filePaths[indexPath.row]
            str.removeFirst(99)
            filePaths.remove(at: indexPath.row)
            defaults.removeObject(forKey: str+"_gray")
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var str =  filePaths[indexPath.row]
        str.removeFirst(99)
        print(filePaths[indexPath.row])
        gray = defaults.array(forKey: str+"_gray") as? [Double]
        drawGray()
        //
        if selectIndex == nil{
            selectIndex = indexPath
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .checkmark
        }else{
            let celled = tableView.cellForRow(at: selectIndex!)
            celled?.accessoryType = .none
            selectIndex = indexPath
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .checkmark
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filePaths.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        CGFloat(70)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //
        let cell = tableView.dequeueReusableCell(withIdentifier: MyTableViewCell.reusedIdentifierString, for: indexPath) as! MyTableViewCell
        //
        if(selectIndex == indexPath){
            cell.accessoryType = .checkmark
        }else{
            cell.accessoryType = .none
        }
        var str =  filePaths[indexPath.row]
        str.removeFirst(99)
        cell.label?.text = str
        return cell
    }
    func initDataSheet(){
        if selectIndex == nil{
            utils.warningInfo(msg: "请选择一组数据进行分析")
        }else{
        let alert = UIAlertController(style: .actionSheet)
                var infos: [LocaleInfo] = []
        for i in 0..<filePaths.count {
            var str =  filePaths[i]
            str.removeFirst(99)
                    infos.append(LocaleInfo(country: str, selected: false))
                }
                var data = [String: [LocaleInfo]]()
                LocaleStore.fetch(info: infos) { [unowned self] result in
                    switch result {
                    case .success(let orderedInfo):
                        data = orderedInfo
                    case .error(let error):
                        break
                    }
                }
      
                alert.addLocalePicker(data: data, type: .country) { info in
                    if(info!.count > 1){
                        utils.warningInfo(msg: "只能选择一组数据")
                    }else{
                        var str = info?.last?.country
                        str?.append("_gray")
                        self.basicGray = self.defaults.array(forKey: str!) as? [Double]
                        self.drawSpec()
                    }
                }
            alert.addAction(title: "取消", style: .cancel)
            alert.show()
        }
}
}

