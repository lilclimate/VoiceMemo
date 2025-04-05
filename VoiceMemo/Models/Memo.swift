//
//  Memo.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import Foundation
import CoreData

struct Memo: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var audioURL: URL?
    var originalTranscription: String
    var enhancedTranscription: String
    var tags: [String]
    
    static var empty: Memo {
        Memo(date: Date(), audioURL: nil, originalTranscription: "", enhancedTranscription: "", tags: [])
    }
}

// CoreData 实体模型类
@objc(MemoEntity)
public class MemoEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var audioPath: String?
    @NSManaged public var originalTranscription: String
    @NSManaged public var enhancedTranscription: String
    @NSManaged public var tagsArray: NSArray? // 使用NSArray存储标签数组
}

extension MemoEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoEntity> {
        return NSFetchRequest<MemoEntity>(entityName: "MemoEntity")
    }
}

extension MemoEntity {
    func toMemo() -> Memo {
        var audioURL: URL? = nil
        if let path = audioPath {
            audioURL = URL(fileURLWithPath: path)
        }
        
        // 将NSArray转换为[String]
        let tagArray = (tagsArray as? [String]) ?? []
        
        return Memo(
            id: id,
            date: date,
            audioURL: audioURL,
            originalTranscription: originalTranscription,
            enhancedTranscription: enhancedTranscription,
            tags: tagArray
        )
    }
}
