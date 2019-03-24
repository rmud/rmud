import Foundation

extension AreaFormatParser {
    func scanNumber(validRange: ClosedRange<Int64>? = nil) throws {
        #if !os(Linux) && !os(Windows)
            // Coredumps on Linux
            assert(scanner.charactersToBeSkipped == FastCharacterSet.whitespaces)
        #endif
        
        guard let result = scanner.scanInt64() else {
            try throwError(.expectedNumber)
        }
        if let range = validRange {
            guard range.contains(result) else {
                throw AreaParseError(kind: .valueOutOfRange(validRange: range), scanner: scanner)
            }
        }
        let value = Value.number(result)
        guard currentEntity.add(name: currentFieldNameWithIndex, value: value) else {
            try throwError(.duplicateField)
        }
        if areasLog {
            log("\(currentFieldNameWithIndex): \(result)")
        }
    }
    
    func scanEnumeration() throws {
        #if !os(Linux) && !os(Windows)
            // Coredumps on Linux
            assert(scanner.charactersToBeSkipped == FastCharacterSet .whitespaces)
        #endif
        
        let value: Value
        if let number = scanner.scanInt64() {
            let namesByValue = definitions.enumerations.enumSpecsByAlias[currentLowercasedFieldName]?.namesByValue ?? [:]
            guard namesByValue[number] != nil else {
                throw AreaParseError(kind: .invalidEnumerationNumericValue(value: number, allowedValues: Array(namesByValue.values.sorted())), scanner: scanner)
            }
            value = Value.enumeration(number)
            if areasLog {
                log("\(currentFieldNameWithIndex): .\(number)")
            }
        } else if let word = scanWord() {
            let result = word.lowercased()
            let valuesByName = definitions.enumerations.enumSpecsByAlias[currentLowercasedFieldName]?.valuesByName ?? [:]
            guard let number = valuesByName[result] else {
                throw AreaParseError(kind: .invalidEnumerationStringValue(value: result, allowedValues: Array(valuesByName.keys.sorted())), scanner: scanner)
            }
            value = Value.enumeration(number)
            if areasLog {
                log("\(currentFieldNameWithIndex): .\(number)")
            }
        } else {
            try throwError(.expectedEnumerationValue)
        }
        
        guard currentEntity.add(name: currentFieldNameWithIndex, value: value) else {
            try throwError(.duplicateField)
        }
    }
    
    func scanFlags() throws {
        #if !os(Linux) && !os(Windows)
            // Coredumps on Linux
            assert(scanner.charactersToBeSkipped == FastCharacterSet.whitespaces)
        #endif
        
        let valuesByName = definitions.enumerations.enumSpecsByAlias[currentLowercasedFieldName]?.valuesByName
        
        var result: Int64
        if let previousValue = currentEntity.value(named: currentFieldNameWithIndex, touch: false),
            case .flags(let previousResult) = previousValue {
            result = previousResult
        } else {
            result = 0
        }
        
        while true {
            if let flags = scanner.scanInt64() {
                // FIXME: validate?
                //let flags: Int64 = bitNumber <= 0 ? 0 : 1 << (bitNumber - 1)
                guard (result & flags) == 0 else {
                    try throwError(.duplicateValue)
                }
                result |= flags
            } else if let word = scanWord()?.lowercased() {
                guard let valuesByName = valuesByName else {
                    // List without associated enumeration names
                    try throwError(.expectedNumber)
                }
                guard let bitNumber = valuesByName[word] else {
                    throw AreaParseError(kind: .invalidEnumerationStringValue(value: word, allowedValues: Array(valuesByName.keys.sorted())), scanner: scanner)
                }
                let flags: Int64 = bitNumber <= 0 ? 0 : 1 << (bitNumber - 1)
                guard (result & flags) == 0 else {
                    try throwError(.duplicateValue)
                }
                result |= flags
            } else {
                break
            }
        }
        
        let value = Value.flags(result)
        currentEntity.replace(name: currentFieldNameWithIndex, value: value)
        if areasLog {
            log("\(currentFieldNameWithIndex): \(result)")
        }
    }
    
    func scanList() throws {
        #if !os(Linux) && !os(Windows)
            // Coredumps on Linux
            assert(scanner.charactersToBeSkipped == FastCharacterSet.whitespaces)
        #endif
        
        let valuesByName = definitions.enumerations.enumSpecsByAlias[currentLowercasedFieldName]?.valuesByName
        
        var result: Set<Int64>
        if let previousValue = currentEntity.value(named: currentFieldNameWithIndex, touch: false),
            case .list(let previousResult) = previousValue {
            result = previousResult
        } else {
            result = Set<Int64>()
        }
        
        while true {
            if let number = scanner.scanInt64() {
                // FIXME: validate?
                guard result.insert(number).inserted else {
                    try throwError(.duplicateValue)
                }
            } else if let word = scanWord()?.lowercased() {
                guard let valuesByName = valuesByName else {
                    // List without associated enumeration names
                    try throwError(.expectedNumber)
                }
                guard let number = valuesByName[word] else {
                    throw AreaParseError(kind: .invalidEnumerationStringValue(value: word, allowedValues: Array(valuesByName.keys.sorted())), scanner: scanner)
                }
                guard result.insert(number).inserted else {
                    try throwError(.duplicateValue)
                }
            } else {
                break
            }
        }
        
        let value = Value.list(result)
        currentEntity.replace(name: currentFieldNameWithIndex, value:  value)
        if areasLog {
            log("\(currentFieldNameWithIndex): \(result)")
        }
    }
    
