import SwiftUI
import Combine

public struct WheelPicker<Cell: View, Center: View, Value: Hashable>: View where Value: Comparable {
    let values: [Value]

    @Binding var selected: Value

    let centerSize: Int

    let cell: (Value) -> Cell
    let center: (Value) -> Center

    public init(_ values: [Value],
         selected: Binding<Value>,
         centerSize: Int = 1,
         cell: @escaping (Value) -> Cell,
         center: @escaping (Value) -> Center) {
        self.values = values
        self._selected = selected
        self.cell = cell
        self.center = center
        self.centerSize = centerSize
    }

    public var body: some View {
        PickerWrapper(values, selected: $selected, centerSize: centerSize, cell: cell, center: center)
    }
}

struct PickerWrapper<Cell: View, Center: View, Value: Hashable>: UIViewRepresentable where Value: Comparable {


    let values: [Value]

    @Binding var selected: Value

    let centerSize: Int

    let cell: (Value) -> Cell
    let center: (Value) -> Center

    typealias UIViewType = CollectionPickerView<UIHostingCell<Cell>, UIHostingView<Center>, Value>

    init(_ values: [Value],
         selected: Binding<Value>,
         centerSize: Int = 1,
         cell: @escaping (Value) -> Cell,
         center: @escaping (Value) -> Center) {
        self.values = values
        self._selected = selected
        self.cell = cell
        self.center = center
        self.centerSize = centerSize
    }

    func updateUIView(_ picker: UIViewType, context: Context) {
        picker.values = values
        picker.select(value: selected)
        picker.centerSize = centerSize
    }


    func makeUIView(context: Context) -> UIViewType {
        let picker = UIViewType(values: self.values,
                              selected: self.selected,
                              configureCell: { $0.set(value: self.cell($1)) },
                              configureCenter: { $0.set(value: self.center($1)) })
        picker.centerSize = centerSize
        context.coordinator.listing(to: picker.publisher)
        return picker
    }

    func makeCoordinator() -> PickerModel<Value> {
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
                .assign(to: \.selected, on: self)
        }
    }
}

final class UIHostingView<Content: View>: UIView {
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

final class UIHostingCell<Content: View>: UICollectionViewCell {
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
        @State var center: Int = 1

        @State var selected: Int = 0

        @State var values: [Int] = Array(0..<100)

        public init() { }

        public var body: some View {
            VStack {
                Text("Steps: \(center)")
                Stepper("Center", value: $center)
                Picker("Values", selection: $selected) {
                    ForEach(values, id: \.self) {
                        Text("\($0)")
                            .tag($0)
                    }
                }

                WheelPicker(values,
                            selected: $selected,
                            centerSize: center,
                            cell: {
                                Text("\($0)")
                                    .font(.headline)
                                    .padding()
                            },
                            center: {
                                Text("\($0) - \($0 + center - 1)")
                                    .font(.headline)
                                    .padding()
                                    .frame(minWidth: 100)
                                    .background(Color.red)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.12), radius: 4)
                            })
                    .accessibility(label: Text("Time Picker"))
                    .accessibility(hint: Text(hint))
            }
        }

        var hint: String {
            guard let index = self.values.firstIndex(of: selected) else {
                return ""
            }
            var hint = ""
            if index > self.values.startIndex {
                hint += "Up: \(self.values[index-1])"
            }
            if index < self.values.endIndex - 1 {
                hint += "Down: \(self.values[index+1])"
            }
            return hint
        }
    }
    public static var previews: some View {
        Preview()
    }
}

