import Foundation

public let ErrorDomain: String! = "SwiftyJSONErrorDomain"

public let ErrorUnsupportedType: Int! = 999
public let ErrorIndexOutOfBounds: Int! = 900
public let ErrorWrongType: Int! = 901
public let ErrorNotExist: Int! = 500

public enum Type :Int{
    
    case number
    case string
    case bool
    case array
    case dictionary
    case null
    case unknown
}

public struct JSON {
    
    public init(data:Data, options opt: JSONSerialization.ReadingOptions = .allowFragments, error: NSErrorPointer? = nil) {
        if let object: AnyObject = JSONSerialization.JSONObjectWithData(data, options: opt, error: error) {
            self.init(object)
        } else {
            self.init(NSNull())
        }
    }
    
    public init(_ object: AnyObject) {
        self.object = object
    }
    
    fileprivate var _object: AnyObject = NSNull()
    
    fileprivate var _type: Type = .null
    
    fileprivate var _error: NSError?
    
    public var object: AnyObject {
        get {
            return _object
        }
        set {
            _object = newValue
            switch newValue {
            case let number as NSNumber:
                if number.isBool {
                    _type = .bool
                } else {
                    _type = .number
                }
            case let string as NSString:
                _type = .string
            case let null as NSNull:
                _type = .null
            case let array as [AnyObject]:
                _type = .array
            case let dictionary as [String : AnyObject]:
                _type = .dictionary
            default:
                _type = .unknown
                _object = NSNull()
                _error = NSError(domain: ErrorDomain, code: ErrorUnsupportedType, userInfo: [NSLocalizedDescriptionKey: "It is a unsupported type"])
            }
        }
    }
    
    public var type: Type { get { return _type } }
    
    public var error: NSError? { get { return self._error } }
    
    public static var nullJSON: JSON { get { return JSON(NSNull()) } }
    
}

extension JSON: Sequence{
    
    public var isEmpty: Bool {
        get {
            switch self.type {
            case .array:
                return (self.object as! [AnyObject]).isEmpty
            case .dictionary:
                return (self.object as! [String : AnyObject]).isEmpty
            default:
                return false
            }
        }
    }
    
    public var count: Int {
        get {
            switch self.type {
            case .array:
                return self.arrayValue.count
            case .dictionary:
                return self.dictionaryValue.count
            default:
                return 0
            }
        }
    }
    
    public func generate() -> GeneratorOf <(String, JSON)> {
        switch self.type {
        case .array:
            let array_ = object as! [AnyObject]
            var generate_ = array_.makeIterator()
            var index_: Int = 0
            return GeneratorOf<(String, JSON)> {
                if let element_: AnyObject = generate_.next() {
                    return ("\(index_++)", JSON(element_))
                } else {
                    return nil
                }
            }
        case .dictionary:
            let dictionary_ = object as! [String : AnyObject]
            var generate_ = dictionary_.makeIterator()
            return GeneratorOf<(String, JSON)> {
                if let (key_: String, value_: AnyObject) = generate_.next() {
                    return (key_, JSON(value_))
                } else {
                    return nil
                }
            }
        default:
            return GeneratorOf<(String, JSON)> {
                return nil
            }
        }
    }
}

public protocol SubscriptType {}

extension Int: SubscriptType {}

extension String: SubscriptType {}

extension JSON {
    
    fileprivate subscript(index: Int) -> JSON {
        get {
            
            if self.type != .array {
                var errorResult_ = JSON.nullJSON
                errorResult_._error = self._error ?? NSError(domain: ErrorDomain, code: ErrorWrongType, userInfo: [NSLocalizedDescriptionKey: "Array[\(index)] failure, It is not an array"])
                return errorResult_
            }
            
            let array_ = self.object as! [AnyObject]
            
            if index >= 0 && index < array_.count {
                return JSON(array_[index])
            }
            
            var errorResult_ = JSON.nullJSON
            errorResult_._error = NSError(domain: ErrorDomain, code:ErrorIndexOutOfBounds , userInfo: [NSLocalizedDescriptionKey: "Array[\(index)] is out of bounds"])
            return errorResult_
        }
        set {
            if self.type == .array {
                var array_ = self.object as! [AnyObject]
                if array_.count > index {
                    array_[index] = newValue.object
                    self.object = array_ as AnyObject
                }
            }
        }
    }
    
