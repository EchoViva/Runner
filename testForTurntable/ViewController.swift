//
//  ViewController.swift
//  testForTurntable
//
//  Created by EchoWu on 2018/1/25.
//  Copyright © 2018年 EchoWu. All rights reserved.
//

let screen_W: CGFloat = UIScreen.main.bounds.size.width
let screen_H: CGFloat = UIScreen.main.bounds.size.height

import UIKit

class ViewController: UIViewController {
    
    private var circleView: cirCleView?
   
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.circleView = cirCleView()
        self.circleView?.frame = CGRect(x: 0, y: 0, width: screen_W, height: screen_W)
        self.circleView?.backgroundColor = UIColor.lightGray
        self.circleView?.center = self.view.center
        self.view.addSubview(self.circleView!)
        self.getClosure()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func getClosure() {
        
        self.circleView?.clickUserPhotoViewClosure = {
            
//           跳转城市线
        }
        
        self.circleView?.sliderCircleViewClosure = { isRotating in
            
//            print("isRotating = [\(isRotating)]")
        }
        self.circleView?.slideCircleSpanRadiaClosure = { sign in
            
//            每走过30度角
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

