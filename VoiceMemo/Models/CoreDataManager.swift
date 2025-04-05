//
//  CoreDataManager.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import Foundation
import CoreData

// 这个类用于初始化和管理CoreData
class CoreDataManager {
    static let shared = CoreDataManager()
    
    // Core Data 堆栈
    lazy var persistentContainer: NSPersistentContainer = {
        let modelName = "VoiceMemoData"
        
        // 尝试查找CoreData模型文件
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("无法找到CoreData模型文件")
            
            // 如果未找到，创建内存中容器并返回
            let container = NSPersistentContainer(name: modelName)
            container.loadPersistentStores { _, error in
                if let error = error as NSError? {
                    print("内存中容器加载失败: \(error), \(error.userInfo)")
                }
            }
            return container
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("无法加载CoreData模型")
            
            // 如果未加载，创建内存中容器并返回
            let container = NSPersistentContainer(name: modelName)
            container.loadPersistentStores { _, error in
                if let error = error as NSError? {
                    print("内存中容器加载失败: \(error), \(error.userInfo)")
                }
            }
            return container
        }
        
        // 创建容器
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("CoreData存储加载失败: \(error), \(error.userInfo)")
            }
            print("CoreData存储加载成功，位置: \(storeDescription.url?.path ?? "未知")")
        }
        
        // 设置合并策略
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // 用于保存Context
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                print("CoreData保存失败: \(error), \(error.userInfo)")
            }
        }
    }
}
