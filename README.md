# 黃絲帶學習成長系統

## 專案概述

黃絲帶學習成長系統是一個專為學習輔導機構設計的綜合管理平台，提供學生資料管理、每日出席記錄、學習表現追蹤等功能。

## 📚 開發指南

### 🚀 快速開始
- [新增頁面檢查清單](docs/quick_reference/new_page_checklist.md) - 新增頁面的快速指南
- [頁面導航與狀態管理最佳實踐](docs/best_practices/page_navigation_and_state_management.md) - 詳細的開發規範

### 🏗️ 架構原則
專案採用 **Clean Architecture** 和 **Bloc Pattern**：
- **路由層**：負責提供正確配置的 BlocProvider
- **Widget 層**：只負責 UI 渲染和用戶互動  
- **Cubit/Bloc 層**：負責業務邏輯和狀態管理
- **Repository 層**：負責數據存取

### 📋 團隊約定
1. **所有新頁面** 都必須遵循最佳實踐文檔
2. **Code Review** 時檢查是否符合標準模式
3. **遇到問題** 時先查閱開發指南
4. **建議改進** 時更新相關文檔

## 🔧 技術棧

- **Framework**: Flutter
- **狀態管理**: flutter_bloc
- **路由**: go_router  
- **後端**: Firebase (Firestore, Auth, Storage)
- **依賴注入**: get_it
- **UI**: Material Design + 自定義設計系統

## 📁 專案結構

```
lib/
├── domain/              # 業務邏輯層
│   ├── bloc/           # Cubit/Bloc 狀態管理
│   ├── model/          # 數據模型
│   ├── repo/           # Repository 介面與實作
│   └── service/        # 業務服務
├── main/               # UI 層
│   ├── pages/          # 頁面 Widget
│   └── components/     # 可重用組件
├── backend/            # 後端配置
└── flutter_flow/       # 路由配置
```

## 🚀 開始使用

### 環境需求
- Flutter 3.0+
- Dart 3.0+
- Firebase 項目配置

### 安裝步驟
```bash
# 1. 克隆專案
git clone [repository-url]

# 2. 安裝依賴
flutter pub get

# 3. 配置 Firebase
# (參考 Firebase 配置文檔)

# 4. 運行專案
flutter run
```

## 🧪 測試

```bash
# 運行所有測試
flutter test

# 運行特定測試檔案
flutter test test/domain/bloc/student_detail_cubit_test.dart

# 生成覆蓋率報告
flutter test --coverage
```

## 📖 功能模組

### 核心功能
- **學生資料管理** - 完整的學生檔案系統
- **每日出席記錄** - 班級出席狀況追蹤
- **學習表現評估** - 多維度表現記錄
- **成長報告生成** - 個人化學習報告

### 輔助功能  
- **用戶權限管理** - 角色基礎的權限控制
- **數據分析** - 學習趨勢分析
- **通知系統** - 重要事件提醒

## 🤝 貢獻指南

1. 查看 [開發最佳實踐](docs/best_practices/page_navigation_and_state_management.md)
2. 使用 [新增頁面檢查清單](docs/quick_reference/new_page_checklist.md)
3. 遵循專案的編碼規範
4. 提交 PR 前確保所有測試通過
5. 添加必要的文檔更新

## 📞 支援

- **技術問題**: 查看開發指南或聯絡技術團隊
- **業務需求**: 聯絡產品團隊  
- **文檔改善**: 歡迎提交 PR

---

*最後更新：2024年1月*
