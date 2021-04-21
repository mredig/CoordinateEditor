import MapKit

public protocol EditorAnnotation: MKAnnotation {
	var mode: CoordinateEditor.CoordinateSelectionMode { get }
}

extension CoordinateEditor {
	public class EasyAnnotation: NSObject, EditorAnnotation {
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
	}
}

extension MKPinAnnotationView {
	static let reuseIdentifier = "\(MKPinAnnotationView.self)-cellID"
}
