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
                // print("Received response", response)
            })
            .store(in: &subscrioptions)
    }
}

// let receiverF = ReceiverF()

print("// ------------------ // ")

// Subject

let subjectG = CurrentValueSubject<String, Never>("A")

final class ReceiverG {
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        subjectG
            .sink { value in
                print("Received value:", value)
            }
            .store(in: &subscriptions)
    }
}

let receiverG = ReceiverG()
subjectG.send("a")
subjectG.send("b")
subjectG.send("c")
subjectG.send("d")
subjectG.send("e")
print("Current value:", subjectG.value)

// PassthroughSubjectとCurrentValueSubjectの二つをSubjectと呼ぶ
// sendを呼ぶとpublishする
// send は　SubjectProtocolのmethod

// CurrentValueSubjectは現在の値を持っている
// Currentはsubscribeするとすぐに現在値がpublishされる

print("// ------------------ // ")

// Subjectの型消去

// Subjectはsendを使える。しかしどこからでもsendができてしまうのは、場合によっては好ましくない
//　イベントを送信するオブジェクトとイベントを受信するオブジェクトは、設計上分離することが多いため

let subjectH = PassthroughSubject<String, Never>()
//　subjectがPublisherになる
let publisherH = subjectH.eraseToAnyPublisher()

final class ReceiverH {
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        publisherH
            .sink { value in
                print("Received value:", value)
            }
            .store(in: &subscriptions)
    }
}

let receiverH = ReceiverH()
subjectH.send("A")
subjectH.send("B")
subjectH.send("C")
subjectH.send("D")
subjectH.send("E")

print("// ------------------ // ")

// @Published

final class Sender {
    //プロパティラッパーをつけるだけでPublisherになる
    @Published var event: String = "A"
    // private をつければ外部変更できないようにできる（普通のプロパティと同じ)
    // @Published private(set) var event: String = "A"
}

let sender = Sender()

final class ReceiverI {
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        sender.$event
            .sink { value in
                print("Received value:", value)
            }
            .store(in: &subscriptions)
    }
}

let receiverI = ReceiverI()
sender.event = "あ"
sender.event = "い"
sender.event = "う"
sender.event = "え"
sender.event = "お"

print("// ------------------ // ")
// Operator

final class Model {
    @Published var value: String = "0"
}

let model = Model()

final class ViewModel {
    var text: String = "" {
        didSet {
            print("didSet text:", text)
        }
    }
}

final class ReceiverJ {
    
    var subscriptions = Set<AnyCancellable>()
    let viewModel = ViewModel()
    
    init() {
        model.$value
            .assign(to: \.text, on: viewModel)
            .store(in: &subscriptions)
    }
}

let receiverJ = ReceiverJ()
model.value = "1"
model.value = "2"
model.value = "3"
model.value = "4"
model.value = "5"


// Modelのvalueが変更されると,viewModelのTextに反映される
// あるオブジェクトの変更を別のオブジェクトに結びつけることを慣用的にバインディングと呼ぶ
// Combineを使うとバインディングの処理を簡潔にかける

print("// ------------------ // ")

// Map
// バインドしたいプロパティの方が常に一致しているとは限らない

// ModelのvalueがIntだった場合

final class ModelA {
    @Published var value: Int = 0
}

let modelA = ModelA()

final class ViewModelA {
    var text: String = "" {
        didSet {
            print("didSet text:", text)
        }
    }
}

final class ReceiverK {
    var subscriptions = Set<AnyCancellable>()
    let viewModelA = ViewModelA()
    let formatter = NumberFormatter()
    
    init() {
        formatter.numberStyle = .spellOut
        
        modelA.$value
            // Int　→ String(spellOut)にformat
            .map { value in
                self.formatter.string(
                    from: NSNumber(integerLiteral: value)) ?? ""
            }
            // assignには変更後の値が渡させる
            .assign(to: \.text, on: viewModelA)
            .store(in: &subscriptions)
    }
}

