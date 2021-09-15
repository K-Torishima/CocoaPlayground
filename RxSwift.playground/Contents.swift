import Foundation
import RxSwift

let prices = [100, 250, 560, 980]
let taxRate = 1.08

Observable
    .from(prices)
    .map { price in
        Int(Double(price) * taxRate)
    }
    .subscribe { event in
        print(event)
    }
    .dispose()

// 下は同じことをしているが、ちょっと違う

prices
    .map({
        Int(Double($0) * taxRate)
        
    })
    .forEach { value in
        // print(value)
    }

