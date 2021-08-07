import Combine
import SwiftUI

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

extension Int: Identifiable {
    public var id: Int {
        self
    }
}

struct WheelPicker_Previews: PreviewProvider {
    struct Preview: View {
        @State var center: Int = 1

        @State var selected: Int = 0

        @State var values: [Int] = Array(0 ..< 100)

        public init() {}

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
                hint += "Up: \(self.values[index - 1])"
            }
            if index < self.values.endIndex - 1 {
                hint += "Down: \(self.values[index + 1])"
            }
            return hint
        }
    }

    public static var previews: some View {
        Preview()
    }
}
