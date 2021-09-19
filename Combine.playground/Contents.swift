import Foundation
import Combine

enum MyError: Error {
    case failed
}

let subject = PassthroughSubject<String, MyError>()

// Referencing instance method 'sink(receiveValue:)'
// on 'Publisher' requires the types 'MyError' and 'Never' be equivalent
// subject.sink { value in
//     print("Received value:", value)
// }

subject.sink(receiveCompletion: { completion in
    print("Received completion:", completion)
}, receiveValue: { value in
    print("Received value:", value)
})


subject.send("あ")
subject.send("い")
subject.send("う")
// subject.send(completion: .finished)
subject.send("え")
subject.send("お")
// subject.send(completion: .finished)

subject.send(completion: .failure(.failed))


// Combineが扱うイベントは3つある
// - 値
// - イベント完了(.finished)
// - エラー終了(.failure)

// 値の型は、送受信に使うクラスによって指定される、


print("// -------------------- //")

// -------------------- //
// Subscribe、Subscription

let subject1 = PassthroughSubject<String, Never>()

// 受信側をReceiverクラスとして分ける

final class Receiver {
    let subscription1: AnyCancellable
    let subscription2: AnyCancellable
    
    // ひとつのsubjectに対して、複数のsubscribeを行うことができる
    
    // sinkには、戻り値があるので、保持しなければならない
    // extension Publisher where Self.Failure == Never {
    // public func sink(receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable
    init() {
        subscription1 = subject1
            .sink { value in
                print("value:", value)
            }
        
        subscription2 = subject1
            .sink { value in
                print("value:", value)
            }
    }
}

//let receiver = Receiver()
//subject1.send("A")
//subject1.send("B")
//subject1.send("C")
//subject1.send("D")
//subject1.send("E")

// 片方がキャンセルさせてももう片方は動く

// store
// 複数のsubscriptionを扱う場合、それをまとめて保持したい場合こいつを使う

let subjectA = PassthroughSubject<String, Never>()

// storeはCancellableのメソッド
final class ReceiverA {
    
    // ここに入れれば、複数のsubscriptionを保持できる
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        subjectA
            .sink { value in
                print("[1] value: ", value)
            }
            .store(in: &subscriptions)
        subjectA
            .sink { value in
                print("[2] value: ", value)
            }
            .store(in: &subscriptions)
    }
}

/*
 extension AnyCancellable {

     /// Stores this type-erasing cancellable instance in the specified collection.
     ///
     /// - Parameter collection: The collection in which to store this ``AnyCancellable``.
     @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
     final public func store<C>(in collection: inout C) where C : RangeReplaceableCollection, C.Element == AnyCancellable

     /// Stores this type-erasing cancellable instance in the specified set.
     ///
     /// - Parameter set: The set in which to store this ``AnyCancellable``.
     final public func store(in set: inout Set<AnyCancellable>)
 }

 */

 let receiverA = ReceiverA()
subjectA.send("A")
subjectA.send("B")
subjectA.send("C")
subjectA.send("D")
subjectA.send("E")


// assign
// sinkと同様にsubscribeする処理
// クロージャを指定する代わりにオブジェクトを指定している

let subjectB = PassthroughSubject<String, Never>()

// Model
final class SomeObject {
    var value: String = "" {
        didSet {
            print("didSet value: ", value)
        }
    }
}

// ViewModel
final class ReceiverB {
    var subscriptions = Set<AnyCancellable>()
    let object = SomeObject()
    
    init() {
        subjectB
            //　SomeObjectのvalueを見ている
            .assign(to:  \.value, on: object)
            .store(in: &subscriptions)
    }
}

// Controller
let receiverB = ReceiverB()
// didSetが呼ばれる
// ViewDid
subjectB.send("た")
subjectB.send("ち")
subjectB.send("つ")
subjectB.send("て")
subjectB.send("と")


/*
 - assignはtoの引数はReferenceWritableKeyPathなので、書き込みが可能でなければならない
 - Errorが発生しないイベント（Never）でないと、assignは利用できない
 
 - クロージャーを書かずに直接オブジェクトのプロパティを反映できるため、Codeが簡潔になる
 */


print("// ------------------- //")
// ------------------- //

// * Publisher

// イベントを送信するものをpublisher
// publisherがイベントを送信することをpublishと呼ぶ
// publisherをsubscribeすることでイベントを受信できる
// passthroughSubjectはpublisherの一つである

print("// ------------------ // ")
//　Sequence
// 配列に.publisherをつけるだけでアクセスできる
// let publisher = ["あ", "い", "う", "え", "お"].publisher
let publisher = (1 ... 20).publisher

final class ReceiverC {
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        publisher
            .map { $0 + 1 }
            .sink { completion in
                print("Received completion: ", completion)
            } receiveValue: { value in
                print("value", value)
            }
            .store(in: &subscriptions)
        
        publisher
            .filter { $0 % 3 == 0 }
            .sink { completion in
                print(completion)
            } receiveValue: { value in
                print("3の倍数をフィルターしてます: ", value)
            }
            .store(in: &subscriptions)
    }
}

let receiverC = ReceiverC()

print("// ------------------ // ")

// Timer
// 1秒ごとに現在時刻をpublishしている
let publisherD = Timer.publish(every: 1, on: .main, in: .common)

final class ReceiverD {

    var subscriptions = Set<AnyCancellable>()
    
    init() {
        publisherD
            //　autoconnectをつけるとconnectする必要はない
            // 自動的に現在時刻が表示される。
            // .autoconnect()
            .sink { value in
                print("Received value:", value)
            }
            .store(in: &subscriptions)
    }
}

let receiver = ReceiverD()
//connectしないとイベントは発行されない
// 以下をコメントアウトするとTimerは動かない
// publisherD.connect()

// 何に使うかは微妙。

print("// ------------------ // ")

// Notification
// Notification CenterでもPublisherは存在する

let myNotification = Notification.Name("MyNotification")

let notificationPublisher = NotificationCenter.default.publisher(for: myNotification)

final class ReceiverE {

    var subscriptions = Set<AnyCancellable>()
    
    init() {
        notificationPublisher
            .sink { value in
                print("Notification Received value:", value)
            }
            .store(in: &subscriptions)
    }
}

let receiverE = ReceiverE()
NotificationCenter.default.post(Notification(name: myNotification))

// NotificationのPublisherは指定した通知がpostされたとき、その通知をPublishする
// 自前の通知を指定してやれば良い
// OSが発行する通知も指定できる

// URLSession
// Errorをpublishするため注意が必要
// 通信が成功すれば、その結果をpublishする
// data、responseのタプルになっている

let url = URL(string: "https://example.com")!
let sessionPublisher = URLSession.shared.dataTaskPublisher(for: url)

final class ReceiverF {
    var subscrioptions = Set<AnyCancellable>()
    
    init() {
        sessionPublisher
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Received error:", error)
                } else {
                    print("Received completion:", completion)
                }
            }, receiveValue: { data, response in
                print("Received data", data)
                print("Received response", response)
            })
            .store(in: &subscrioptions)
    }
}

let receiverF = ReceiverF()

print("// ------------------ // ")
// Subject
