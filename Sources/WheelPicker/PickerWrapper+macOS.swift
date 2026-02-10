#if os(macOS)
import AppKit
import SwiftUI

struct PickerWrapper<Cell: View, Center: View, Value: Hashable>: NSViewRepresentable where Value: Comparable {
    let values: [Value]

    @Binding var selected: Value

    let centerSize: Int
    let collectionViewBounces: Bool

    let cell: (Value) -> Cell
    let center: (Value) -> Center

    let onScroll: (Value, Value) -> Void

    typealias NSViewType = MacWheelPickerView<Value>

    init(_ values: [Value],
         selected: Binding<Value>,
         collectionViewBounces: Bool? = true,
         centerSize: Int = 1,
         onScroll: @escaping (Value, Value) -> Void,
         cell: @escaping (Value) -> Cell,
         center: @escaping (Value) -> Center) {
        self.values = values
        self._selected = selected
        self.collectionViewBounces = collectionViewBounces ?? true
        self.centerSize = centerSize
        self.onScroll = onScroll
        self.cell = cell
        self.center = center
    }

    func makeCoordinator() -> PickerModel<Value> {
        PickerModel(selected: self.$selected, onScroll: self.onScroll)
    }

    func makeNSView(context: Context) -> NSViewType {
        let picker = NSViewType(values: self.values,
                                selected: self.selected,
                                centerSize: self.centerSize,
                                collectionViewBounces: self.collectionViewBounces,
                                configureCell: { value in AnyView(self.cell(value)) },
                                configureCenter: { value in AnyView(self.center(value)) })
        picker.onSelectionChanged = { value in
            context.coordinator.didSelect(value)
        }
        return picker
    }

    func updateNSView(_ picker: NSViewType, context: Context) {
        picker.configureCell = { value in AnyView(self.cell(value)) }
        picker.configureCenter = { value in AnyView(self.center(value)) }
        picker.collectionViewBounces = self.collectionViewBounces
        picker.values = self.values
        picker.centerSize = self.centerSize
        picker.select(value: self.selected)
        picker.onSelectionChanged = { value in
            context.coordinator.didSelect(value)
        }
    }
}

final class PickerModel<Value: Hashable> {
    @Binding var selected: Value

    let onScroll: (Value, Value) -> Void

    init(selected: Binding<Value>, onScroll: @escaping (Value, Value) -> Void) {
        self._selected = selected
        self.onScroll = onScroll
    }

    func didSelect(_ value: Value) {
        if self.selected != value {
            self.onScroll(self.selected, value)
            self.selected = value
        }
    }
}

final class MacWheelPickerView<Value: Hashable & Comparable>: NSView {
    var values: [Value] {
        didSet {
            guard self.values != oldValue else {
                return
            }

            let previousValue = oldValue[safe: self.selectedIndex] ?? oldValue.first
            if let previousValue {
                if let newIndex = self.values.firstIndex(where: { $0 >= previousValue }) {
                    self.selectedIndex = newIndex
                } else {
                    self.selectedIndex = max(self.values.count - 1, 0)
                }
            } else {
                self.selectedIndex = 0
            }

            self.reloadRows()
            self.updateCenterView()
            self.scrollToItem(at: self.selectedIndex, animated: false)
        }
    }

    var centerSize: Int {
        didSet {
            guard self.centerSize != oldValue else {
                return
            }
            self.updateRowLayout()
            self.updateCenterView()
            self.scrollToItem(at: self.selectedIndex, animated: false)
        }
    }

    var collectionViewBounces: Bool {
        didSet {
            self.scrollView.verticalScrollElasticity = self.collectionViewBounces ? .automatic : .none
        }
    }

    var configureCell: (Value) -> AnyView {
        didSet {
            self.reloadRows()
        }
    }

    var configureCenter: (Value) -> AnyView {
        didSet {
            self.updateCenterView()
        }
    }

    var onSelectionChanged: ((Value) -> Void)?

    private let scrollView = NSScrollView()
    private let documentView = NSView()
    private var rowViews: [NSHostingView<AnyView>] = []

    private var centerHostingView: NSHostingView<AnyView>

    private var cellHeight: CGFloat = 44

    private var selectedIndex: Int = 0 {
        didSet {
            guard self.selectedIndex != oldValue,
                  let value = self.currentSelectedValue else {
                return
            }
            self.updateCenterView()
            self.onSelectionChanged?(value)
        }
    }

    private var isProgrammaticScroll = false
    private var endScrollWorkItem: DispatchWorkItem?

