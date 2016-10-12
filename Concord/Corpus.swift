//
//  Corpus.swift
//  Concord
//
//  Created by Richard Wei on 10/11/16.
//  Copyright © 2016 Richard Wei. All rights reserved.
//

import Foundation
import Dispatch

extension String.UnicodeScalarView : Hashable {

    public static func ==(lhs: String.UnicodeScalarView, rhs: String.UnicodeScalarView) -> Bool {
        return lhs.elementsEqual(rhs)
    }

    public var hashValue: Int {
        return reduce(0) { acc, x in
            31 &* acc.hashValue &+ x.hashValue
        }
    }

}

public struct Vocabulary {

    private var frequencyTable: [String.UnicodeScalarView : Int] = [:]
    private var frequentWordTable: [Int : [String]] = [:]
    private var rankTable: [Int : Int] = [:]

    public private(set) var wordCount = 0, typeCount = 0

    public var minFrequency: Int {
        return rankTable[0] ?? 0
    }

    public var maxFrequency: Int {
        return rankTable[1] ?? 0
    }

    public var diversity: Float {
        return Float(typeCount) / Float(wordCount)
    }

    public func frequency(of word: String) -> Int {
        return frequencyTable[word.unicodeScalars] ?? 0
    }

    public func frequency(withRank rank: Int) -> Int {
        return rankTable[rank] ?? 0
    }

    public var mostFrequentWords: [String] {
        return maxFrequency == 0 ? [] : frequentWordTable[maxFrequency]!
    }

    public var leastFrequentWords: [String] {
        return minFrequency == 0 ? [] : frequentWordTable[minFrequency]!
    }

    public func words(withFrequency frequency: Int) -> [String] {
        return frequentWordTable[frequency] ?? []
    }

    public var words: AnyCollection<String> {
        return AnyCollection(frequencyTable.keys.lazy.map{String($0)})
    }

    public init<Text: RandomAccessCollection>(tokenizedText: Text)
        where Text.Iterator.Element == String,
              Text.IndexDistance == Int, Text.Index == Int
    {
        for i in 0..<tokenizedText.endIndex {
            let token = tokenizedText[i].unicodeScalars
            wordCount += 1
            if self.frequencyTable.keys.contains(token) {
                self.frequencyTable[token] = 1 + (frequencyTable[token] ?? 0)
            }
            else {
                self.frequencyTable[token] = 1
                typeCount += 1
            }
        }
        
        for (token, freq) in frequencyTable {
            let word = String(token)
            if frequentWordTable.keys.contains(freq) {
                frequentWordTable[freq]!.append(word)
            }
            else {
                frequentWordTable[freq] = [word]
            }
        }

        for (i, freq) in frequentWordTable.keys.sorted(by: >).enumerated() {
            rankTable[i] = freq
        }
    }

}

public protocol Concordancible {
    var textLength: Int { get }
    func frequency(ofWord word: String) -> Int
    func topWords(_ count: Int) -> [String]
}

open class Corpus : Concordancible {

    open let sentences: [[String]]

    open var label: String?

    private static var punctuations: Set<UnicodeScalar> = [ ".", ",", "?", "!", ":", ";" ]

    public var text: AnyCollection<String> {
        return AnyCollection(sentences.lazy.flatMap{$0})
    }

    public let vocabulary: Vocabulary

    public func frequency(ofWord word: String) -> Int {
        return vocabulary.frequency(of: word)
    }

    public var textLength: Int {
        return vocabulary.wordCount
    }

    public var sentenceCount: Int {
        return sentences.count
    }

    public var vocabularyDiversity: Float {
        return vocabulary.diversity
    }

    public func topWords(_ count: Int) -> [String] {
        var words: [String] = []
        var i = 0
        while i < count {
            let freq = vocabulary.frequency(withRank: i)
            let freqWords = vocabulary.words(withFrequency: freq).prefix(count - i)
            words.append(contentsOf: freqWords)
            i += freqWords.count
        }
        return words
    }

    public init?(fileHandle: FileHandle, encoding: String.Encoding = .utf8) {
        let data = fileHandle.readDataToEndOfFile()
        guard !data.isEmpty,
            let string = String(data: data, encoding: encoding)
            else { return nil }
        sentences = string.unicodeScalars.split(
            whereSeparator: { $0 == "\n" || $0 == "\r" }
        ).flatMap {
            $0.isEmpty ? nil :
                $0.split(
                    separator: " ",
                    omittingEmptySubsequences: true
                ).flatMap {
                    let noPunc = Corpus.punctuations.contains($0.last!) ? $0.dropLast() : $0
                    return noPunc.isEmpty ? nil : String(noPunc)
                }
        }
        vocabulary = Vocabulary(tokenizedText: sentences.lazy.flatMap{$0})
    }

    public convenience init?(contentsOfFile filePath: String, encoding: String.Encoding = .utf8) {
        let path = Bundle.main.path(forResource: filePath, ofType: nil) ?? filePath
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return nil }
        self.init(fileHandle: fileHandle, encoding: encoding)
    }

    public convenience init?(url: URL, encoding: String.Encoding = .utf8) {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return nil }
        self.init(fileHandle: fileHandle, encoding: encoding)
    }
    
}
