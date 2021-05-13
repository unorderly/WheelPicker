import SwiftUI
import WheelPicker

struct ContentView: View {
    @State var center = 2

    @State var selected: Int = 50

    @State var values: [Int] = Array(stride(from: 0, through: 100, by: 5))

    var body: some View {
        VStack {
            Text("Steps: \(center) - Selected: \(selected)")

            Stepper("Center", value: $center)
            Picker("Values", selection: $selected) {
                ForEach(values, id: \.self) {
                    Text("\($0)")
                        .tag($0)
                }
            }

            Button("Test") {
                self.selected = 12
            }

            GeometryReader { proxy in
                WheelPicker(values,
                            selected: $selected,
                            centerSize: center,
                            cell: {
                                Text("\($0)")
                                    .font(.headline)
                                    .padding()
                            },
                            center: { value in
                                Button(action: {}) {
                                    Text("\(value) - \(value + center - 1)")
                                        .font(.headline)
                                        .padding()
                                        .frame(minWidth: 100)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.12), radius: 4)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            })
                    .accessibility(label: Text("Time Picker"))
                    .accessibility(hint: Text(hint))
                    .frame(width: proxy.size.width)
            }
            .frame(height: 500)
            .transition(AnyTransition.opacity.animation(Animation.default)
                .combined(with: .move(edge: .bottom)))
            .animation(.spring())
        }
//        .animation(.spring())
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
