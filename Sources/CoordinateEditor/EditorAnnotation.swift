import MapKit

extension CoordinateEditorView {
	public class EditorAnnotation: NSObject, MKAnnotation {
		public var title: String? {
			sourcePlacemark.title
		}
		public var subtitle: String?
		public var coordinate: CLLocationCoordinate2D {
			sourcePlacemark.coordinate
		}
		public var mode: CoordinateSelectionMode
		public let sourcePlacemark: MKPlacemark

		public init(_ placemark: MKPlacemark, mode: CoordinateSelectionMode) {
			self.mode = mode
			self.sourcePlacemark = placemark
		}

		public static func fetchNameAndInit(for coordinate: CLLocationCoordinate2D, mode: CoordinateSelectionMode, completion: @escaping (Result<EditorAnnotation, Error>) -> Void) {
			CLGeocoder().reverseGeocodeLocation(CLLocation(coordinate)) { placemarks, error in
				let result: Result<EditorAnnotation, Error>
				defer {
					DispatchQueue.main.async { completion(result) }
				}

				if let error = error {
					result = .failure(error)
					return
				}

				guard let place = placemarks?.first else {
					result = .failure(CoordinateEditorError.noResponse)
					return
				}
				let placemark = MKPlacemark(placemark: place)
				let new = EditorAnnotation(placemark, mode: mode)
				result = .success(new)
			}
		}
	}
}


protocol ReuseIdentifiable {
	static var reuseIdentifier: String { get }
}

extension ReuseIdentifiable {
	static var reuseIdentifier: String { "\(Self.self)-cellID" }
}


extension MKPinAnnotationView: ReuseIdentifiable {}

extension MKMarkerAnnotationView: ReuseIdentifiable {}
