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

print("// ------------------ //")
// データの変更を伝える

final class Account {
    private(set) var userId = ""
    private(set) var passwoed = ""
    private(set) var isValid = false
    
    func update(userId: String, password: String) {
        self.userId = userId
        self.passwoed = password
        isValid = userId.count >= 4 && password.count >= 4
    }
}
// Accountのupdateを呼ぶとそれに応じてisValidの値が決まる

final class ReceiverO {
    private let account = Account()
    
    func load() {
        account.update(userId: "hoge", password: "pass")
        print("ReceiverO isValid: \(account.isValid)")
    }
}

let receiverO = ReceiverO()
receiverO.load()

// updateメソッドを読んだ後で、Receiverクラスが自分でisValidプロパティを読むことになる
// Receiverクラスの実装を注意深く行わないと、isValidプロパティを読みにいく処理を忘れてしまいそう。

// 上記の方法ではなくAccountクラスからisValidプロパティが変わったことを通知してもらう方が間違いは起こりにくい
// Accountクラスに通知のためのpublisherを用意してReceiverクラスでsubscribeするという方法がある

print("// ------------------ //")
// ＠Published

final class AccountP {
    private(set) var userId = ""
    private(set) var passwoed = ""
    @Published private(set) var isValid = false
    
    func update(userId: String, password: String) {
        self.userId = userId
        self.passwoed = password
        isValid = userId.count >= 4 && password.count >= 4
    }
}

final class ReceiverP {
    private var subscriptions = Set<AnyCancellable>()
    private let account = AccountP()
    
    init() {
        account.$isValid
            .sink { isValid in
                print("ReceiverP isValid: \(isValid)")
            }
            .store(in: &subscriptions)
    }
    
    func load() {
        account.update(userId: "hoge", password: "pass")
    }
}

let receiverP = ReceiverP()
receiverP.load()

print("// ------------------ //")
// CurrentValueSubject

final class AccountQ {
    private(set) var userId = ""
    private(set) var password = ""
    private let isValidSubject: CurrentValueSubject<Bool, Never>
    let isValid: AnyPublisher<Bool, Never>
    
    init() {
        isValidSubject = CurrentValueSubject<Bool, Never>(false)
        isValid = isValidSubject.eraseToAnyPublisher()
    }
    
    func update(userId: String, password: String) {
        self.userId = userId
        self.password = password
        let isValid = userId.count >= 4 && password.count >= 4
        isValidSubject.send(isValid)
        // こっちでも良い
        // isValidSubject.value = isValid
    }
}

/*
 CurrentValueSubjectはprivateにしてAccountクラスの外側には公開しないようにしている
 sendメソッドやvalueプロパティをAccountクラスの外側から使えないようにする
 eraseToAnyPublisherメソッドによってSubjectではないPublisherに変換して公開している
 */

final class ReceiverQ {
    
    private var subscriptions = Set<AnyCancellable>()
    private let account = AccountQ()
    
    init() {
        account.isValid
            .sink { isValid in
                print("ReceiverQ  isValid:", isValid)
            }
            .store(in: &subscriptions)
    }
    
    func load() {
        account.update(userId: "hoge", password: "pass")
    }
}

let receiverQ = ReceiverQ()
receiverQ.load()


print("// ------------------ //")
// PassthroughSubject（上の方法とほぼ同じ）

final class AccountR {
    private(set) var userId: String = ""
    private(set) var password: String = ""
    private let isValidSubject: PassthroughSubject<Bool, Never>
    let isValid: AnyPublisher<Bool, Never>
    
    
    init() {
        isValidSubject = PassthroughSubject<Bool, Never>()
        isValid = isValidSubject.eraseToAnyPublisher()
    }

    func update(userId: String, password: String) {
        self.userId = userId
        self.password = password
        let isValid = userId.count >= 4 && password.count >= 4
        isValidSubject.send(isValid)
    }
}

final class ReceiverR {
    private var subscriptions = Set<AnyCancellable>()
    private let account = AccountR()
    
    init() {
        account.isValid
            .sink { isValid in
                print("ReceiverR isValid:", isValid)
            }
            .store(in: &subscriptions)
    }
    
    func load() {
        account.update(userId: "aa", password: "aaaaa")
    }
}

let receiverR = ReceiverR()
receiverR.load()

// どれを使うべきか

/*
 - @Published
 - CurrentValueSubject
 - PssthroughSubject
 
 結論、やりたいことができるならどれでも良い
 
 - PssthroughSubject
 値を保持しないという特徴がある、
 初期値を考慮する必要がなく、必要な時に必要なだけイベントを通知するということがやりやすい
 
 逆にイベント以外でも通常のプロパティのように値を参照したい場合は
 @PublishedやCurrentValueSubjectが向いている
 
 - @Published
 通常のプロパティとほとんど同じような感覚で使うことができる
 Codeがシンプルになるという点でCurrentValueSubjectより便利
 @Publishedはclassでしか使えない
 Subjectでは.finishdや.failueをsendできるが @Publishedではできない
 
 状況に応じて実装していくと良さそう
 
 */

print("// ------------------ //")
// Opelaterの活用

final class AccountS {
    private let userIdSubject: CurrentValueSubject<String, Never>
    private let passwordSubject: CurrentValueSubject<String, Never>
    var userId: String { userIdSubject.value }
    var password: String { passwordSubject.value }
    
    let isValid: AnyPublisher<Bool, Never>
    
    init() {
        userIdSubject = CurrentValueSubject<String, Never>("")
        passwordSubject = CurrentValueSubject<String, Never>("")
        isValid = userIdSubject
            .combineLatest(passwordSubject)
            .map { userId, password in
                userId.count >= 4 && password.count >= 4
            }
            .eraseToAnyPublisher()
    }
    