    fileprivate subscript(key: String) -> JSON {
        get {
            var returnJSON = JSON.nullJSON
            if self.type == .dictionary {
                if let object: AnyObject = self.object[key] {
                    returnJSON = JSON(object)
                } else {
                    returnJSON._error = NSError(domain: ErrorDomain, code: ErrorNotExist, userInfo: [NSLocalizedDescriptionKey: "Dictionary[\"\(key)\"] does not exist"])
                }
            } else {
                returnJSON._error = self._error ?? NSError(domain: ErrorDomain, code: ErrorWrongType, userInfo: [NSLocalizedDescriptionKey: "Dictionary[\"\(key)\"] failure, It is not an dictionary"])
            }
            return returnJSON
        }
        set {
            if self.type == .dictionary {
                var dictionary_ = self.object as! [String : AnyObject]
                dictionary_[key] = newValue.object
                self.object = dictionary_ as AnyObject
            }
        }
    }
    
    fileprivate subscript(sub: SubscriptType) -> JSON {
        get {
            if sub is String {
                return self[key:sub as! String]
            } else {
                return self[index:sub as! Int]
            }
        }
        set {
            if sub is String {
                self[key:sub as! String] = newValue
            } else {
                self[index:sub as! Int] = newValue
            }
        }
    }
    
    public subscript(path: [SubscriptType]) -> JSON {
        get {
            if path.count == 0 {
                return JSON.nullJSON
            }
            
            var next = self
            for sub in path {
                next = next[sub:sub]
            }
            return next
        }
        set {
            
            switch path.count {
            case 0: return
            case 1: self[sub:path[0]] = newValue
            default:
                var last = newValue
                var newPath = path
                newPath.removeLast()
                for sub in path.reversed() {
                    var previousLast = self[newPath]
                    previousLast[sub:sub] = last
                    last = previousLast
                    if newPath.count <= 1 {
                        break
                    }
                    newPath.removeLast()
                }
                self[sub:newPath[0]] = last
            }
        }
    }
    
    public subscript(path: SubscriptType...) -> JSON {
        get {
            return self[path]
        }
        set {
            self[path] = newValue
        }
    }
}

extension JSON: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value as AnyObject)
    }
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value as AnyObject)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value as AnyObject)
    }
}

extension JSON: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value as AnyObject)
    }
}

extension JSON: ExpressibleByBooleanLiteral {
    
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value as AnyObject)
    }
}

extension JSON: ExpressibleByFloatLiteral {
    
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value as AnyObject)
    }
}

extension JSON: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (String, AnyObject)...) {
        var dictionary_ = [String : AnyObject]()
        for (key_, value) in elements {
            dictionary_[key_] = value
        }
        self.init(dictionary_ as AnyObject)
    }
}

extension JSON: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: AnyObject...) {
        self.init(elements as AnyObject)
    }
}

extension JSON: ExpressibleByNilLiteral {
    
    public init(nilLiteral: ()) {
        self.init(NSNull())
    }
}

extension JSON: RawRepresentable {
    
    public init?(rawValue: AnyObject) {
        if JSON(rawValue).type == .unknown {
            return nil
        } else {
            self.init(rawValue)
        }
    }
    
    public var rawValue: AnyObject {
        return self.object
    }
    
    public func rawData(options opt: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions(0), error: NSErrorPointer? = nil) -> Data? {
        return JSONSerialization.dataWithJSONObject(self.object, options: opt, error:error)
    }
    
    public func rawString(_ encoding: UInt = String.Encoding.utf8, options opt: JSONSerialization.WritingOptions = .prettyPrinted) -> String? {
        switch self.type {
        case .array, .dictionary:
            if let data = self.rawData(options: opt) {
                var errors : NSErrorPointer? = nil
                
                return NSString(data: data, encoding: encoding) as? String
                
            } else {
                return nil
            }
        case .string:
            return (self.object as! String)
        case .number:
            return (self.object as! NSNumber).stringValue
        case .bool:
            return (self.object as! Bool).description
        case .null:
            return "null"
        default:
            return nil
        }
    }
}

extension JSON: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        if let string = self.rawString(options:.prettyPrinted) {
            return string
        } else {
            return "unknown"
        }
    }
    
    public var debugDescription: String {
        return description
    }
}

extension JSON {
    
    public var array: [JSON]? {
        get {
            if self.type == .array {
                return map(self.object as! [AnyObject]){ JSON($0) }
            } else {
                return nil
            }
        }
    }
    
    public var arrayValue: [JSON] {
        get {
            return self.array ?? []
        }
    }
    
    public var arrayObject: [AnyObject]? {
        get {
            switch self.type {
            case .array:
                return self.object as? [AnyObject]
            default:
                return nil
            }
        }
        set {
            if newValue != nil {
                self.object = NSMutableArray(array: newValue!, copyItems: true)
            } else {
                self.object = NSNull()
            }
        }
    }
}

