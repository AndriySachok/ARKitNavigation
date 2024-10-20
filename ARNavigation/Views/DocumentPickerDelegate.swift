//
//  DocumentPickerDelegate.swift
//  ARNavigation
//
//  Created by Андрій on 20.10.2024.
//

import UIKit

class DocumentPickerDelegate: UIViewController, UIDocumentPickerDelegate {
    
    func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let selectedFileURL = urls.first else { return }
        print("Selected file URL: \(selectedFileURL)")
        
        let _ = selectedFileURL.startAccessingSecurityScopedResource()
        
        
        selectedFileURL.stopAccessingSecurityScopedResource()
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
}
