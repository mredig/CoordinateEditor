import MapKit

class CoordinateEditor: UIView {
	var startCoordinates: CLLocationCoordinate2D? {
		didSet { updateAnnotations() }
	}
	var selectedCoordinates: CLLocationCoordinate2D? {
		didSet { updateAnnotations() }
	}

	private let mapView = MKMapView()

	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
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
			let start = MKPlacemark(coordinate: startCoordinates)

			mapView.addAnnotation(start)
		}

		if let selectedCoordinates = selectedCoordinates {
			let selected = MKPlacemark(coordinate: selectedCoordinates)

			mapView.addAnnotation(selected)
		}

		let regionCenter = startCoordinates ?? selectedCoordinates ?? CLLocationCoordinate2D(latitude: 40.759551, longitude: -111.888196)

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
}

#if DEBUG
import SwiftUI

struct MapPreviews: PreviewProvider {

	struct CoordinateEditorPreview: UIViewRepresentable {
		@State var startCoord: CLLocationCoordinate2D?
		@State var selectedCoord: CLLocationCoordinate2D?

		func makeUIView(context: Context) -> CoordinateEditor {
			CoordinateEditor()
		}

		func updateUIView(_ uiView: CoordinateEditor, context: Context) {
			uiView.startCoordinates = startCoord
			uiView.selectedCoordinates = selectedCoord
		}
	}

	static var previews: some View {
		CoordinateEditorPreview(
			startCoord: nil,
			selectedCoord: nil)
	}

}
#endif
