import MapKit

public class CoordinateEditor: UIView {
	public var startCoordinates: CLLocationCoordinate2D? {
		didSet { updateAnnotations() }
	}
	public var selectedCoordinates: CLLocationCoordinate2D? {
		didSet { updateAnnotations() }
	}

	public var region: MKCoordinateRegion {
		get { mapView.region }
		set { mapView.region = newValue }
	}

	private let mapView = MKMapView()

	public enum CoordinateSelectionMode {
		case startCoordinate
		case selectedCoordinate
	}

	public typealias AnnotationGenerator = (CoordinateSelectionMode, CLLocationCoordinate2D) -> MKAnnotation
	public var annotationGenerator: AnnotationGenerator


	public init(annotationGenerator: AnnotationGenerator? = nil) {
		self.annotationGenerator = annotationGenerator ?? { mode, coordinates in
			let title: String
			switch mode {
			case .selectedCoordinate:
				title = "Selected Location"
			case .startCoordinate:
				title = "Original Location"
			}
			return EasyAnnotation(title: title, coordinate: coordinates)
		}
		super.init(frame: .zero)
		commonInit()
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func commonInit() {
		addSubview(mapView)

		constrain(subview: mapView)

		let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressMap))
		mapView.addGestureRecognizer(longPressGesture)
	}

	private func updateAnnotations() {
		mapView.removeAnnotations(mapView.annotations)

		if let startCoordinates = startCoordinates {
			let start = annotationGenerator(.startCoordinate, startCoordinates)

			mapView.addAnnotation(start)
		}

		if let selectedCoordinates = selectedCoordinates {
			let selected = annotationGenerator(.selectedCoordinate, selectedCoordinates)

			mapView.addAnnotation(selected)
		}

		let regionCenter = selectedCoordinates ?? startCoordinates ?? CLLocationCoordinate2D(latitude: 40.768866, longitude: -111.904324)

		let span = selectedCoordinates == nil ? MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 30) : mapView.region.span
		let region = MKCoordinateRegion(center: regionCenter, span: span)
		mapView.setRegion(region, animated: true)
	}

	@objc private func longPressMap(_ sender: UILongPressGestureRecognizer) {
		guard sender.state == .began else { return }
		let deviceLocation = sender.location(in: mapView)

		let coordinate = mapView.convert(deviceLocation, toCoordinateFrom: mapView)

		selectedCoordinates = coordinate
	}

	public typealias SearchResultCompletion = (Result<MKLocalSearch.Response, Error>) -> Void
	public func performNaturalLanguageSearch(for query: String, completion: @escaping SearchResultCompletion) {

		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = query
		let search = MKLocalSearch(request: request)
		search.start { response, error in
			let result: Result<MKLocalSearch.Response, Error>
			defer {
				DispatchQueue.main.async {
					completion(result)
				}
			}

			if let error = error {
				result = .failure(error)
				return
			}

			guard let response = response else {
				result = .failure(CoordinateEditorError.noResponse)
				return
			}

			result = .success(response)
		}
	}

	public func setRegion(_ region: MKCoordinateRegion, animated: Bool = true) {
		mapView.setRegion(region, animated: animated)
	}

	enum CoordinateEditorError: Error {
		case noResponse
	}
}

#if DEBUG
import SwiftUI

struct MapPreviews: PreviewProvider {

	struct CoordinateEditorPreview: UIViewRepresentable {
		@State var startCoord: CLLocationCoordinate2D?
		@State var selectedCoord: CLLocationCoordinate2D?

		let searchQuery: String?

		func makeUIView(context: Context) -> CoordinateEditor {
			let view = CoordinateEditor()

			return view
		}

		func updateUIView(_ uiView: CoordinateEditor, context: Context) {
			uiView.startCoordinates = startCoord
			uiView.selectedCoordinates = selectedCoord

			if let query = searchQuery {
				uiView.performNaturalLanguageSearch(for: query) { [weak uiView] result in
					do {
						let response = try result.get()
						uiView?.selectedCoordinates = response.mapItems.first?.placemark.coordinate
						uiView?.setRegion(response.boundingRegion)
					} catch {
						print("Error searching map: \(error)")
					}
				}
			}
		}
	}

	struct PreviewWrapper: View {
		@State var searchQuery = ""

		var body: some View {
			VStack {
				TextField("Search", text: $searchQuery)

				CoordinateEditorPreview(
					startCoord: nil,
					selectedCoord: nil,
					searchQuery: searchQuery.isEmpty ? nil : searchQuery)
			}
		}
	}

	static var previews: some View {
		PreviewWrapper()
	}

}
#endif
