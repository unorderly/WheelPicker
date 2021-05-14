#if canImport(AppKit)
import Combine
import SwiftUI

struct PickerWrapper<Cell: View, Center: View, Value: Hashable>: NSViewRepresentable where Value: Comparable {
    let values: [Value]

    @Binding var selected: Value

    let centerSize: Int

    let cell: (Value) -> Cell
    let center: (Value) -> Center

    typealias NSViewType = CollectionPickerView<NSHostingCell<Cell>, NSHostingView<Center>, Value>

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

    func updateNSView(_ picker: NSViewType, context: Context) {
        picker.configureCell = { $0.set(value: self.cell($1)) }
        picker.configureCenter = { $0.set(value: self.center($1)) }
        picker.values = self.values
        picker.select(value: self.selected)
        picker.centerSize = self.centerSize
    }

    func makeNSView(context: Context) -> NSViewType {
        let picker = NSViewType(values: self.values,
                                selected: self.selected,
                                configureCell: { $0.set(value: self.cell($1)) },
                                configureCenter: { $0.set(value: self.center($1)) })
        picker.centerSize = self.centerSize
        context.coordinator.listing(to: picker.publisher)
        return picker
    }

    func makeCoordinator() -> PickerModel<Value> {
        PickerModel(selected: $selected)
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

final class NSHostingView<Content: View>: NSView {
    private var hosting: SwiftUI.NSHostingView<Content>?


    func set(value content: Content) {
        if let hosting = self.hosting {
            hosting.rootView = content
        } else {
            let hosting = SwiftUI.NSHostingView(rootView: content)
            layer?.backgroundColor = NSColor.clear.cgColor
            hosting.translatesAutoresizingMaskIntoConstraints = false
            hosting.layer?.backgroundColor = NSColor.clear.cgColor
            self.addSubview(hosting)

            NSLayoutConstraint.activate([
                hosting.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
                hosting.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
                hosting.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
                hosting.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0)
            ])
            self.hosting = hosting
        }
    }
}

final class NSHostingCell<Content: View>: NSCollectionViewItem {
    private var hosting: SwiftUI.NSHostingView<Content>?

    override func loadView() {
        self.view = NSView()
    }

    func set(value content: Content) {
        if let hosting = self.hosting {
            hosting.rootView = content
        } else {
            let hosting = SwiftUI.NSHostingView(rootView: content)

            hosting.translatesAutoresizingMaskIntoConstraints = false
            hosting.layer?.backgroundColor = NSColor.clear.cgColor

            self.view.addSubview(hosting)

            NSLayoutConstraint.activate([
                hosting.topAnchor
                    .constraint(equalTo: self.view.topAnchor, constant: 0),
                hosting.leftAnchor
                    .constraint(equalTo: self.view.leftAnchor, constant: 0),
                hosting.bottomAnchor
                    .constraint(equalTo: self.view.bottomAnchor, constant: 0),
                hosting.rightAnchor
                    .constraint(equalTo: self.view.rightAnchor, constant: 0)
            ])
            self.hosting = hosting
        }
    }
}

#endif