    func update(userId: String, password: String) {
        userIdSubject.value = userId
        passwordSubject.value = password
    }
}

final class ReceiverS {
    private var subscription = Set<AnyCancellable>()
    private let account = AccountS()
    
    init() {
        account.isValid
            .sink { isValid in
                print("ReceiverS isValid: ", isValid)
            }
            .store(in: &subscription)
    }
    
    func load() {
        account.update(userId: "hoge", password: "hugahuga")
        print(account.password)
        print(account.userId)
    }
}

let receiverS = ReceiverS()
receiverS.load()


print("// -------------- //")

final class AccountT {
    private(set) var userId = ""
    private(set) var password = ""
    @Published private(set) var isValid = false
    
    func update(userId: String, password: String) {
        self.userId = userId
        self.password = password
        isValid = userId.count >= 4 && password.count >= 4
    }
}

final class SomeObjectT {
    var value: Bool = false {
        didSet {
            print("isValid: \(value)")
        }
    }
}

final class ReceiverT {
    private var subscriptions = Set<AnyCancellable>()
    private let object = SomeObjectT()
    private let account = AccountT()
    
    init() {
        account.$isValid
            .assign(to: \.value, on: object)
            .store(in: &subscriptions)
    }
    
    func load() {
        account.update(userId: "hoge", password: "huga")
    }
}

let receiverT = ReceiverT()
receiverT.load()


// UIの更新

import PlaygroundSupport
import UIKit

// --------------------------- //

let view = UIView()
view.frame = CGRect(x: 0, y: 0, width: 320, height: 160)
view.backgroundColor = .white
PlaygroundPage.current.liveView = view

let label = UILabel()
label.frame = CGRect(x: 20, y: 20, width: 280, height: 20)
label.textColor = .black
label.text = "initial text"
view.addSubview(label)

final class ReceiverUI {
    private var subscriptions = Set<AnyCancellable>()
    private var account = AccountT()
    
    init() {
        account.$isValid
            // publishされる値を表示する値に変換する
            .map { "isValid: \($0)"}
            // 表示用の値を実際にUIに反映する
            .assign(to: \.text, on: label)
            .store(in: &subscriptions)
    }
    
    func load() {
        account.update(userId: "hoge", password: "pass")
    }
}

// let receiverUI = ReceiverUI()
// receiverUI.load()

// 上記には二つのことがあるので別クラスに分離する

final class ViewModelE {
    // publishされる値を表示する値に変換する
    
    //　表示用のテキストをPublishする
    let labelText: AnyPublisher<String?, Never>
    private let account = AccountT()
    
    init() {
        labelText = account.$isValid
            .map { "isValid: \($0)" }
            .eraseToAnyPublisher()
    }
    
    func load() {
        account.update(userId: "hoge", password: "pass")
    }
}

final class ViewController {
    // 表示用の値を実際にUIに反映する
    
    private var subscriptions = Set<AnyCancellable>()
    private let viewModel = ViewModelE()
    
    init() {
        // viewModel -> view
        viewModel.labelText
            .assign(to: \.text, on: label)
            .store(in: &subscriptions)
    }
    
    func load() {
        // view -> viewModel
        self.viewModel.load()
        
    }
}

let viewController = ViewController()
viewController.load()

//　全てのバインディングはassignでは書けない
// sinkが必要

// 例

struct Article {
    var id: String
    var title: String
    var content: String
}

final class ViewModelF {
    // datasource
    @Published private(set) var articles: [Article] = []
    
    func fetch() {
        //　仮データ(実際にはURLSessionなどでデータを取得する
        let fetchedArticles = (0 ..< 10).map {
            Article(id: "id \($0)",
                    title: "title \($0)",
                    content: "content \($0)")
        }
        
        // APIからデータを取得後　articlesに格納
        articles = fetchedArticles
    }
}

final class ViewControllerF {
    private var subscriptions = Set<AnyCancellable>()
    private let viewModel = ViewModelF()
    
    init() {
        viewModel.$articles
            .sink { values in
                // viewのdata配列に入れるでも良いし、tableViewとかにそのまま私でも良いと思う
                print(values)
            }
            .store(in: &subscriptions)
    }
    
    func fetch() {
        viewModel.fetch()
    }
}

let viewControllerF = ViewControllerF()
viewControllerF.fetch()

// UIKitでの活用
// UIKitにはCombine向けのインターフェースがない
// UIControllにはPublisherがない

// 標準で提供されているもの
// Notification
// 以下はkeyboardの通知
final class ViewControllerG: UIViewController {
    private var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardDidShowNotification)
            .sink { notification in
                print(notification)
            }
            .store(in: &subscriptions)
    }
}

// PassthroughSubjectの活用
// イベント発生はtarget_Action方式
// Action発生時イベントをpublishしてくれるPublisherがいればそれをsubscribeすることでActionを処理できる

// Actionハンドラが呼ばれたとき、PassthroughSubjectのsendを使ってイベントを中継するという方法がある
// 以下はサンプルであるためplaygroundでは動かない

final class SimpleButtonViewController: UIViewController {
    private var subscriptions = Set<AnyCancellable>()
    private let buttonTap = PassthroughSubject<Void, Never>()
    
    @IBOutlet private var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.addTarget(self, action: #selector(buttonTapAction), for: .touchUpInside)
        buttonTap
            .sink { _ in
                print("Button Tap")
            }
            .store(in: &subscriptions)
    }
    
    @objc func buttonTapAction() {
        buttonTap.send()
    }
}


