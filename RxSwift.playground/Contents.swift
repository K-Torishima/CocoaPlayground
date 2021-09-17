import Foundation
import RxSwift

// モチベーション
// 復習を兼ねて勉強する

let prices = [100, 250, 560, 980]
let taxRate = 1.08

Observable
    .from(prices)
    .map { price in
        Int(Double(price) * taxRate)
    }
    // ここのevent は　Event型
    .subscribe { event in
        // print(event)
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


// 概要はここに書いてある
// https://www.2nd-walker.com/2020/01/30/beginning-of-rxswift-2/#Playground_zuo_cheng

// ここでは注意点とかをメモする
// （fromやmapなどのメソッドのことを、ReactiveXでは“Operator”と呼んでいます）
// subscribeすることで処理が渡させる
// subscribeを書かないと動かない
// Eventは以下のCodeになっている


//public enum Event<Element> {
//    /// Next element is produced.
//    case next(Element)
//
//    /// Sequence terminated with an error.
//    case error(Swift.Error)
//
//    /// Sequence completed successfully.
//    case completed
//}

// Observableから1つの要素が発行され、Observerに渡される時のイベントが `next`
// すべての要素を渡し終えて処理が完了した時のイベントが `completed`
// そして途中で何かしらのエラーが発生した場合のイベントが `error`

// クロージャーはEventごとに分けれる
/*
    .subscribe(onNext: { element in
        print(element)
    }, onError: { error in
        print(error)
    }, onCompleted: {
        print("completed")
    }, onDisposed: {
        print("disposed")
    })

*/

// dispose はリソース解放のためのメソッド
// removeとかと同じような感じ。URLセッションならTask kill のところ

//　別パターンに関して
func test() {
    
    let disposeBug = DisposeBag()
    
    let subject = PublishSubject<String>()
    // 他のサブジェクト
    // BehaviorSubject
    //let subject = BehaviorSubject<String>(value: "☕")

    // ReplaySubject
    // let subject = ReplaySubject<String>.create(bufferSize: 2)

    // AsyncSubject
    // let subject = AsyncSubject<String>()
    
    subject.onNext("apple")
    
    subject
        .subscribe(onNext: { elsement in
            // print("Event1 -> \(elsement)")
        }, onCompleted: {
            // print("Event1 -> completed")
        }, onDisposed: {
            // print("Event1 -> disposed")
        })
        .disposed(by: disposeBug)
    
    subject.onNext("susi")
    
    subject
        .map({ element in
            "\(element) is nice!"
        })
        .subscribe(onNext: { element in
            // print("Event2 -> \(element)")
        }, onCompleted: {
            // print("Event2 -> completed")
        }, onDisposed: {
            // print("Event2 -> disposed")
        })
        .disposed(by: disposeBug)
    subject.onNext("バーガー")
    
    subject
        .subscribe(onNext: { element in
           // print("Event3 -> \(element)")
            
        }, onCompleted: {
           // print("Event3 -> completed")
        }, onDisposed: {
           // print("Event3 -> disposed")
        })
        .disposed(by: disposeBug)
    
    subject.onNext("ラーメン")
    subject.onCompleted()
    
    
}

test()

// PublishSubjectとは
/*
 複数あるSubjectの一つ
 PublishSubject -> 発行対象
 onNextメソッドを使うことで、購読しているObserverたちに要素を発行することができます。
 
 */


// -------------- //
// Operatorとは

// Create
// 要素の発行を自前で行うマニュアルなObservableを作成するためのOperatorです


func createSample() {
    let disposeBag = DisposeBag()
    // マニュアルなOvservableの作成
    
    let observable = Observable<String>
        .create({ observable in
            observable.onNext("ビール")
            observable.onNext("酒")
            observable.onNext("ワイン")
            observable.onCompleted()
            
            return Disposables.create {
                print("Observable: Dispose")
            }
        })
    
    observable
        .subscribe(onNext: { element in
            print("Observer: \(element)")
            
        }, onDisposed: {
            print("Observer: onDisposed")
        })
        .disposed(by: disposeBag)
}

createSample()