    init(values: [Value],
         selected: Value,
         centerSize: Int,
         collectionViewBounces: Bool,
         configureCell: @escaping (Value) -> AnyView,
         configureCenter: @escaping (Value) -> AnyView) {
        self.values = values
        self.centerSize = max(centerSize, 1)
        self.collectionViewBounces = collectionViewBounces
        self.configureCell = configureCell
        self.configureCenter = configureCenter
        self.centerHostingView = NSHostingView(rootView: AnyView(EmptyView()))
        self.selectedIndex = values.firstIndex(of: selected) ?? 0
        super.init(frame: .zero)

        self.wantsLayer = true
        self.scrollView.drawsBackground = false
        self.scrollView.hasVerticalScroller = false
        self.scrollView.hasHorizontalScroller = false
        self.scrollView.autohidesScrollers = true
        self.scrollView.automaticallyAdjustsContentInsets = false
        self.scrollView.contentInsets = NSEdgeInsetsZero
        self.scrollView.verticalScrollElasticity = collectionViewBounces ? .automatic : .none

        self.scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.boundsDidChange),
                                               name: NSView.boundsDidChangeNotification,
                                               object: self.scrollView.contentView)

        self.scrollView.documentView = self.documentView
        self.documentView.wantsLayer = true

        self.addSubview(self.scrollView)
        self.addSubview(self.centerHostingView)

        self.reloadRows()
        self.updateCenterView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layout() {
        super.layout()
        self.scrollView.frame = self.bounds
        self.updateRowLayout()
        self.layoutCenterView()
        self.scrollToItem(at: self.selectedIndex, animated: false)
    }

    func select(value: Value) {
        guard !self.isProgrammaticScroll,
              let index = self.values.firstIndex(of: value),
              index != self.selectedIndex else {
            return
        }
        self.scrollToItem(at: index)
    }

    @objc
    private func boundsDidChange() {
        self.didScroll(end: false)

        guard !self.isProgrammaticScroll else {
            return
        }
        self.endScrollWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.didScroll(end: true)
        }
        self.endScrollWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
    }

    private var currentSelectedValue: Value? {
        self.values[safe: self.selectedIndex]
    }

    private func reloadRows() {
        for row in self.rowViews {
            row.removeFromSuperview()
        }
        self.rowViews = self.values.map { value in
            let row = NSHostingView(rootView: self.configureCell(value))
            row.translatesAutoresizingMaskIntoConstraints = false
            row.frame = .zero
            self.documentView.addSubview(row)
            return row
        }
        self.updateRowLayout()
    }

    private func updateCenterView() {
        guard let selected = self.currentSelectedValue else {
            self.centerHostingView.rootView = AnyView(EmptyView())
            return
        }
        self.centerHostingView.rootView = self.configureCenter(selected)
        self.layoutCenterView()
    }

    private func updateRowLayout() {
        self.cellHeight = self.measuredCellHeight()

        let topInset = max((self.bounds.height - self.cellHeight) / 2, 0)
        let bottomInset = topInset

        var y = topInset
        let width = self.bounds.width

        for row in self.rowViews {
            row.frame = CGRect(x: 0, y: y, width: width, height: self.cellHeight)
            y += self.cellHeight
        }

        let contentHeight = max(y + bottomInset, self.bounds.height)
        self.documentView.frame = CGRect(x: 0, y: 0, width: width, height: contentHeight)
    }

    private func measuredCellHeight() -> CGFloat {
        guard let value = self.values.first else {
            return 44
        }

        let sizingView = NSHostingView(rootView: self.configureCell(value))
        sizingView.frame = CGRect(x: 0, y: 0, width: max(self.bounds.width, 1), height: 10)
        let measured = sizingView.fittingSize.height
        if measured > 0 {
            return measured
        }
        return 44
    }

    private func layoutCenterView() {
        self.centerHostingView.frame.size.width = self.bounds.width
        let size = self.centerHostingView.fittingSize
        self.centerHostingView.frame = CGRect(x: 0,
                                              y: (self.bounds.height - size.height) / 2,
                                              width: self.bounds.width,
                                              height: size.height)
    }

    private func scrollToItem(at index: Int, animated: Bool = true) {
        guard self.values.indices.contains(index) else {
            return
        }

        let offsetY = self.offsetForItem(at: index)
        self.isProgrammaticScroll = true

        let newOrigin = CGPoint(x: 0, y: offsetY)
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                self.scrollView.contentView.animator().setBoundsOrigin(newOrigin)
            } completionHandler: {
                self.isProgrammaticScroll = false
            }
        } else {
            self.scrollView.contentView.setBoundsOrigin(newOrigin)
            self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
            self.isProgrammaticScroll = false
        }

        self.selectedIndex = index
    }

    private func offsetForItem(at index: Int) -> CGFloat {
        let centerIndex = CGFloat(index) + CGFloat(self.effectiveCenterSize - 1) / 2
        let centerY = centerIndex * self.cellHeight + self.cellHeight / 2
        let offsetY = centerY - self.bounds.height / 2

        let maxOffset = max(self.documentView.bounds.height - self.bounds.height, 0)
        return min(max(offsetY, 0), maxOffset)
    }

    private func didScroll(end: Bool) {
        guard !self.values.isEmpty,
              self.cellHeight > 0 else {
            return
        }

        let centerY = self.scrollView.contentView.bounds.midY
        let rawCenterIndex = (centerY - self.cellHeight / 2) / self.cellHeight
        let candidate = Int(round(rawCenterIndex - CGFloat(self.effectiveCenterSize - 1) / 2))
        let clamped = min(max(candidate, 0), max(self.values.count - 1, 0))

        if clamped != self.selectedIndex {
            self.selectedIndex = clamped
        }

        if end {
            self.scrollToItem(at: clamped)
        }
    }

    private var effectiveCenterSize: Int {
        max(self.centerSize, 1)
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        self.indices.contains(index) ? self[index] : nil
    }
}
#endif