extension JSON {
    
    fileprivate func _map<Key:Hashable ,Value, NewValue>(_ source: [Key: Value], transform: (Value) -> NewValue) -> [Key: NewValue] {
        var result = [Key: NewValue](minimumCapacity:source.count)
        for (key,value) in source {
            result[key] = transform(value)
        }
        return result
    }
    
    public var dictionary: [String : JSON]? {
        get {
            if self.type == .dictionary {
                return _map(self.object as! [String : AnyObject]){ JSON($0) }
            } else {
                return nil
            }
        }
    }
    
    public var dictionaryValue: [String : JSON] {
        get {
            return self.dictionary ?? [:]
        }
    }
    
    public var dictionaryObject: [String : AnyObject]? {
        get {
            switch self.type {
            case .dictionary:
                return self.object as? [String : AnyObject]
            default:
                return nil
            }
        }
        set {
            if newValue != nil {
                self.object = NSMutableDictionary(dictionary: newValue!, copyItems: true)
            } else {
                self.object = NSNull()
            }
        }
    }
}

extension JSON {
    
    public var bool: Bool? {
        get {
            switch self.type {
            case .bool:
                return self.object.boolValue
            default:
                return nil
            }
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as Bool)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var boolValue: Bool {
        get {
            switch self.type {
            case .bool, .number, .string:
                return self.object.boolValue
            default:
                return false
            }
        }
        set {
            self.object = NSNumber(value: newValue as Bool)
        }
    }
}

extension JSON {
    
