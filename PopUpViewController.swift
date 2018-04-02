//
//  PopUpViewController.swift
//  Project1
//
//  Created by Infield Infotech on 3/6/18.
//  Copyright © 2018 Infield Infotech. All rights reserved.
//

import UIKit

class PopUpViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
       
    }
    
    @IBAction func okPopUpBtn(_ sender: UIButton) {
        dismiss(animated: true, completion: nil);
        
    }

}
