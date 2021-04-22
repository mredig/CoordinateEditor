//
//  ViewController.swift
//  Demo
//
//  Created by Michael Redig on 4/21/21.
//

import UIKit
import CoordinateEditor
import CoreLocation

@testable import CoordinateEditor

class ViewController: UIViewController {

	let coordEditor = CoordinateEditor()

	override func loadView() {
		self.view = coordEditor
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		let textField = UITextField()
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.borderStyle = .roundedRect

		view.addSubview(textField)

		NSLayoutConstraint.activate([
			view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
			view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
			view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: textField.topAnchor),
		])

		textField.addTarget(self, action: #selector(onSearchBoxReturn), for: .editingDidEnd)
		textField.delegate = self

		let coord = CLLocationCoordinate2D(latitude: 43.986561, longitude: -92.459473)
		coordEditor.setStarter(to: coord)
	}

	@objc private func onSearchBoxReturn(_ sender: UITextField) {
		guard
			let search = sender.text,
			search.isEmpty == false
		else { return }

		coordEditor.performNaturalLanguageSearch(for: search) { [weak self] result, editorView in
			do {
				let response = try result.get()
				guard let firstResult = response.mapItems.first?.placemark else { return }

				editorView.selectedLocationAnnotation = CoordinateEditor.EditorAnnotation(firstResult, mode: .selectedCoordinate)
				editorView.setRegion(response.boundingRegion)
			} catch {
				print("error searching: \(error)")
			}
		}
	}
	
}

extension ViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()

		return true
	}
}