    func scanDictionary() throws {
        #if !os(Linux) && !os(Windows)
            // Coredumps on Linux
            assert(scanner.charactersToBeSkipped == FastCharacterSet.whitespaces)
        #endif
        
        let valuesByName = definitions.enumerations.enumSpecsByAlias[currentLowercasedFieldName]?.valuesByName
        
        var result: [Int64: Int64?]
        if let previousValue = currentEntity.value(named: currentFieldNameWithIndex, touch: false),
            case .dictionary(let previousResult) = previousValue {
            result = previousResult
        } else {
            result = [Int64: Int64?]()
        }
        
        while true {
            if let key = scanner.scanInt64() {
                // FIXME: validate?
                guard result[key] == nil else {
                    try throwError(.duplicateValue)
                }
                if scanner.skipByte(T.equals) {
                    guard let value = scanner.scanInt64() else {
                        try throwError(.expectedNumber)
                    }
                    result[key] = value
                } else {
                    result[key] = nil as Int64?
                }
            } else if let word = scanWord()?.lowercased() {
                guard let valuesByName = valuesByName else {
                    // List without associated enumeration names
                    try throwError(.expectedNumber)
                }
                guard let key = valuesByName[word] else {
                    throw AreaParseError(kind: .invalidEnumerationStringValue(value: word, allowedValues: Array(valuesByName.keys.sorted())), scanner: scanner)
                }
                guard result[key] == nil else {
                    try throwError(.duplicateValue)
                }
                if scanner.skipByte(T.equals) {
                    guard let value = scanner.scanInt64() else {
                        try throwError(.expectedNumber)
                    }
                    result[key] = value
                } else {
                    result[key] = nil as Int64?
                }
            } else {
                break
            }
        }
        
        let value = Value.dictionary(result)
        currentEntity.replace(name: currentFieldNameWithIndex, value: value)
        if areasLog {
            log("\(currentFieldNameWithIndex): \(result)")
        }
    }
    
    func scanLine() throws {
        #if !os(Linux) && !os(Windows)
            assert(scanner.charactersToBeSkipped == FastCharacterSet.whitespaces)
        #endif
        
        guard let result = try scanQuotedText() else {
            try throwError(.expectedDoubleQuote)
        }
        //if currentFieldInfo?.flags.contains(.automorph) ?? false {
        //    result = morpher.convertToSimpleAreaFormat(text: result,
        //        animateByDefault: animateByDefault)
        //}
        let value = Value.line(result)
        if currentEntity.value(named: currentFieldNameWithIndex, touch: false) != nil {
            try throwError(.duplicateField)
        }
        currentEntity.replace(name: currentFieldNameWithIndex, value: value)
        if areasLog {
            log("\(currentFieldNameWithIndex): \(result)")
        }
    }
    
    func scanLongText() throws {
        #if !os(Linux) && !os(Windows)
            assert(scanner.charactersToBeSkipped == FastCharacterSet.whitespaces)
        #endif
        
        guard let firstLine = try scanQuotedText() else {
            try throwError(.expectedDoubleQuote)
        }
        var result = [firstLine]
        while true {
            #if !os(Linux) && !os(Windows)
                assert(scanner.charactersToBeSkipped == FastCharacterSet.whitespaces)
            #endif
            var expectedDoubleQuoteError = false
            try scanner.skipping(FastCharacterSet.whitespacesAndNewlines) {
                guard let nextLine = try scanQuotedText() else {
                    // It's normal to not have continuation lines
                    expectedDoubleQuoteError = true
                    return
                }
                result.append(nextLine)
                try skipComments()
            }
            guard !expectedDoubleQuoteError else {
                break
            }
        }
        //if currentFieldInfo?.flags.contains(.automorph) ?? false {
        //    result = result.map {
        //        morpher.convertToSimpleAreaFormat(text: $0, animateByDefault: animateByDefault)
        //    }
        //}
        let value = Value.longText(result)
        if currentEntity.value(named: currentFieldNameWithIndex, touch: false) != nil {
            try throwError(.duplicateField)
        }
        currentEntity.replace(name: currentFieldNameWithIndex, value:  value)
        if areasLog {
            log("\(currentFieldNameWithIndex): \(result)")
        }
    }
    
    func scanDice() throws {
        #if !os(Linux) && !os(Windows)
            assert(scanner.charactersToBeSkipped == FastCharacterSet.whitespaces)
        #endif
        
        guard let v1 = scanner.scanInt64() else {
            try throwError(.expectedNumber)
        }
        
        let hasK = scanner.skipByte(T.dBig) || scanner.skipByte(T.dSmall) ||
            scanner.skipBytes(T.ruKBig) || scanner.skipBytes(T.ruKSmall)
        
        let v2OrNil = scanner.scanInt64()
        
        let hasPlus = scanner.skipByte(T.plus)
        
        let v3OrNil = scanner.scanInt64()
        
        if hasK && v2OrNil == nil {
            try throwError(.syntaxError)
        }
        if hasPlus && (v2OrNil == nil || v3OrNil == nil) {
            try throwError(.syntaxError)
        }
        
        let value: Value
        if v2OrNil == nil && v3OrNil == nil {
            value = .dice(Dice<Int64>(number: 0, size: 0, add: v1))
            if areasLog {
                log("\(currentFieldNameWithIndex): 0d0+\(v1)")
            }
        } else {
            value = .dice(
                Dice<Int64>(number: v1, size: (v2OrNil ?? 0), add: (v3OrNil ?? 0)))
            if areasLog {
                log("\(currentFieldNameWithIndex): \(v1)d\(v2OrNil ?? 0)+\(v3OrNil ?? 0)")
            }
        }
        
        if currentEntity.value(named: currentFieldNameWithIndex, touch: false) != nil {
            try throwError(.duplicateField)
        }
        currentEntity.replace(name: currentFieldNameWithIndex, value:  value)
    }
}
