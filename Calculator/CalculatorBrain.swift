//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Frascella Claudio on 6/27/17.
//  Copyright © 2017 TeamDecano. All rights reserved.
//

import Foundation

func factorial(_ x: Double) -> Double {
    if x <= 1.0 {
        return 1.0
    }
    return x * factorial(x - 1.0)
}

func nthroot(_ x: Double, n: Double) -> Double {
    return x < 0 && abs(n.truncatingRemainder(dividingBy: 2)) == 1 ? -pow(-x, 1/n) : pow(x, 1/n)
}

private func checker(_ x : Double) -> String? {
    if x.hasDecimal || x <= 1.0 {
        return "Invalid input"
    }
    return nil
}

struct CalculatorBrain {
    
    //MARK: Private properties
    private enum Operation { //embedded private enum
        case constant(Double) //associated value
        case unaryOperation(((Double) -> Double), ((String) -> String), ((Double) -> String?)) //type that takes a double and returns a double
        case binaryOperation(((Double,Double) -> Double), ((String,String) -> String), ((Double,Double) -> String?))
        case equals
    }
    

    
    //dictionary of constants anf formulae
    private var operations: Dictionary<String,Operation> = [
        "π"   : Operation.constant(Double.pi),
        "e"   : Operation.constant(M_E),
        "Rand": Operation.constant(Double(arc4random()) / Double(UINT32_MAX)),
        
        "%"    : Operation.unaryOperation( { $0 / 100 }, { "(\($0))%" }, { _ in nil } ),
        "√"    : Operation.unaryOperation(sqrt, { "√(\($0))" }, { ($0 < 0) ? "Illegal operation" : nil } ),
        "cos"  : Operation.unaryOperation(cos, { "cos(\($0))" }, { _ in nil } ),
        "sin"  : Operation.unaryOperation(sin, { "sin(\($0))" }, { _ in nil } ),
        "tan"  : Operation.unaryOperation(tan, { "tan(\($0))" }, { _ in nil } ),
        "cosh" : Operation.unaryOperation(cosh, { "cosh(\($0))" }, { _ in nil } ),
        "sinh" : Operation.unaryOperation(sinh, { "sinh(\($0))" }, { _ in nil } ),
        "tanh" : Operation.unaryOperation(tanh, { "tanh(\($0))" }, { _ in nil } ),
        "x⁻¹"  : Operation.unaryOperation( { 1 / $0 }, { "1/(\($0))" }, { ($0 <= 0) ? "Illegal operation" : nil } ),
         "x!"   : Operation.unaryOperation(factorial, { "(\($0))!" }, { ($0.hasDecimal || $0 <= 1.0) ? "Illegal operation" : nil } ),
        "±"    : Operation.unaryOperation( { -$0 }, { "-(\($0))" }, { _ in nil } ),
        "x²"   : Operation.unaryOperation({ pow($0, 2) }, { "(\($0))²" }, { _ in nil } ),
        "log₁₀": Operation.unaryOperation(log10, { "log₁₀(\($0))" }, { ($0 < 0) ? "Illegal operation" : nil } ),
        "log₂" : Operation.unaryOperation(log2, { "log₂(\($0))" }, { ($0 < 0) ? "Illegal operation" : nil } ),
        "ln"   : Operation.unaryOperation(log, { "ln(\($0))" }, { ($0 < 0) ? "Illegal operation" : nil } ),
        "eˣ"   : Operation.unaryOperation(exp, { "e^(\($0))" }, { _ in nil } ),
        "2ˣ"   : Operation.unaryOperation(exp2, { "2^(\($0))" }, { _ in nil } ),
        "10ˣ"  : Operation.unaryOperation(__exp10, {"10^(\($0))" }, { _ in nil } ),

        "×"   : Operation.binaryOperation( { $0 * $1 }, { "\($0) × \($1)" }, { _ in nil } ),
        "÷"   : Operation.binaryOperation( { $0 / $1 }, { "\($0) ÷ \($1)" }, { ($1 == 0) ? "Illegal operation" : nil } ),
        "+"   : Operation.binaryOperation( { $0 + $1 }, { "\($0) + \($1)" }, { _ in nil } ),
        "-"   : Operation.binaryOperation( { $0 - $1 }, { "\($0) - \($1)" }, { _ in nil } ),
        "xʸ"  : Operation.binaryOperation(pow, { "\($0)^\($1)" }, { _ in nil } ),
        "EE"  : Operation.binaryOperation( { $0 * __exp10($1) }, { "\($0)×10^\($1)" }, { _ in nil } ),
        "ʸ√x" : Operation.binaryOperation(nthroot, { "\($1)√(\($0))" }, { (op1, op2) in ((op1 < 0) ? "Illegal operation" : nil) } ),
        "="   : Operation.equals,
    ]
    
    
    private enum Input {
        case operation(String)
        case operand(Double)
        case variable(String)
    }
    
