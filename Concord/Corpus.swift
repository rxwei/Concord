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

    private var frequencies: [String.UnicodeScalarView : Int] = [:]

    private var frequentWords: [Int : [String]] = [:]

    public private(set) var wordCount: Int = 0

    public private(set) var typeCount: Int = 0

    public var diversity: Float {
        return Float(typeCount) / Float(wordCount)
    }
    
    public func frequency(of word: String) -> Int {
        return frequencies[word.unicodeScalars] ?? 0
    }
    
    public func words(withFrequency frequency: Int) -> [String] {
        return frequentWords[frequency] ?? []
    }
    
    public init<Text: RandomAccessCollection>(tokenizedText: Text)
        where Text.Iterator.Element == String,
              Text.IndexDistance == Int, Text.Index == Int
    {
        for i in 0..<tokenizedText.endIndex {
            let token = tokenizedText[i].unicodeScalars
            wordCount += 1
            if self.frequencies.keys.contains(token) {
                self.frequencies[token] = 1 + (frequencies[token] ?? 0)
            }
            else {
                self.frequencies[token] = 1
                typeCount += 1
            }
        }
        
        for (token, freq) in frequencies {
            let word = String(token)
            
            if frequentWords.keys.contains(freq) {
                frequentWords[freq]!.append(word)
            }
            else {
                frequentWords[freq] = [word]
            }
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
        return (0..<count).flatMap { i in
            self.vocabulary.words(withFrequency: i)
        }
    }

    public init?(fileHandle: FileHandle, encoding: String.Encoding = .utf8) {
        let data = fileHandle.readDataToEndOfFile()
        guard !data.isEmpty,
            let string = String(data: data, encoding: encoding)
            else { return nil }
        sentences = string.unicodeScalars.split(separator: "\n", omittingEmptySubsequences: true).map {
            $0.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
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
