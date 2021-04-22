import CoreLocation

extension CLLocation {
	convenience init(_ coordinate: CLLocationCoordinate2D) {
		self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
	}
}
