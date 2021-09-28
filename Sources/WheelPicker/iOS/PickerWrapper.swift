#if canImport(UIKit)
    import Combine
    import SwiftUI

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
            picker.configureCell = { $0.set(value: self.cell($1)) }
            picker.configureCenter = { $0.set(value: self.center($1)) }
            picker.values = self.values
            picker.select(value: self.selected)
            picker.centerSize = self.centerSize
        }

        func makeUIView(context: Context) -> UIViewType {
            let picker = UIViewType(values: self.values,
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

    final class UIHostingView<Content: View>: UIView {
        private var hosting: UIHostingController<Content>?

        func set(value content: Content) {
            if let hosting = self.hosting {
                hosting.rootView = content
            } else {
                let hosting = UIHostingController(rootView: content)
                backgroundColor = .clear
                hosting.view.translatesAutoresizingMaskIntoConstraints = false
                hosting.view.backgroundColor = .clear
                self.addSubview(hosting.view)

                NSLayoutConstraint.activate([
                    hosting.view.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
                    hosting.view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
                    hosting.view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
                    hosting.view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0)
                ])
                self.hosting = hosting
            }
        }
    }

    final class UIHostingCell<Content: View>: UICollectionViewCell {
        private var hosting: UIHostingController<Content>?

        func set(value content: Content) {
            if let hosting = self.hosting {
                hosting.rootView = content
            } else {
                let hosting = UIHostingController(rootView: content)

                backgroundColor = .clear
                hosting.view.translatesAutoresizingMaskIntoConstraints = false
                hosting.view.backgroundColor = .clear
//                hosting.view.layer.borderColor = UIColor.green.withAlphaComponent(0.5).cgColor
//                hosting.view.layer.borderWidth = 2
                self.contentView.addSubview(hosting.view)

                NSLayoutConstraint.activate([
                    hosting.view.topAnchor
                        .constraint(equalTo: self.contentView.topAnchor, constant: 0),
                    hosting.view.leftAnchor
                        .constraint(equalTo: self.contentView.leftAnchor, constant: 0),
                    hosting.view.bottomAnchor
                        .constraint(equalTo: self.contentView.bottomAnchor, constant: 0),
                    hosting.view.rightAnchor
                        .constraint(equalTo: self.contentView.rightAnchor, constant: 0)
                ])
                self.hosting = hosting
            }
        }


        override func layoutSubviews() {
            super.layoutSubviews()
            self.hosting?.view.setNeedsUpdateConstraints()
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            self.hosting?.view.removeFromSuperview()
            self.hosting = nil
        }
    }

#endif
