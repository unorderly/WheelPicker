//
//  ContentView.swift
//  Example
//
//  Created by Leonard Mehlig on 29.01.21.
//

import SwiftUI
import WheelPicker

struct ContentView: View {
    @State var center: Int = 1

    @State var selected: Int = 0

    @State var values: [Int] = Array(0..<100)

    var body: some View {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
