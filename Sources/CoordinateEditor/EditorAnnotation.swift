import MapKit

extension CoordinateEditor {
	public class EditorAnnotation: NSObject, MKAnnotation {
		public var title: String?
		public var subtitle: String?
		public let coordinate: CLLocationCoordinate2D
		public var mode: CoordinateSelectionMode

		public init(title: String? = nil, subtitle: String? = nil, mode: CoordinateSelectionMode, coordinate: CLLocationCoordinate2D) {
			self.title = title
			self.mode = mode
			self.subtitle = subtitle
			self.coordinate = coordinate
		}

		convenience init(_ placemark: MKPlacemark, mode: CoordinateSelectionMode) {
			let locality = [placemark.locality, placemark.administrativeArea]
				.compactMap { $0 }
				.joined(separator: ", ")
			let title = [placemark.name, locality]
				.compactMap { $0 }
				.joined(separator: " ")

			self.init(title: title, mode: mode, coordinate: placemark.coordinate)
		}

		public static func fetchName(for coordinate: CLLocationCoordinate2D, mode: CoordinateSelectionMode, completion: @escaping (Result<EditorAnnotation, Error>) -> Void) {
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
