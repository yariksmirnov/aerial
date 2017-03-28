//
//  InspectorView.swift
//  Aerial
//
//  Created by Yaroslav Smirnov on 27/03/2017.
//  Copyright © 2017 Yaroslav Smirnov. All rights reserved.
//

import Cocoa
import PureLayout

final class InspectorView: NSScrollView {

    var container = ScrollDocumentView()
    var stackView = NSStackView()
    fileprivate var sections = [InpsectorSectionView]()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        defaultInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        defaultInit()
    }

    private func defaultInit() {
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        documentView = container
        container.translatesAutoresizingMaskIntoConstraints = false
        container.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero, excludingEdge: .bottom)
        container.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        stackView.orientation = .vertical
        stackView.distribution = .fill
    }

    func configure(withRecords records: [InspectorRecord]) {
        sections.forEach { $0.removeFromSuperview() }
        sections.removeAll()

        let general = records.filter { $0.value is String }.sorted {
            $0.0.title.compare($0.1.title) == .orderedAscending
        }
        let specific = records.filter { $0.value is [String: String] }.sorted {
            $0.0.title.compare($0.1.title) == .orderedAscending
        }

        let sorted = [InspectorRecord(title: "General", value: general)] + specific.map {
            var value = [InspectorRecord]()
            ($0.value as? [String: String])?.forEach {
                value.append(InspectorRecord(title: $0.key, value: $0.value))
            }
            return InspectorRecord(title: $0.title, value: value)
        }

        for record in sorted {
            let sectionView = InpsectorSectionView(title: record.title)
            sections.append(sectionView)
            guard let section = record.value as? [InspectorRecord] else { return }
            let sectionsContainer = NSView()
            sectionView.addSubview(sectionsContainer)
            sectionsContainer.autoPinEdgesToSuperviewEdges(
                with: NSEdgeInsetsZero,
                excludingEdge: .top
            )
            sectionsContainer.autoPinEdge(.top, to: .bottom, of: sectionView.titleLabel, withOffset: 4)
            var previousTitleView: NSTextField?
            var previousRecordView: NSView?
            for sectionRecord in section {
                let recordView = SectionRecordView()
                sectionView.records.append(recordView)
                sectionsContainer.addSubview(recordView)
                let recordTitle = recordView.titleView
                recordTitle.isBordered = false
                recordTitle.preferredMaxLayoutWidth = 70
                recordTitle.isEditable = false
                recordTitle.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize())
                recordTitle.stringValue = sectionRecord.title
                recordTitle.alignment = .right
                recordView.addSubview(recordTitle)
                recordTitle.setContentCompressionResistancePriority(NSLayoutPriorityRequired, for: .vertical)
                recordTitle.setContentHuggingPriority(NSLayoutPriorityRequired, for: .horizontal)
                let valueLabel = recordView.valueView
                valueLabel.isBordered = false
                valueLabel.setContentCompressionResistancePriority(NSLayoutPriorityRequired, for: .vertical)
                valueLabel.setContentCompressionResistancePriority(NSLayoutPriorityDefaultLow, for: .horizontal)
                valueLabel.isEditable = false
                valueLabel.isSelectable = true
                valueLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular))
                valueLabel.stringValue = sectionRecord.value as? String ?? "NaN"
                recordView.addSubview(valueLabel)

                recordTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 5)
                recordTitle.autoPinEdge(toSuperviewEdge: .bottom)
                recordTitle.autoPinEdge(.right, to: .left, of: valueLabel)
                recordTitle.autoSetDimension(.width, toSize: 70, relation: .greaterThanOrEqual)
                recordTitle.autoSetDimension(.width, toSize: 100, relation: .lessThanOrEqual)
                if let prevTitle = previousTitleView {
                    recordTitle.autoMatch(.width, to: .width, of: prevTitle)
                }
                valueLabel.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero, excludingEdge: .left)
                valueLabel.autoPinEdge(.left, to: .right, of: recordTitle)

                recordView.autoPinEdge(toSuperviewEdge: .left)
                recordView.autoPinEdge(toSuperviewEdge: .right)
                if let view = previousRecordView {
                    recordView.autoPinEdge(.top, to: .bottom, of: view, withOffset: 2)
                } else {
                    recordView.autoPinEdge(toSuperviewEdge: .top)
                }
                previousTitleView = recordTitle
                previousRecordView = recordView
            }
            previousRecordView?.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20)
        }
        for (i, view) in sections.enumerated() {
            self.stackView.addArrangedSubview(view)
            view.autoMatch(.width, to: .width, of: stackView)
            if i > 0 {
                guard let firstRecords = view.records.first else { continue }
                guard let lastRecord = sections[i - 1].records.last else { continue }
                firstRecords.titleView.autoMatch(.width, to: .width, of: lastRecord.titleView)
            }
        }
    }

}

private final class SectionRecordView: NSView {
    var titleView = NSTextField()
    var valueView = NSTextField()
}

private final class InpsectorSectionView: NSView {

    var titleLabel = NSTextField()
    var records = [SectionRecordView]()

    init(title: String) {
        super.init(frame: .zero)
        addSubview(titleLabel)
        titleLabel.isEditable = false
        titleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 2)
        titleLabel.autoPinEdge(toSuperviewEdge: .top)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 11)
        titleLabel.stringValue = title
        titleLabel.isBordered = false

        let separator = View()
        addSubview(separator)
        separator.autoSetDimension(.height, toSize: 1)
        separator.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero, excludingEdge: .top)
        separator.backgroundColor = NSColor.lightGray.withAlphaComponent(0.8)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

final class ScrollDocumentView: NSView {

    override var isFlipped: Bool {
        return true
    }

}

class View: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var wantsUpdateLayer: Bool {
        return true
    }

    override func updateLayer() {
        layer?.backgroundColor = backgroundColor?.cgColor
    }

    var backgroundColor: NSColor? {
        didSet {
            self.setNeedsDisplay(bounds)
        }
    }

}

