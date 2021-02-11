//
//  ContentView.swift
//  Example
//
//  Created by Leonard Mehlig on 29.01.21.
//

import SwiftUI
import WheelPicker
import StepSlider

public struct InteractiveButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
//            .shadow(configuration.isPressed && !self.accessibilityReduceMotion
//                ? .none
//                : self.shadow)
            .scaleEffect(configuration.isPressed && !self.accessibilityReduceMotion
                ? 0.95
                : 1)
            .animation(.interactiveSpring(), value: configuration.isPressed && !self.accessibilityReduceMotion)
    }
}

class Model: ObservableObject {
    @Published var size: Int = 1
}

struct ContentView: View {
    @StateObject var model = Model()

    @State var selected: Int = 50

    @State var values: [Int] = Array(stride(from: 0, through: 100, by: 5))

    var body: some View {
        VStack {
            Text("Steps: \(model.size) - Selected: \(selected)")
            StepSlider(selected: $model.size, values: [1,5,10,20])
//            Stepper("Center", value: $center)
//            Picker("Values", selection: $selected) {
//                ForEach(values, id: \.self) {
//                    Text("\($0)")
//                        .tag($0)
//                }
//            }

            Button("Test") {
                self.selected = 12
            }

            if model.size > 1 {
                GeometryReader { proxy in
            WheelPicker(values,
                        selected: $selected,
                        centerSize: model.size,
                        cell: {
                            Text("\($0)")
                                .font(.headline)
                                .padding()
                        },
                        center: { value in
                            Button(action: { }) {
                                Text("\(value) - \(value + model.size - 1)")
                                    .font(.headline)
                                    .padding()
                                    .frame(minWidth: 100)
                                    .background(Color.red)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.12), radius: 4)
                            }
                            .buttonStyle(InteractiveButtonStyle())
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
        }
        .animation(.spring())
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