    private var equation = [Input]()
    
    
    //MARK: Public Methods
    mutating func undo() {
        if !equation.isEmpty {
            equation.removeLast()
        }
    }
    
    mutating func performOperation(_ symbol: String) {
        equation.append(.operation(symbol))
    }
    
    mutating func setOperand(_ operand: Double) {
        equation.append(.operand(operand))
    }
    
    mutating func setOperand(variable named: String) {
        equation.append(.variable(named))
    }
    
    
    func evaluate(using variables: Dictionary<String,Double>? = nil)
        -> (result: Double?, isPending: Bool, description: String) {
            
            // DECLARATIONS
            var accumulator: (result: Double, description: String)?
            var pendingBinaryOperation: PendingBinaryOperation? //optional, not set always
            var error: String? = nil
            
            func performPendingBinaryOperation() {
                if pendingBinaryOperation != nil && accumulator != nil {
                    
                    error = pendingBinaryOperation!.performErrorCheck(with: accumulator!)
                    if error == nil {
                        accumulator = pendingBinaryOperation!.perform(with: accumulator!)
                        pendingBinaryOperation = nil
                    }
                }
            }

            struct PendingBinaryOperation {
                let function: (Double,Double) -> Double
                let descriptionFunction: (String,String) -> String
                let firstOperand: (result: Double, description: String)
                let errorFunction: (Double,Double) -> String?
                
                func perform(with secondOperand: (Double, String)) -> (Double, String) {
                    return (function(firstOperand.0, secondOperand.0), descriptionFunction(firstOperand.1, secondOperand.1))
                }
                
                func performErrorCheck(with secondOperand: (Double, String)) -> String? {
                    return (errorFunction(firstOperand.0, secondOperand.0))
                }
            }
            
            // CALCULATIONS
            for item in equation {
            
                switch(item) {
                case .operand(let value):
                    accumulator = (value, value.displayFormatted)
                    
                case .operation(let symbol):
                
                    if let operation = operations[symbol] {
                        switch operation {
                        case .constant(let value):
                            accumulator = (value, symbol)
                            
                        case .unaryOperation(let function, let descriptionFunction, let errorFunction):
                            if accumulator != nil { //protects crashing
                                
                                error = errorFunction(accumulator!.result)
                                if error == nil {
                                    
                                    if symbol == "%" {
                                        performPendingBinaryOperation()
                                    }
                                    accumulator = (function(accumulator!.result), descriptionFunction(accumulator!.description))
                                }
                            }
                            
                        case .binaryOperation(let function, let descriptionFunction, let errorFunction):
                            
                            performPendingBinaryOperation()
                            if accumulator != nil {
                                pendingBinaryOperation = PendingBinaryOperation(function: function,descriptionFunction: descriptionFunction,
                                                                                firstOperand: accumulator!, errorFunction: errorFunction)
                                accumulator = nil
                            }
                            
                        case .equals:
                            performPendingBinaryOperation()
                        }
                    }
                    
                case .variable(let symbol):
                    if let value = variables?[symbol] {
                        accumulator = (value, symbol)
                    } else {
                        accumulator = (0, symbol)
                    }

                }
            
            }
            // RETURN values
            var result: Double? { // optional bc it's not always set
                get {
                    return accumulator?.result
                }
            }
            
            //returns true when there is a binary operation pending.
            var resultIsPending: Bool {
                get {
                    return (pendingBinaryOperation !=  nil)
                }
            }
            
            //returns a description of the sequence of operands and operations that led to the value returned by result (or the result so far if resultIsPending)
            var description: String? {
                get {
                    if resultIsPending {
                        let firstOp = pendingBinaryOperation!.firstOperand.description
                        let secondOp = accumulator?.description ?? ""
                        return pendingBinaryOperation!.descriptionFunction(firstOp, secondOp)
                    } else {
                        return error ?? accumulator?.description
                    }
                }
            }
            
            return (result, resultIsPending, description ?? " ")

    }
    
    //MARK: Public properties
    @available(*, deprecated, message: "Unusable")
    var result: Double? { // optional bc it's not always set
        get {
            return evaluate().result
        }
    }
    
    @available(*, deprecated, message: "Unusable")
    //returns true when there is a binary operation pending.
    var resultIsPending: Bool {
        get {
            return evaluate().isPending
        }
    }
    
    @available(*, deprecated, message: "Unusable")
    //returns a description of the sequence of operands and operations that led to the value returned by result (or the result so far if resultIsPending)
    var description: String? {
        get {
            return evaluate().description
        }
    }
}

extension Double {
    var displayFormatted: String {
        get {
            let numberFormatter = NumberFormatter()
            numberFormatter.minimumIntegerDigits = 1
            numberFormatter.maximumFractionDigits = 6
            return numberFormatter.string(for: self) ?? String(self)
        }
    }
    var hasDecimal: Bool {
        get {
            return self.truncatingRemainder(dividingBy: 1) != 0
        }
    }
}
