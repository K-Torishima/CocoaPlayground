//
//  ViewController.swift
//  CocoaPlayground
//
//  Created by 鳥嶋 晃次 on 2021/09/15.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    private var subscriptions = Set<AnyCancellable>()
    // private let buttonTap = PassthroughSubject<Void, Never>()
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var textView: UITextView!
    
    private let viewModel = ViewModel()
    private var data: [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.addTarget(self,
                         action: #selector(buttonTapAction),
                         for: .touchUpInside)
        
//        buttonTap
//            .sink { _ in
//                print("Button Tap")
//            }
//            .store(in: &subscriptions)
        
        viewModel.tapAction
            .sink { users in
                print(users)
                self.data.append(contentsOf: users)
            }
            .store(in: &subscriptions)
        
        
    }
    
    @objc private func buttonTapAction() {
        // buttonTap.send()
        viewModel.fetch()
        textView.text = "\(data)"
    }
}

final class ViewModel {
    let tapAction = PassthroughSubject<[User], Never>()
    
    private let model = Model()
    
    func fetch() {
        tapAction.send(model.users)
    }
}

final class Model {
    let users: [User] = [
        User(id: "1", name: "koji", age: "30"),
        User(id: "2", name: "kenta", age: "23"),
        User(id: "3", name: "tanaka", age: "32"),
    ]
}

struct User {
    var id: String
    var name: String
    var age: String
}
