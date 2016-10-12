//
//  ViewController.swift
//  Concord
//
//  Created by Richard Wei on 10/11/16.
//  Copyright © 2016 Richard Wei. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var pathField: NSTextField!
    @IBOutlet var textView: NSTextView!

    var corpora: [Corpus] = []

    var text: String = "" {
        didSet {
            textView.string = text
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.font = NSFont(name: "Helvetica", size: 16)
        text = "Click \"Open\"\n"
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func openFiles(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.beginSheetModal(for: NSApp.mainWindow!) { result in
            guard result == NSFileHandlingPanelOKButton else { return }
            self.text.removeAll()
            self.corpora.removeAll()
            for url in openPanel.urls {
                if let corpus = Corpus(url: url, encoding: .utf8) {
                    self.corpora.append(corpus)
                    self.text.append("Loaded \(url)\n")
                }
            }
        }
    }

    @IBAction func showTextLengths(_ sender: Any) {
        
    }

    @IBAction func showVocabularyDiversity(_ sender: Any) {

    }

    @IBAction func showSentenceLengths(_ sender: Any) {
        
    }

    @IBAction func showWordLengths(_ sender: Any) {

    }

    @IBAction func showTop20Words(_ sender: Any) {

    }

    @IBAction func showDistribution(_ sender: Any) {

    }
    
    @IBAction func showFrequentWords(_ sender: Any) {
        
    }
    
    @IBAction func showTop20Favored(_ sender: Any) {
        
    }
}

