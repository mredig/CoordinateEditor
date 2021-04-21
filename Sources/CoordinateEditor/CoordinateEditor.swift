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

		mapView.showAnnotations(mapView.annotations, animated: true)
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
			startCoord: CLLocationCoordinate2D(latitude: 45, longitude: 100),
			selectedCoord: CLLocationCoordinate2D(latitude: 25, longitude: 40))
	}

}
#endif
