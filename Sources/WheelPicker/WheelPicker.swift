import SwiftUI
import Combine

public struct WheelPicker: View {
    @State var appeared: Int = 0
    @State var disappeared: Int = 0

    @State var offset: CGFloat = 0

    @State var selected: CellView = CellView(value: 0)

    public init() { }

    public var body: some View {
        VStack {
            Picker("", selection: $selected) {
                ForEach(0..<10) {
                    Text("\($0)")
                        .tag(CellView(value: $0))
                }
            }

            ZStack {
                Wrapper(selected: $selected)
//                Text("\(self.selected.value)")
//                    .padding(30)
//                    .background(Color.red)
//                    .allowsHitTesting(false)
            }

//            Text("Hellloooo")
//                .padding()
//                .background(Color.green)
        }
    }

}

struct CellView: View, Hashable {

    let value: Int

    var body: some View {
        Text("Item \(value)")
            .padding(20)
    }
}

struct Wrapper: UIViewRepresentable {

    @Binding var selected: CellView

    typealias UIViewType = CollectionPickerView<SwiftUICollectionViewCell<CellView>, UIHostingView<CellView>>

    func updateUIView(_ picker: UIViewType, context: Context) {
        picker.select(value: selected)
    }


    func makeUIView(context: Context) -> UIViewType {
        let cells = (0..<10)
            .map { CellView(value: $0) }
        let view = UIViewType(values: cells, selected: self.selected)
        context.coordinator.listing(to: view.publisher)
        return view
    }

    func makeCoordinator() -> PickerModel<CellView> {
        return PickerModel(selected: $selected)
    }
}

class PickerModel<Value: Hashable> {
    @Binding var selected: Value

    private var cancallable: AnyCancellable?

    init(selected: Binding<Value>) {
        self._selected = selected
    }

    func listing<P: Publisher>(to publisher: P) where P.Output == Value, P.Failure == Never {
        DispatchQueue.main.async {
            self.cancallable?.cancel()
            self.cancallable = publisher
                .map { print("Selected: \($0)"); return $0 }
                .assign(to: \.selected, on: self)
        }
    }
}

class UIHostingView<Content: View>: UIView, CollectionCenter where Content: Hashable {
    func set(value content: Content) {
        self.subviews.forEach {
            $0.removeFromSuperview()
        }
        let hostingController = UIHostingController(rootView: content)
        backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        self.addSubview(hostingController.view)

        let constraints = [
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            hostingController.view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            hostingController.view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0),
        ]
        NSLayoutConstraint.activate(constraints)
    }
}

final class SwiftUICollectionViewCell<Content: View>: UICollectionViewCell, CollectionCell where Content: Hashable {
    func set(value content: Content) {
        contentView.subviews.forEach {
            $0.removeFromSuperview()
        }
        let hostingController = UIHostingController(rootView: content)
        backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        contentView.addSubview(hostingController.view)

        let constraints = [
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            hostingController.view.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            hostingController.view.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
        ]
        NSLayoutConstraint.activate(constraints)
    }
}

struct WheelPicker_Previews: PreviewProvider {

    struct Preview: View {
        @State var value: Int = 1

        var body: some View {
            WheelPicker()
        }
    }
    static var previews: some View {
        Preview()
    }
}