    public var string: String? {
        get {
            switch self.type {
            case .string:
                return self.object as? String
            default:
                return nil
            }
        }
        set {
            if newValue != nil {
                self.object = NSString(string:newValue!)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var stringValue: String {
        get {
            switch self.type {
            case .string:
                return self.object as! String
            case .number:
                return self.object.stringValue
            case .bool:
                return (self.object as! Bool).description
            default:
                return ""
            }
        }
        set {
            self.object = NSString(string:newValue)
        }
    }
}

extension JSON {
    
    public var number: NSNumber? {
        get {
            switch self.type {
            case .number, .bool:
                return self.object as? NSNumber
            default:
                return nil
            }
        }
        set {
            self.object = newValue?.copy() as AnyObject ?? NSNull()
        }
    }
    
    public var numberValue: NSNumber {
        get {
            switch self.type {
            case .string:
                let scanner = Scanner(string: self.object as! String)
                if scanner.scanDouble(nil){
                    if (scanner.isAtEnd) {
                        return NSNumber(value: (self.object as! NSString).doubleValue as Double)
                    }
                }
                return NSNumber(value: 0.0 as Double)
            case .number, .bool:
                return self.object as! NSNumber
            default:
                return NSNumber(value: 0.0 as Double)
            }
        }
        set {
            self.object = newValue.copy() as AnyObject
        }
    }
}

extension JSON {
    
    public var null: NSNull? {
        get {
            switch self.type {
            case .null:
                return NSNull()
            default:
                return nil
            }
        }
        set {
            self.object = NSNull()
        }
    }
}

extension JSON {
    
    public var URL: Foundation.URL? {
        get {
            switch self.type {
            case .string:
                if let encodedString_ = self.object.addingPercentEscapes(using: String.Encoding.utf8.rawValue) {
                    return Foundation.URL(string: encodedString_)
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
        set {
            self.object = newValue?.absoluteString as AnyObject ?? NSNull()
        }
    }
}

extension JSON {
    
    public var double: Double? {
        get {
            return self.number?.doubleValue
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as Double)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var doubleValue: Double {
        get {
            return self.numberValue.doubleValue
        }
        set {
            self.object = NSNumber(value: newValue as Double)
        }
    }
    
    public var float: Float? {
        get {
            return self.number?.floatValue
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as Float)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var floatValue: Float {
        get {
            return self.numberValue.floatValue
        }
        set {
            self.object = NSNumber(value: newValue as Float)
        }
    }
    
    public var int: Int? {
        get {
            return self.number?.intValue
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as Int)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var intValue: Int {
        get {
            return self.numberValue.intValue
        }
        set {
            self.object = NSNumber(value: newValue as Int)
        }
    }
    
    public var uInt: UInt? {
        get {
            return self.number?.uintValue
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as UInt)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var uIntValue: UInt {
        get {
            return self.numberValue.uintValue
        }
        set {
            self.object = NSNumber(value: newValue as UInt)
        }
    }
    
    public var int8: Int8? {
        get {
            return self.number?.int8Value
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as Int8)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var int8Value: Int8 {
        get {
            return self.numberValue.int8Value
        }
        set {
            self.object = NSNumber(value: newValue as Int8)
        }
    }
    
    public var uInt8: UInt8? {
        get {
            return self.number?.uint8Value
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as UInt8)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var uInt8Value: UInt8 {
        get {
            return self.numberValue.uint8Value
        }
        set {
            self.object = NSNumber(value: newValue as UInt8)
        }
    }
    
    public var int16: Int16? {
        get {
            return self.number?.int16Value
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as Int16)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var int16Value: Int16 {
        get {
            return self.numberValue.int16Value
        }
        set {
            self.object = NSNumber(value: newValue as Int16)
        }
    }
    
    public var uInt16: UInt16? {
        get {
            return self.number?.uint16Value
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as UInt16)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var uInt16Value: UInt16 {
        get {
            return self.numberValue.uint16Value
        }
        set {
            self.object = NSNumber(value: newValue as UInt16)
        }
    }
    
    public var int32: Int32? {
        get {
            return self.number?.int32Value
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as Int32)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var int32Value: Int32 {
        get {
            return self.numberValue.int32Value
        }
        set {
            self.object = NSNumber(value: newValue as Int32)
        }
    }
    
    public var uInt32: UInt32? {
        get {
            return self.number?.uint32Value
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as UInt32)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var uInt32Value: UInt32 {
        get {
            return self.numberValue.uint32Value
        }
        set {
            self.object = NSNumber(value: newValue as UInt32)
        }
    }
    
    public var int64: Int64? {
        get {
            return self.number?.int64Value
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as Int64)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var int64Value: Int64 {
        get {
            return self.numberValue.int64Value
        }
        set {
            self.object = NSNumber(value: newValue as Int64)
        }
    }
    
    public var uInt64: UInt64? {
        get {
            return self.number?.uint64Value
        }
        set {
            if newValue != nil {
                self.object = NSNumber(value: newValue! as UInt64)
            } else {
                self.object =  NSNull()
            }
        }
    }
    
    public var uInt64Value: UInt64 {
        get {
            return self.numberValue.uint64Value
        }
        set {
            self.object = NSNumber(value: newValue as UInt64)
        }
    }
}

extension JSON: Comparable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.number, .number):
        return (lhs.object as! NSNumber) == (rhs.object as! NSNumber)
    case (.string, .string):
        return (lhs.object as! String) == (rhs.object as! String)
    case (.bool, .bool):
        return (lhs.object as! Bool) == (rhs.object as! Bool)
    case (.array, .array):
        return (lhs.object as! NSArray) == (rhs.object as! NSArray)
    case (.dictionary, .dictionary):
        return (lhs.object as! NSDictionary) == (rhs.object as! NSDictionary)
    case (.null, .null):
        return true
    default:
        return false
    }
}

public func <=(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.number, .number):
        return (lhs.object as! NSNumber) <= (rhs.object as! NSNumber)
    case (.string, .string):
        return (lhs.object as! String) <= (rhs.object as! String)
    case (.bool, .bool):
        return (lhs.object as! Bool) == (rhs.object as! Bool)
    case (.array, .array):
        return (lhs.object as! NSArray) == (rhs.object as! NSArray)
    case (.dictionary, .dictionary):
        return (lhs.object as! NSDictionary) == (rhs.object as! NSDictionary)
    case (.null, .null):
        return true
    default:
        return false
    }
}

public func >=(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.number, .number):
        return (lhs.object as! NSNumber) >= (rhs.object as! NSNumber)
    case (.string, .string):
        return (lhs.object as! String) >= (rhs.object as! String)
    case (.bool, .bool):
        return (lhs.object as! Bool) == (rhs.object as! Bool)
    case (.array, .array):
        return (lhs.object as! NSArray) == (rhs.object as! NSArray)
    case (.dictionary, .dictionary):
        return (lhs.object as! NSDictionary) == (rhs.object as! NSDictionary)
    case (.null, .null):
        return true
    default:
        return false
    }
}

public func >(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.number, .number):
        return (lhs.object as! NSNumber) > (rhs.object as! NSNumber)
    case (.string, .string):
        return (lhs.object as! String) > (rhs.object as! String)
    default:
        return false
    }
}

public func <(lhs: JSON, rhs: JSON) -> Bool {
    
    switch (lhs.type, rhs.type) {
    case (.number, .number):
        return (lhs.object as! NSNumber) < (rhs.object as! NSNumber)
    case (.string, .string):
        return (lhs.object as! String) < (rhs.object as! String)
    default:
        return false
    }
}

private let trueNumber = NSNumber(value: true as Bool)
private let falseNumber = NSNumber(value: false as Bool)
private let trueObjCType = String(cString: trueNumber.objCType)
private let falseObjCType = String(cString: falseNumber.objCType)

extension NSNumber: Comparable {
    var isBool:Bool {
        get {
            let objCType = String(cString: self.objCType)
            if (self.compare(trueNumber) == ComparisonResult.orderedSame &&  objCType == trueObjCType) ||  (self.compare(falseNumber) == ComparisonResult.orderedSame && objCType == falseObjCType){
                return true
            } else {
                return false
            }
        }
    }
}

public func ==(lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == ComparisonResult.orderedSame
    }
}

public func !=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    return !(lhs == rhs)
}

public func <(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == ComparisonResult.orderedAscending
    }
}

public func >(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == ComparisonResult.orderedDescending
    }
}

public func <=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) != ComparisonResult.orderedDescending
    }
}

public func >=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) != ComparisonResult.orderedAscending
    }
}

