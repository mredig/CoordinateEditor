import MapKit

extension CoordinateEditor {
	public class EasyAnnotation: NSObject, MKAnnotation {
		public var title: String?
		public var subtitle: String?
		public let coordinate: CLLocationCoordinate2D

		public init(title: String? = nil, subtitle: String? = nil, coordinate: CLLocationCoordinate2D) {
			self.title = title
			self.subtitle = subtitle
			self.coordinate = coordinate
		}
	}
}
