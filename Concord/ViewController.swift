//
//  ViewController.swift
//  Concord
//
//  Created by Richard Wei on 10/11/16.
//  Copyright © 2016 Richard Wei. All rights reserved.
//

import Cocoa
import CorePlot

class ViewController: NSViewController {

    @IBOutlet var lookupField: NSTextField!
    @IBOutlet var textView: NSTextView!

    var corpora: [Corpus] = []

    var currentPlotData: [Int] = []

    var text: String = "" {
        didSet {
            textView.string = text
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.font = NSFont(name: "Helvetica", size: 16)
        self.output("Click \"Open\"")
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    private func clearOutput() {
        self.text.removeAll()
    }

    private func output(_ strings: String..., clearing: Bool = false) {
        self.text.append(strings.joined(separator: " ") + "\n")
    }

    @IBAction func openFiles(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.beginSheetModal(for: NSApp.mainWindow!) { result in
            guard result == NSFileHandlingPanelOKButton else { return }
            self.clearOutput()
            self.corpora.removeAll()
            guard !openPanel.urls.isEmpty else {
                self.output("No file selected")
                return
            }
            self.output("Reading corpora...")
            for url in openPanel.urls {
                DispatchQueue.global(qos: .utility).async {
                    guard let corpus = Corpus(url: url, encoding: .utf8) else {
                        self.output("Cannot open \(url)")
                        return
                    }
                    corpus.label = url.deletingPathExtension().lastPathComponent
                    DispatchQueue.main.sync {
                        self.corpora.append(corpus)
                        self.output("Loaded corpus \(corpus.label) from \(url)")
                    }
                }
            }
        }
    }

    @IBAction func lookup(_ field: NSTextField) {
        let word = field.attributedStringValue.string
        self.clearOutput()
        output("Frequency of \(word)")
        for corpus in corpora {
            output("\t\(corpus.label!): \(corpus.frequency(ofWord: word))")
        }
        field.resignFirstResponder()
    }

    @IBAction func showTextLengths(_ sender: Any) {
        self.clearOutput()
        output("Text length")
        for corpus in corpora {
            self.output("\t\(corpus.label!): \(corpus.textLength)")
        }
    }

    @IBAction func showVocabularyDiversity(_ sender: Any) {
        self.clearOutput()
        output("Vocabulary diversity")
        for corpus in corpora {
            self.output("\t\(corpus.label!): \(corpus.vocabularyDiversity)")
        }
    }

    @IBAction func showSentenceLengths(_ sender: Any) {
        self.clearOutput()
        output("Sentence lengths")
        for corpus in corpora {
            let avgSenLen = corpus.sentences.lazy.map{$0.count}.reduce(0, +)
                / corpus.sentenceCount
            output("\t\(corpus.label!):")
            output("\t\tSentence count: \(corpus.sentenceCount)")
            output("\t\tAverage sentence length: \(avgSenLen)")
        }
    }

    @IBAction func showWordLengths(_ sender: Any) {
        self.clearOutput()
        output("Average word lengths")
        for corpus in corpora {
            let avgWordLen = corpus.vocabulary.words.map{$0.characters.count}.reduce(0, +)
                / corpus.vocabulary.words.count
            self.output("\t\(corpus.label!): \(avgWordLen)")
        }
    }

    @IBAction func showTop20Words(_ sender: Any) {
        self.clearOutput()
        output("Top 20 words")
        for corpus in corpora {
            self.output("\t\(corpus.label!):\n\t\t" +
                "\(corpus.topWords(20).joined(separator: "\n\t\t"))")
        }
    }

    @IBAction func showDistribution(_ sender: Any) {
        self.clearOutput()
        output("Distribution plot")
        for corpus in corpora {
            currentPlotData = (0...30).map(corpus.vocabulary.frequency)
            output("\t\(corpus.label!):\n\t\t\(currentPlotData)")
//            let graph = CPTGraph()
//            let textStyle = CPTMutableTextStyle()
//            textStyle.fontName = "Helvetica"
//            textStyle.fontSize = 14.0
//            graph.titleTextStyle = textStyle
//            let plot = CPTPlot(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
//            plot.dataSource = self
//            graph.add(plot)
//            graph.reloadData()
//            let image = graph.imageOfLayer()
//            let attachmentCell = NSTextAttachmentCell(imageCell: image)
//            let attachment = NSTextAttachment()
//            attachment.attachmentCell = attachmentCell
//            let attrString = NSAttributedString(attachment: attachment)
//            textView.textStorage?.append(attrString)
        }
    }
    
    @IBAction func showFrequentWords(_ sender: Any) {
        self.clearOutput()
        output("Disjoint frequent words")

        let wordSets: [Set<String>] = corpora.map{Set($0.topWords(10))}
        var filteredSets: [Set<String>] = []
        for (i, set) in wordSets.enumerated() {
            var set = set
            wordSets.prefix(upTo: i).forEach { set.subtract($0) }
            wordSets.suffix(from: i+1).forEach { set.subtract($0) }
            filteredSets.append(set)
        }
        
        for (corpus, set) in zip(corpora, filteredSets) {
            self.output("\t\(corpus.label!):\n\t\t" +
                "\(set.joined(separator: "\n\t\t"))")
        }
    }

    @IBAction func showTop20Favored(_ sender: Any) {
        self.clearOutput()
        output("Top 20 favored words")

        let commonWordSets: [Set<String>] = corpora.map{Set($0.vocabulary.words)}
        var commonWords = commonWordSets[0]
        for set in commonWordSets.dropFirst() {
            commonWords.formIntersection(set)
        }
        
        for corpus in corpora {
            let favored = commonWords
                .map { ($0, corpus.frequency(ofWord: $0)) }
                .sorted { $0.1 > $1.1 }
                .map { $0.0 }
                .prefix(20)

            self.output("\t\(corpus.label!): \(favored.joined(separator: ", "))")
        }
    }

    /// Temp

    @IBAction func showPersonalPronouns(_ sender: Any) {
        self.clearOutput()
        output("Personal pronouns")

        let personalPronouns = [ "We", "I" ]
        for corpus in corpora {
            output("\t\(corpus.label!):")
            for p in personalPronouns {
                output("\t\t\(p): \(corpus.frequency(ofWord: p))")
            }
        }
    }
}

extension ViewController : CPTPlotDataSource {
    /** @brief @required The number of data points for the plot.
     *  @param plot The plot.
     *  @return The number of data points for the plot.
     **/
    public func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt(currentPlotData.count)
    }

    public func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        return currentPlotData[Int(idx)]
    }

    
}