let receiverK = ReceiverK()
modelA.value = 1
modelA.value = 2
modelA.value = 3
modelA.value = 11

// mapはPublisherのMap
/*
 - func map<T>(_ transform: @escaping (Self.Output) -> T) -> Publishers.Map<Self, T>
 - Publisher プロトコルに適合する Publishers.Map という型になっている
 - map メソッドの戻り値は Publisher なので subscribe できる。
 - assign を使って subscribe されている
 
 */

print("// ------------------ // ")

// filter

final class ModelB {
    @Published var value: Int = 0
}

let modelB = ModelB()

final class ViewModelB {
    var text: String = "" {
        didSet {
            print("didSet text:", text)
        }
    }
}

final class ReceiverL {
    var subscriptions = Set<AnyCancellable>()
    let viewModelB = ViewModelB()
    let formatter = NumberFormatter()
    
    init() {
        
        formatter.numberStyle = .spellOut
        
        // 偶数のみをpublishするように変換する
        modelB.$value
            .filter { $0 % 2 == 0 }
            .map { self.formatter.string(from: NSNumber(integerLiteral: $0)) ?? "" }
            .assign(to: \.text, on: viewModelB)
            .store(in: &subscriptions)
    }
}

let receiverL = ReceiverL()
modelB.value = 1
modelB.value = 2
modelB.value = 3
modelB.value = 4
modelB.value = 5

print("// ------------------ // ")

// compactMap
// nilの場合publishしない

final class ModelC {
    @Published var value: Int = 0
}

let modelC = ModelC()

final class ViewModelC {
    var text: String = "" {
        didSet {
            print("didSet text:", text)
        }
    }
}

final class ReceiverM {
    var subscriptions = Set<AnyCancellable>()
    let viewModelC = ViewModelC()
    let formatter = NumberFormatter()
    
    init() {
        formatter.numberStyle = .spellOut
        
        modelC.$value
            .compactMap { self.formatter.string(from: NSNumber(integerLiteral: $0)) }
            .assign(to: \.text, on: viewModelC)
            .store(in: &subscriptions)
    }
}

let receiverM = ReceiverM()
modelC.value = 1
modelC.value = 2
modelC.value = 3
modelC.value = 4
modelC.value = 5

// nilをpublishするだけでなく、返還後はOptionalのString?ではなくStringになる
// これがcompactMapを使うメリット

print("// ------------------ // ")

// combineLatest
// 二つのPublisherからひとつのPulisherを作るOpertor

final class ModelD {
    let subjectX = PassthroughSubject<String, Never>()
    let subjectY = PassthroughSubject<String, Never>()
}

let modelD = ModelD()

final class ViewModelD {
    var text: String = "" {
        didSet {
            print("didSet text:", text)
        }
    }
}

final class ReceiverN {
    var subscriptions = Set<AnyCancellable>()
    let viewModelD = ViewModelD()
    
    init() {
        modelD.subjectX
            .combineLatest(modelD.subjectY)
            .map { "X:" + $0.0 + " Y:" + $0.1 }
            .assign(to: \.text, on: viewModelD)
            .store(in: &subscriptions)
    }
}
let receiverN = ReceiverN()
modelD.subjectX.send("1")
modelD.subjectX.send("2")
modelD.subjectY.send("3")
modelD.subjectY.send("4")
modelD.subjectX.send("5")

/*
 combineLatestは、
 二つのPublisherのうちどちらかがpublishした場合に
 両方の最新の値をタプルでくみにしてpublishする、というもの
 
 片方がまだ一つもpublishしてない場合publishしない
 二つのプロパティが両方セットされた場合に何かしらの処理を行いたい場合使う

 Operatorはまだまだある
 
 そのほか
 prepend
 append
 merge
 switchToLatest
 */

// Combineを導入する上で一番大事なこと
// UI（View)とModelとのBinding
// UIKit + Combineでも十分活用可能


