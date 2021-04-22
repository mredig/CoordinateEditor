import MapKit

public class CoordinateEditorView: UIView {
	private var _startLocationAnnotation: EditorAnnotation?
	/**
	Set this value if you have coordinates to start with and a title to label on the map. If you only have coordinates, refer to `setStarter(_:)`
	*/
	public var startLocationAnnotation: EditorAnnotation? {
		get { _startLocationAnnotation }
		set {
			newValue?.mode = .startCoordinate
			_startLocationAnnotation = newValue
			updateAnnotations()
		}
	}
	private var _selectedLocationAnnotation: EditorAnnotation?
	/**
	This value reflects the location that the user has selected. You may also set it programmatically.
	*/
	public var selectedLocationAnnotation: EditorAnnotation? {
		get { _selectedLocationAnnotation }
		set {
			newValue?.mode = .selectedCoordinate
			_selectedLocationAnnotation = newValue
			updateAnnotations()
		}
	}

	/**
	Forwarded property from the `MKMapView`
	*/
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

	/**
	You may provide a new value to this closure to override the default pin appearances.
	*/
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

		EditorAnnotation.fetchNameAndInit(for: coordinate, mode: .selectedCoordinate) { [weak self] result in
			do {
				let annotation = try result.get()
				self?.selectedLocationAnnotation = annotation
			} catch {
				print("Error fetching name for coordinate \(coordinate): \(error)")
			}
		}
	}

	public typealias SearchResultCompletion = (Result<MKLocalSearch.Response, Error>, CoordinateEditorView) -> Void
	/**
	Performs a search for map locations based on the user's text input using natural language. The response is provided without enacting any actions. If you wish for
	the location to automatically be selected, you may just set the `selectedLocationAnnotation` to the result in the completion closure, or maybe you'd
	prefer to just move the region to the boundary of the result. Perhaps you don't want to do anything and just print someting to the console. I don't care. I'm not
	your mom. Do what you want. But the tools are there if you DO want to automate anything.
	*/
	public func performNaturalLanguageSearch(for query: String, completion: @escaping SearchResultCompletion) {
		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = query
		let search = MKLocalSearch(request: request)
		search.start { [self] response, error in
			let result: Result<MKLocalSearch.Response, Error>
			defer {
				DispatchQueue.main.async {
					completion(result, self)
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

	/**
	Passthrough to the `MKMapView`'s `setRegion` method.
	*/
	public func setRegion(_ region: MKCoordinateRegion, animated: Bool = true) {
		mapView.setRegion(region, animated: animated)
	}

	/**
	Will perform a quick reverse geo lookup to find a natual language label for the provided coordinates and then set the labelled result to the `startLocationAnnotation`
	*/
	public func setStarter(to coordinate: CLLocationCoordinate2D) {
		EditorAnnotation.fetchNameAndInit(for: coordinate, mode: .startCoordinate) { [weak self] result in
			self?.startLocationAnnotation = try? result.get()
		}
	}

	/**
	Passthrough to the `MKMapView`'s `register` method - allows you to provide custom `MKMapAnnotationView` subclasses
	*/
	public func register(_ viewClass: AnyClass, forAnnotationViewWithReuseIdentifier identifier: String) {
		mapView.register(viewClass, forAnnotationViewWithReuseIdentifier: identifier)
	}

	enum CoordinateEditorError: Error {
		case noResponse
	}
}

extension CoordinateEditorView {
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
