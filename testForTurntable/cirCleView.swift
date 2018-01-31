//
//  circleView.swift
//  testForTurntable
//
//  Created by EchoWu on 2018/1/26.
//  Copyright © 2018年 EchoWu. All rights reserved.
//

import UIKit
import AudioToolbox

class cirCleView: UIView {
    
    private let COUNT = 12
    
    private var circleView    : UIView  = UIView()
    private var slice_radian  : CGFloat = CGFloat()   //slice 以弧度为准
    
    private var inner_radius  : CGFloat = CGFloat()   //userView的半径
    private var outer_radius  : CGFloat = CGFloat()   //circleView的半径
    private var middle_raidus : CGFloat = CGFloat()   //outer_radius - inner_radius
    
    private var centerPoint   : CGPoint = CGPoint()      // 中心点
    
    private var dotViews      : [UIView]  = [UIView]()  //12个View      dotViews
    private var indicatorView : UIView?                 // 转动点   indicatorView
    private var userView      : UIView?                 //userView
    
    private var isRotating    : Bool = false { didSet {
        
        self.sliderCircleViewClosure?(isRotating)
        }
    }
    
    private var indicatorRadian : CGFloat = 0  //指示器的角度
    private var lastRadian      : CGFloat = 0  //上次点击相对于北极的角度
    private var lastHour        : Int     = 0  // 指示器上一个时间点
    
    private var userPhotoUrl    : URL? //传进的头像url JTUser

    var clickUserPhotoViewClosure  : (() -> ())?  // 点击头像
    var sliderCircleViewClosure    : ((_ isRotating: Bool) -> ())?  // 判断是否滑动
    var slideCircleSpanRadiaClosure: ((_ sign: Int) -> ())?
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    override func layoutSubviews() {
        self.onLayout()
    }
    
//    MARK: 时间点+1时考虑取模12，弧度或角度加减考虑取模Double.pi或360
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /*
         //取得点
         //if( 是否在可转范围内 || 是否正在转动)
         // {开始处理转动}
         
         计算 起始化角度 = getAngle();
         
         上次角度 = 起始化角度
         */
        let touch: UITouch = (((touches as NSSet).anyObject() as AnyObject) as! UITouch)
        let point          = touch.location(in: self.circleView)

        if(!self.isInRing(point: point)){
            return
        }
        
        //开始转动
        self.isRotating = true
        self.lastRadian = self.getRadian(point: point)     // 初始角度
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {  // 只调用一次
        /*
         是否正在转动 转动的范围
         
         x,y
         当前角度 = getAngele()
         
         差值 = 当前角度 - 上次角度
         
         差值 切分  //
         
         改布局 onLayout()
         
         上次角度 = 当前角度
         */
        
//        划出转动范围 底层View不滑动
        let touch: UITouch    = (((touches as NSSet).anyObject() as AnyObject) as! UITouch)
        let currentTouchPoint = touch.location(in: self.circleView)
        
        if(!self.isInRing(point: currentTouchPoint)  && (!self.isRotating)) {
            //不在范围内 且 没有在转，表示这个touch不需要处理。
            return
        }
        //开始转动
        self.isRotating = true
        
        //当前手指所在位置的弧度
        let currentRadian = self.getRadian(point: currentTouchPoint)
        
        //本次移动的弧度
        let spanRadian = currentRadian - self.lastRadian < 0 ? (currentRadian  - self.lastRadian + CGFloat(Double.pi * 20) ) : (currentRadian - lastRadian)
        let temporarySpandian = currentRadian - self.lastRadian // 临时变量，判断转动方向（顺/逆）
        
        self.indicatorRadian += spanRadian  // 叠加 总共走了多少度
        self.indicatorRadian = fmod(self.indicatorRadian, CGFloat(2 * Double.pi))
        
        let currentHour = self.getCurrentHour(temporarySpandian, toRadian: self.indicatorRadian, lastHour: lastHour)
        let dHour = currentHour - lastHour  // 判断顺时针和逆时针方向，dHour 和 temporarySpandian不同
    
        if lastHour != currentHour {

            let sign    = dHour > 0 ? 1 : -1
            var tmpHour = lastHour
            while (tmpHour != currentHour) {

                tmpHour = (tmpHour + sign * 1 + COUNT * 3) % COUNT
                _playSound()
                self.slideCircleSpanRadiaClosure?(sign)  // 每滑动三十度角调用一次
            }
        }
        //触发自动布局
        setNeedsLayout()
        
        self.lastRadian = currentRadian
        self.lastHour   = currentHour
    }


    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.touchedEndOrCancel()
        
