//
//  Button.swift
//  Calculator
//
//  Created by Frascella Decano on 19/9/17.
//  Copyright © 2017 TeamDecano. All rights reserved.
//

import UIKit

@IBDesignable
class Button: UIButton {
    
    //MARK: Properties
    @IBInspectable var cornerRadius: CGFloat = 3.0 {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 1.0 {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var borderColor = UIColor.white.cgColor {
        didSet {
            setupView()
        }
    }
    
    //MARK: Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        setupView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = cornerRadius
        
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor
    }
}
