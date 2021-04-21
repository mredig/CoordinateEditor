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


	public init(annotationGenerator: @escaping AnnotationGenerator = { _, coordinates in MKPlacemark(coordinate: coordinates) }) {
		self.annotationGenerator = annotationGenerator
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

		let regionCenter = selectedCoordinates ?? startCoordinates ??  CLLocationCoordinate2D(latitude: 40.768866, longitude: -111.904324)

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

	public func setRegion(_ region: MKCoordinateRegion, animated: Bool = true) {
		mapView.setRegion(region, animated: animated)
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
			startCoord: CLLocationCoordinate2D(latitude: 40.768866, longitude: -111.904324),
			selectedCoord: nil)
	}

}
#endif
