import MapKit

public class CoordinateEditor: UIView {
	private var _startLocationAnnotation: EditorAnnotation?
	public var startLocationAnnotation: EditorAnnotation? {
		get { _startLocationAnnotation }
		set {
			newValue?.mode = .startCoordinate
			_startLocationAnnotation = newValue
			updateAnnotations()
		}
	}
	private var _selectedLocationAnnotation: EditorAnnotation?
	public var selectedLocationAnnotation: EditorAnnotation? {
		get { _selectedLocationAnnotation }
		set {
			newValue?.mode = .selectedCoordinate
			_selectedLocationAnnotation = newValue
			updateAnnotations()
		}
	}

	public var region: MKCoordinateRegion {
		get { mapView.region }
		set { mapView.region = newValue }
	}

	private let mapView = MKMapView()
	private let mapDelegate = TheDelegate()

	public enum CoordinateSelectionMode {
		case startCoordinate
		case selectedCoordinate
	}

	public var annotationViewProvider: AnnotationProvider {
		get { mapDelegate.provider }
		set { mapDelegate.provider = newValue }
	}

	public override init(frame: CGRect = .zero) {
		super.init(frame: frame)
		commonInit()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}

	private func commonInit() {
		addSubview(mapView)

		constrain(subview: mapView)

		let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressMap))
		mapView.addGestureRecognizer(longPressGesture)

		register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.reuseIdentifier)
		mapView.delegate = mapDelegate
	}

	private func updateAnnotations() {
		mapView.removeAnnotations(mapView.annotations)

		if let startCoordinates = startLocationAnnotation {
			mapView.addAnnotation(startCoordinates)
		}

		if let selectedCoordinates = selectedLocationAnnotation {
			mapView.addAnnotation(selectedCoordinates)
		}

		let regionCenter = selectedLocationAnnotation?.coordinate ??
			startLocationAnnotation?.coordinate ??
			CLLocationCoordinate2D(latitude: 40.768866, longitude: -111.904324)

		let span = selectedLocationAnnotation == nil ? MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 30) : mapView.region.span
		let region = MKCoordinateRegion(center: regionCenter, span: span)
		mapView.setRegion(region, animated: true)
	}

	@objc private func longPressMap(_ sender: UILongPressGestureRecognizer) {
		guard sender.state == .began else { return }
		let deviceLocation = sender.location(in: mapView)

		let coordinate = mapView.convert(deviceLocation, toCoordinateFrom: mapView)

		EditorAnnotation.fetchName(for: coordinate, mode: .selectedCoordinate) { [weak self] result in
			do {
				let annotation = try result.get()
				self?.selectedLocationAnnotation = annotation
			} catch {
				print("Error fetching name for coordinate \(coordinate): \(error)")
			}
		}
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

	public func setStarter(to coordinate: CLLocationCoordinate2D) {
		EditorAnnotation.fetchName(for: coordinate, mode: .startCoordinate) { [weak self] result in
			self?.startLocationAnnotation = try? result.get()
		}
	}

	public func register(_ viewClass: AnyClass, forAnnotationViewWithReuseIdentifier identifier: String) {
		mapView.register(viewClass, forAnnotationViewWithReuseIdentifier: identifier)
	}

	enum CoordinateEditorError: Error {
		case noResponse
	}
}

extension CoordinateEditor {
	public typealias AnnotationProvider = (MKMapView, EditorAnnotation) -> MKAnnotationView?
	class TheDelegate: NSObject, MKMapViewDelegate {

		var provider: AnnotationProvider

		init(provider: AnnotationProvider? = nil) {
			self.provider = provider ?? { mapView, annotation in
				let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.reuseIdentifier, for: annotation)

				annotationView.annotation = annotation
				annotationView.canShowCallout = true

				if let pinView = annotationView as? MKMarkerAnnotationView {
					switch annotation.mode {
					case .selectedCoordinate:
						pinView.markerTintColor = MKPinAnnotationView.greenPinColor()
						pinView.animatesWhenAdded = true
						pinView.alpha = 1
					case .startCoordinate:
						pinView.markerTintColor = MKPinAnnotationView.redPinColor()
						pinView.animatesWhenAdded = false
						pinView.alpha = 0.5
					}
				}

				return annotationView
			}
		}

		func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
			guard let annotation = annotation as? EditorAnnotation else { fatalError() }
			return provider(mapView, annotation)
		}
	}
}

#if DEBUG
import SwiftUI

//struct MapPreviews: PreviewProvider {
//
//	struct CoordinateEditorPreview: UIViewRepresentable {
//		@State var startCoord: CLLocationCoordinate2D?
//		@State var selectedCoord: CLLocationCoordinate2D?
//
//		let searchQuery: String?
//
//		func makeUIView(context: Context) -> CoordinateEditor {
//			let view = CoordinateEditor()
//
//			return view
//		}
//
//		func updateUIView(_ uiView: CoordinateEditor, context: Context) {
//			uiView.startCoordinates = startCoord
//			uiView.selectedCoordinates = selectedCoord
//
//			if let query = searchQuery {
//				uiView.performNaturalLanguageSearch(for: query) { [weak uiView] result in
//					do {
//						let response = try result.get()
//						uiView?.selectedCoordinates = response.mapItems.first?.placemark.coordinate
//						uiView?.setRegion(response.boundingRegion)
//					} catch {
//						print("Error searching map: \(error)")
//					}
//				}
//			}
//		}
//	}
//
//	struct PreviewWrapper: View {
//		@State var searchQuery = ""
//
//		var body: some View {
//			VStack {
//				TextField("Search", text: $searchQuery)
//
//				CoordinateEditorPreview(
//					startCoord: CLLocationCoordinate2D(latitude: 40.768866, longitude: -111.904324),
//					selectedCoord: nil,
//					searchQuery: searchQuery.isEmpty ? nil : searchQuery)
//			}
//		}
//	}
//
//	static var previews: some View {
//		PreviewWrapper()
//	}
//
//}
#endif