@available(*, unavailable, renamed: "JSON")
public typealias JSONValue = JSON

extension JSON {
    
    @available(*, unavailable, message: "use 'init(_ object:AnyObject)' instead")
    public init(object: AnyObject) {
        self = JSON(object)
    }
    
    @available(*, unavailable, renamed: "dictionaryObject")
    public var dictionaryObjects: [String : AnyObject]? {
        get { return self.dictionaryObject }
    }
    
    @available(*, unavailable, renamed: "arrayObject")
    public var arrayObjects: [AnyObject]? {
        get { return self.arrayObject }
    }
    
    @available(*, unavailable, renamed: "int8")
    public var char: Int8? {
        get {
            return self.number?.int8Value
        }
    }
    
    @available(*, unavailable, renamed: "int8Value")
    public var charValue: Int8 {
        get {
            return self.numberValue.int8Value
        }
    }
    
    @available(*, unavailable, renamed: "uInt8")
    public var unsignedChar: UInt8? {
        get{
            return self.number?.uint8Value
        }
    }
    
    @available(*, unavailable, renamed: "uInt8Value")
    public var unsignedCharValue: UInt8 {
        get{
            return self.numberValue.uint8Value
        }
    }
    
    @available(*, unavailable, renamed: "int16")
    public var short: Int16? {
        get{
            return self.number?.int16Value
        }
    }
    
    @available(*, unavailable, renamed: "int16Value")
    public var shortValue: Int16 {
        get{
            return self.numberValue.int16Value
        }
    }
    
    @available(*, unavailable, renamed: "uInt16")
    public var unsignedShort: UInt16? {
        get{
            return self.number?.uint16Value
        }
    }
    
    @available(*, unavailable, renamed: "uInt16Value")
    public var unsignedShortValue: UInt16 {
        get{
            return self.numberValue.uint16Value
        }
    }
    
    @available(*, unavailable, renamed: "int")
    public var long: Int? {
        get{
            return self.number?.intValue
        }
    }
    
    @available(*, unavailable, renamed: "intValue")
    public var longValue: Int {
        get{
            return self.numberValue.intValue
        }
    }
    
    @available(*, unavailable, renamed: "uInt")
    public var unsignedLong: UInt? {
        get{
            return self.number?.uintValue
        }
    }
    
    @available(*, unavailable, renamed: "uIntValue")
    public var unsignedLongValue: UInt {
        get{
            return self.numberValue.uintValue
        }
    }
    
    @available(*, unavailable, renamed: "int64")
    public var longLong: Int64? {
        get{
            return self.number?.int64Value
        }
    }
    
    @available(*, unavailable, renamed: "int64Value")
    public var longLongValue: Int64 {
        get{
            return self.numberValue.int64Value
        }
    }
    
    @available(*, unavailable, renamed: "uInt64")
    public var unsignedLongLong: UInt64? {
        get{
            return self.number?.uint64Value
        }
    }
    
    @available(*, unavailable, renamed: "uInt64Value")
    public var unsignedLongLongValue: UInt64 {
        get{
            return self.numberValue.uint64Value
        }
    }
    
    @available(*, unavailable, renamed: "int")
    public var integer: Int? {
        get {
            return self.number?.intValue
        }
    }
    
    @available(*, unavailable, renamed: "intValue")
    public var integerValue: Int {
        get {
            return self.numberValue.intValue
        }
    }
    
    @available(*, unavailable, renamed: "uInt")
    public var unsignedInteger: Int? {
        get {
            return self.number?.uintValue
        }
    }
    
    @available(*, unavailable, renamed: "uIntValue")
    public var unsignedIntegerValue: Int {
        get {
            return Int(self.numberValue.uintValue)
        }
    }
}
