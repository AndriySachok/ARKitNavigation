//
//  LoadViewController.swift
//  ARNavigation
//
//  Created by Андрій on 20.10.2024.
//
import UIKit
import UniformTypeIdentifiers
import Combine
import RealityKit

class LoadViewController: UIViewController, UIDocumentPickerDelegate {
    let interactor: Interactor
    var textField: UITextField!
    var arView: ARView!
    var selectedMapURL: URL? {
        didSet {
            setupSearchStack()
            interactor.selectedMapURL = selectedMapURL
        }
    }
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        openDocumentPicker()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        interactor.killARView()
    }
    
    func setupSearchStack() {
        textField = UITextField()
        textField.placeholder = "Enter room to search"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        let button1 = createButton(withTitle: "Confirm")
        
        let searchStackView = UIStackView(arrangedSubviews: [textField, button1])
        searchStackView.axis = .horizontal
        searchStackView.distribution = .fillProportionally
        searchStackView.alignment = .fill
        searchStackView.spacing = 10
        searchStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchStackView)
        
        NSLayoutConstraint.activate([
            searchStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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
    
    func setupARView() {
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)
        
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        guard let room = Int(textField.text ?? "") else {
            print("Wrong room number!!")
            return
        }
        setupARView()
        interactor.roomToFind = room
    }
    
    func openDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        print("Selected file URL: \(url)")
        arView = interactor.setARView()
        selectedMapURL = url
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was canceled.")
    }
}

extension LoadViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
    }
}
