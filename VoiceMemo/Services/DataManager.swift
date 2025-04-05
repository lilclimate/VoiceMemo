//
//  DataManager.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import Foundation
import CoreData
import Combine

class DataManager {
    static let shared = DataManager()
    
    private let container: NSPersistentContainer
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        container = NSPersistentContainer(name: "VoiceMemoData")
        
        // 加载数据存储
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // 替换这些错误条件代码为您的实际错误处理
                /*
                 典型的错误包括:
                 * 目标目录不存在
                 * 外部存储不可用
                 * 没有权限创建存储位置
                 * 已经存在但不可访问的存储
                 */
                fatalError("加载Core Data存储失败: \(error), \(error.userInfo)")
            }
        }
        
        // 启用自动合并策略
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // 保存录音备忘录
    func saveMemo(memo: Memo) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(DataError.managerDeallocated))
                return
            }
            
            let context = self.container.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "MemoEntity", in: context)!
            let memoEntity = NSManagedObject(entity: entity, insertInto: context) as! MemoEntity
            
            memoEntity.id = memo.id
            memoEntity.date = memo.date
            memoEntity.audioPath = memo.audioURL?.path
            memoEntity.originalTranscription = memo.originalTranscription
            memoEntity.enhancedTranscription = memo.enhancedTranscription
            memoEntity.tagsArray = memo.tags as NSArray
            
            do {
                try context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取所有备忘录
    func fetchAllMemos() -> AnyPublisher<[Memo], Error> {
        return Future<[Memo], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(DataError.managerDeallocated))
                return
            }
            
            let context = self.container.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MemoEntity")
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            let fetchRequest = request as! NSFetchRequest<MemoEntity>
            
            do {
                let memoEntities = try context.fetch(fetchRequest)
                let memos = memoEntities.map { $0.toMemo() }
                promise(.success(memos))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 删除备忘录
    func deleteMemo(id: UUID) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(DataError.managerDeallocated))
                return
            }
            
            let context = self.container.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MemoEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let fetchRequest = request as! NSFetchRequest<MemoEntity>
            
            do {
                let results = try context.fetch(fetchRequest)
                if let memoToDelete = results.first {
                    // 如果有关联的音频文件，也删除它
                    if let audioPath = memoToDelete.audioPath {
                        try? FileManager.default.removeItem(atPath: audioPath)
                    }
                    
                    context.delete(memoToDelete)
                    try context.save()
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}

enum DataError: Error {
    case managerDeallocated
}
