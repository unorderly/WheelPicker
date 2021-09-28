import SwiftUI
import WheelPicker

struct ContentView: View {
    struct Value: Comparable, Equatable, Hashable {
        static func < (lhs: ContentView.Value, rhs: ContentView.Value) -> Bool {
            lhs.index < rhs.index
        }

        let index: Int
        let length: Int
    }
//    @State var center = 2

    @State var selected: Value = Value(index: 50, length: 1)

    @State var length: Int = 1

    var values: [Value] {
        stride(from: 0, through: 100, by: 1).map { Value.init(index: $0, length: self.length) }
    }

    var body: some View {
        VStack {
            Text("Length: \(length) - Selected: \(selected.index) - \(selected.length)")

            Stepper("Center", value: $length)
            Picker("Values", selection: $selected) {
                ForEach(values, id: \.self) {
                    Text("\($0.index)")
                        .tag($0)
                }
            }

//            Button("Test") {
//                self.selected =
//            }

            GeometryReader { proxy in
                WheelPicker(values,
                            selected: $selected,
                            centerSize: length / 10 + 1,
                            cell: {
                    Text("\($0.index) - \($0.length)")
                                    .font(.headline)
                                    .padding()
                                    .background(Color.red.opacity(0.5))
                                    .border(Color.black.opacity(0.5))
                            },
                            center: { value in
                                Button(action: {}) {
                                    Text("\(value.index) - \(value.length)")
                                        .font(.headline)
                                        .padding()
                                        .frame(minWidth: 100)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.12), radius: 4)
                                }
                            })
                    .accessibility(label: Text("Time Picker"))
                    .accessibility(hint: Text(hint))
                    .frame(width: proxy.size.width)
            }
            .frame(height: 200)
            .transition(AnyTransition.opacity.animation(Animation.default)
                .combined(with: .move(edge: .bottom)))
            .animation(.spring())
        }
        .animation(.spring())
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