        /*
         标记，本次结束
         
         取得最近的点
         getNearestPoint();
         自动转过去
         
         重新布局 onLayout()
         */
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.touchedEndOrCancel()
    }
    
    //当手势停下或系统事件（例如手机来电）触发滑动取消时
    private func touchedEndOrCancel() {
        
        if (!self.isRotating){
            //没有在转，表示这个touch不需要处理
            return
        }
        
        //取得最近的点
        let currentHour = self.getNearestHour(indicatorRadian: Double(self.indicatorRadian))
        
        if(lastHour != currentHour){
            //自动转过去
            //_playSoundEnd()
            _playSound()
        }
        
        self.indicatorRadian = CGFloat(currentHour) * slice_radian
        setNeedsLayout()
        
        self.isRotating = false
        self.lastHour   = currentHour
    }
    
    private func _playSound(){
        //1108快门声 1396很轻的bo生 1368 1158
        //当camera是video时，无声音与振动
        AudioServicesPlayAlertSound(1396) //1396
    }
    private func _playSoundEnd(){
        //1108快门声 1396很轻的bo生 1368 1158
        //当camera是video时，无声音与振动
        AudioServicesPlayAlertSound(1108)
    }
    
    
    //初始化布局
    private func onLayout() {
        
        //进行布局
        self.circleView.frame = CGRect(x: 0, y: 0, width: screen_W / 2, height: screen_W / 2)
        
        self.slice_radian    = CGFloat(Double.pi / Double(COUNT/2)) // 12 个imageView的间隔角度
        
        self.outer_radius    = self.circleView.frame.width / 2
        self.inner_radius    = self.circleView.frame.width * 1/6
        self.middle_raidus   = (self.outer_radius - self.inner_radius) / 2 + self.inner_radius
        
        //background view
        let centerX      = self.outer_radius
        let centerY      = self.outer_radius
        self.centerPoint = CGPoint(x: centerX, y: centerY)
        
        self.circleView.center = CGPoint(x: screen_W / 2, y: screen_W / 2)
        self.circleView.layer.cornerRadius = self.outer_radius
        
        //for small dot
        let dotview_radius   = self.middle_raidus / 12
        for i in 0..<self.dotViews.count {
            let dotView   = self.dotViews[i]
            
            dotView.frame = CGRect(x: 0, y: 0, width: dotview_radius * 2, height: dotview_radius * 2)
            dotView.layer.cornerRadius  = dotview_radius
            
            self.onLayoutByAngle(view: dotView , radius: self.middle_raidus, radian: self.slice_radian * CGFloat(i))
        }
        
        //for user info
        self.userView!.frame = CGRect.init(x: 0, y: 0, width: self.inner_radius * 2, height: self.inner_radius * 2)
        self.userView!.layer.cornerRadius  = self.inner_radius
        self.userView!.center = self.centerPoint
        
        //indicator_radius
        let indicator_radius = dotview_radius * 1.3
        self.indicatorView!.frame = CGRect.init(x: 0, y: 0, width: indicator_radius * 2, height: indicator_radius * 2)
        self.indicatorView!.layer.cornerRadius = indicator_radius
        
        self.onLayoutByAngle(view: self.indicatorView!, radius: self.middle_raidus, radian: self.indicatorRadian)
        
    }
    
    //COUNT圆点中心点位置
    private func onLayoutByAngle(view: UIView,radius: CGFloat, radian: CGFloat){
        //uiview angle : 0 - 359
        let viewCenterX: CGFloat = self.centerPoint.x + radius * sin(abs(radian))
        let viewCenterY: CGFloat = self.centerPoint.y - radius * cos(abs(radian))
        
        view.center = CGPoint(x: viewCenterX, y: viewCenterY)
    }
    
    private func initLayout(){
        
        //for circleView
        let circleView: UIView = UIView()
        self.circleView = circleView
        self.circleView.backgroundColor = UIColor.groupTableViewBackground
        self.addSubview(self.circleView)
        
        //for user info
        userView = UIView()
        userView!.backgroundColor     = UIColor.red
        userView!.layer.masksToBounds = true
        userView!.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.tapUserPhotoView(tag:))))
        userView!.isUserInteractionEnabled = true
        self.circleView.addSubview(userView!)
        
        //for small dot
        for _ in 0..<self.COUNT {
            let view: UIView = UIView()
            view.layer.masksToBounds = true
            view.backgroundColor     = UIColor.lightGray
            self.circleView.addSubview(view)
            self.dotViews.append(view)
        }
        
        //动的点（指示器）
        let indicatorView: UIView = UIView()
        indicatorView.backgroundColor = UIColor.black
        self.circleView.addSubview(indicatorView)
        self.indicatorView = indicatorView
        
    }
    
    @objc func tapUserPhotoView(tag: UITapGestureRecognizer) {
        self.clickUserPhotoViewClosure?()
    }

    //0 - 11
    //当手势停下时，获取指示器最近的时间点
    private func getNearestHour(indicatorRadian : Double) -> Int{
        
        let slice_angle     = self.radianToAngle(Double(self.slice_radian))
        let indicator_Angle = self.radianToAngle(Double(indicatorRadian))
        
        let prev_hour: Int = Int(floor(indicator_Angle / slice_angle))
        let last_hour: Int = Int(fmod(Double(prev_hour + 1) , Double(COUNT)))
        
        let prev_df = abs(Double(prev_hour) * slice_angle - indicator_Angle)
        let next_df = (Double(last_hour) * slice_angle - indicator_Angle + 3600).truncatingRemainder(dividingBy: 360)
        
        let returnHour = prev_df < next_df ? prev_hour : last_hour
        return returnHour
    }
    
    //   返回：  0 - 11
    //   获取当前的时间点
    private func getCurrentHour(_ temporarySpandian: CGFloat, toRadian: CGFloat, lastHour: Int) -> Int {
        
        let fromRadian = toRadian - temporarySpandian
        
        var fromHour = lastHour
        var toHour   = lastHour
        
        if temporarySpandian > 0 {  // 顺时针滑动
            fromHour = Int(floor(fromRadian / slice_radian))
            toHour   = Int(floor(toRadian / slice_radian))
        }
        else {   //逆时针滑动
            
            fromHour = Int(floor(fromRadian / slice_radian)) + 1
            toHour   = Int(floor(toRadian / slice_radian)) + 1
            fromHour = Int(fmod(Double(fromHour), 12))
            toHour   = Int(fmod(Double(toHour), 12))   // 在1-2之间时间点均为1，划过1的瞬间，lastHour与currentHuor的时间点值不同
        }
        
        let returnHour = fromHour == toHour ? lastHour : toHour
        return returnHour
    }
    
    //返回：  相对于正北方 ， 0 - pi*2
    private func getRadian(point: CGPoint) -> CGFloat {
        
        let dx: CGFloat = point.x - centerPoint.x
        let dy: CGFloat = point.y - centerPoint.y
        
        let angle = 180 - radianToAngle(atan2(Double(dx), Double(dy))) // 以正北方为参考
        let radian = self.angleToRadian(angle)
        
        return CGFloat(radian)
    }

    // 角度与弧度互转
    private func angleToRadian(_ angle: Double) -> CGFloat {
        return CGFloat(angle / 180 * Double.pi)
    }
    
    private func radianToAngle(_ radian : Double)-> Double{
        return radian * 180 / Double.pi
    }
    
    //是否在可touch范围内
    private func isInRing(point : CGPoint) -> Bool{
        
        let radius   = sqrt(pow(point.y - self.centerPoint.y, 2) + pow(point.x - self.centerPoint.x, 2))
        let isResult = radius < self.outer_radius ? true : false
        
        return isResult
    }
    
    private func _myprint(_ msg: String){
        print(msg)
    }
    
}
