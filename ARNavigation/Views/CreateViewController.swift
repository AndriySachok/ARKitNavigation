//
//  ViewController.swift
//  ARNavigation
//
//  Created by Андрій on 19.10.2024.
//

import UIKit
import Combine

class CreateViewController: UIViewController {
    let interactor: Interactor
    let documentPickerDelegate = DocumentPickerDelegate()
    
    var stackView: UIStackView!
    var textField: UITextField!
    var cancellableForShareSheet: AnyCancellable?
    
    init(interactor: Interactor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dismissKeyboard()
        cancellableForShareSheet = interactor.updatePublisher
            .sink { [weak self] in
                self?.presentShareSheet()
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupARView()
        setupButtonStackView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        interactor.killARView()
    }
    
    func setupTextField() {
        textField = UITextField()
        textField.placeholder = "Enter room number"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupARView() {
        let arView = interactor.setARView()
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)
        
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func setupButtonStackView() {
        let button1 = createButton(withTitle: "Path1")
        let button2 = createButton(withTitle: "Path2")
        let button3 = createButton(withTitle: "Path3")
        let button4 = createButton(withTitle: "Dist")
        let button5 = createButton(withTitle: "Room")
        let button6 = createButton(withTitle: "Save")
        
        let buttonStackView = UIStackView(arrangedSubviews: [button1, button2, button3, button4, button5, button6])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillProportionally
        buttonStackView.alignment = .fill
        buttonStackView.spacing = 10
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        setupTextField()
        
        let attributeStackView = UIStackView(arrangedSubviews: [textField])
        attributeStackView.axis = .horizontal
        attributeStackView.distribution = .fillProportionally
        attributeStackView.alignment = .fill
        attributeStackView.spacing = 8
        attributeStackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView = UIStackView(arrangedSubviews: [buttonStackView, attributeStackView])
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 8),
            buttonStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -8),
            attributeStackView.heightAnchor.constraint(equalToConstant: 40),
            attributeStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 8),
            attributeStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -8),
        ])
    }
    
    func createButton(withTitle title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    func presentShareSheet() {
        let items: [Any] = [interactor.savedMapUrl!]
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact]
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        switch sender.currentTitle {
        case "Path1":
            interactor.creationAction = .setPath1
        case "Path2":
            interactor.creationAction = .setPath2
        case "Path3":
            interactor.creationAction = .setPath3
        case "Dist":
            interactor.creationAction = .findNeighbors
        case "Room":
            interactor.roomNumber = textField.text ?? ""
            interactor.creationAction = .addRoom
        case "Save":
            interactor.creationAction = .saveMap
        default:
            break
        }
    }
    
}

extension CreateViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
    }
}

extension UIViewController {
    func dismissKeyboard() {
       let tap: UITapGestureRecognizer = UITapGestureRecognizer( target: self, action:    #selector(UIViewController.dismissKeyboardTouchOutside))
       tap.cancelsTouchesInView = false
       view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboardTouchOutside() {
       view.endEditing(true)
    }
}

