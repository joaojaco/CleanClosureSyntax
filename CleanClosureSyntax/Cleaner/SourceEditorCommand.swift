//
//  SourceEditorCommand.swift
//  Cleaner
//
//  Created by João Jacó S. Abreu on 27/02/21.
//

import Foundation
import XcodeKit

extension NSString {
    // Remove the given characters in the range
    func remove(characters: [Character], in range: NSRange) -> NSString {
        var cleanString = self
        for char in characters {
            cleanString = cleanString.replacingOccurrences(of: String(char), with: "", options: .literal, range: range) as NSString
        }
        return cleanString
    }
}

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        var updatedLineIndexes = [Int]()
        
        // 1. Find lines that contain a closure syntax
        for lineIndex in 0 ..< invocation.buffer.lines.count {
            let line = invocation.buffer.lines[lineIndex] as! NSString
            do {
                let regex = try NSRegularExpression(pattern: "\\{.*\\(.+\\).+in", options: .caseInsensitive)
                let range = NSRange(0 ..< line.length)
                let results = regex.matches(in: line as String, options: .reportProgress, range: range)
                // 2. When a closure is found, clean up its syntax
                _ = results.map { result in
                    let cleanLine = line.remove(characters: ["(", ")"], in: result.range)
                    updatedLineIndexes.append(lineIndex)
                    invocation.buffer.lines[lineIndex] = cleanLine
                }
            } catch {
                completionHandler(error as NSError)
            }
        }
        
        // 3. If at least a line was changed, create an array of changes and pass it to the buffer selections
        if !updatedLineIndexes.isEmpty {
            let updatedSelections: [XCSourceTextRange] = updatedLineIndexes.map { lineIndex in
                let lineSelection = XCSourceTextRange()
                lineSelection.start = XCSourceTextPosition(line: lineIndex, column: 0)
                lineSelection.end = XCSourceTextPosition(line: lineIndex, column: 0)
                return lineSelection
            }
            invocation.buffer.selections.setArray(updatedSelections)
        }
        completionHandler(nil)
    }
    
}
