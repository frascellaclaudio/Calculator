//
//  ViewController.swift
//  Calculator
//
//  Created by Frascella Claudio on 6/26/17.
//  Copyright © 2017 TeamDecano. All rights reserved.
//
// lectures from Developing iOS 10 Apps in Swift 
// - Stanford Instructor: Paul Hegarty
import UIKit

class ViewController: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var descriptionDisplay: UILabel!
    @IBOutlet weak var memoryDisplay: UILabel!
    
    //MARK: Private properties
    private var brain = CalculatorBrain() // create instance
    private var userIsInTheMiddleOfTyping = false
    private var displayValue: Double {
        get {
            let displayText = Double(display.text!) ?? 0
            return displayText
        }
        set {
            display.text = newValue.isNaN ? "Not a number" : newValue.displayFormatted
        }
    }
    private var memoryVars : Dictionary<String,Double>? {
        didSet {
            for (key, value) in memoryVars! {
                memoryDisplay.text = key + ":" + "\(value.displayFormatted) "
            }
        }
    }
    
    //MARK: Actions
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        
        if userIsInTheMiddleOfTyping {
            if (digit == "." && display.text!.contains(".")) {
                return
            }
            let textCurrentlyInDisplay = display.text! == "0" && digit != "." ? "" : display.text!
            display.text = textCurrentlyInDisplay + digit
        } else {
            display.text = (digit == ".") ? ("0" + digit) : digit
            userIsInTheMiddleOfTyping = true
        }
    }

    @IBAction func backspace(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            var displayText: String? = display.text!
            guard (displayText?.characters.count)! > 1 else {
                display.text = "0"
                userIsInTheMiddleOfTyping = false
                return
            }
            displayText!.remove(at: displayText!.index(before: displayText!.endIndex))
            display.text = displayText
        } else {
            brain.undo()
            calculate()
        }
    }

    @IBAction func performOperation(_ sender: UIButton) {
        if display.text == "Not a number" && sender.currentTitle != "C" {
            return
        }
        
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        
        calculate()
    }
    
    //C button
    @IBAction func clear(_ sender: UIButton) {
        userIsInTheMiddleOfTyping = false
        brain = CalculatorBrain()
        displayValue = 0
        descriptionDisplay.text = " "
        memoryVars = Dictionary<String,Double>()
    }
    
    //M button
    @IBAction func recallMemory(_ sender: UIButton) {
        brain.setOperand(variable: "M")
        userIsInTheMiddleOfTyping = false
        calculate()
    }
    
    //→M button
    @IBAction func saveToMemory(_ sender: UIButton) {
        memoryVars = ["M" : displayValue]
        userIsInTheMiddleOfTyping = false
        calculate()
    }

    //MARK: Private methods
    private func calculate() {
        let calculatedValue = brain.evaluate(using: memoryVars)
        
        if let result = calculatedValue.result {
            displayValue = result
        }
       
        var displayDescription = calculatedValue.description
        if displayDescription != " " {
            displayDescription.append(calculatedValue.isPending ? "..." : " =")
        }
        descriptionDisplay.text = displayDescription
    }
    
    //Shows and hides buttons, changes title color attribute of button
    private func adjustButtonLayout(for view: UIView, isPortrait: Bool) {
        for subview in view.subviews {
            if subview.tag == 1 {
                subview.isHidden = isPortrait
            } else if subview.tag == 2 {
                subview.isHidden = !isPortrait
            }
            if let button = subview as? UIButton {
                button.setTitleColor(UIColor.white, for: .highlighted)
            } else if let stack = subview as? UIStackView {
                adjustButtonLayout(for: stack, isPortrait: isPortrait);
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adjustButtonLayout(for: view, isPortrait: traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        adjustButtonLayout(for: view, isPortrait: (newCollection.horizontalSizeClass == .compact && newCollection.verticalSizeClass == .regular))
    }
    

}

