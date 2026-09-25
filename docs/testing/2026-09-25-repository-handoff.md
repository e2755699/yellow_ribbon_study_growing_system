# 2026-09-25 整理與交接

這批工作由 `codex/ipad-testflight-20260919` 透過合併請求交付 `master`；合併後以 `master` 為團隊開發基準。既有主要功能在 `c132582`，TestFlight build 3 交付紀錄在 `9cd29bd`。

## 同事接續開發

先保存自己尚未提交的工作，再執行：

```sh
git fetch origin
git switch master
git pull --ff-only origin master
```

使用 **Flutter 3.24.5 / Dart 3.5.4**，分別在根目錄、`packages/ui_component/` 與 `widgetbook_gallery/` 執行 `flutter pub get`。可從此分支另開自己的功能分支。

`.flutter-plugins` 與 `.flutter-plugins-dependencies` 含每台電腦的套件快取路徑，已停止版本追蹤並加入忽略規則；本機檔案保留，換機由 `flutter pub get` 重建。Widgetbook 的平台插件註冊檔仍保留版本追蹤，這次納入既有依賴產生的更新。

## 本次整理範圍

- 內建淺色主題的語意文字色，以及學生詳情姓名／區塊標題使用 `primaryText` 的修正；保留相關回歸測試，更新現有元件登錄與 Widgetbook 案例說明。
- iPad Info.plist 與 Flutter 啟動時的左右橫向設定。
- Design System Firestore 規則、本機 emulator 設定及五組規則測試。這是版本管理交付，沒有部署線上規則。
- 補入先前功能、設計、測試及送審紀錄，修正 README 中過時的「尚未提交」描述與返回保存文件的矛盾說明。
- 隱私政策保留「待確認草稿」狀態；提交 repository 不代表政策正式生效、App 已送審或上架。

## 本次重跑驗證

- `tool/check_design_system.ps1` 通過：Widgetbook 20 項、App 97 項測試；Widgetbook 靜態分析無問題，指定遷移範圍分析 0 error／0 warning、4 項既有 info。
- Widgetbook `main.directories.g.dart` 以 build_runner 重新產生，內容沒有差異；App 與 Widgetbook 使用同一個 `StudentProfileOverview`。
- Firestore emulator：`demo-yellow-ribbon-theme` 本機專案，5 項通過、0 失敗，沒有跳過測試。
- Info.plist 可正常解析，iPad 的兩個方向值與 Flutter 啟動設定一致。
- `git diff --check` 通過。

這次以整理、回歸檢查與交接為範圍，沒有重新執行人工畫面比對或 iPad 原生建置／實機驗收；之前的視覺證據見 [Design System 驗證紀錄](../design-system.md)。目前提交包含 build 3 之後的原生設定修改，不能直接當作 TestFlight 已測版本。

## 尚待處理

- 線上 Firebase 規則合併、管理權授予與真實權限驗收仍待處理；不可用舊版整份本機 rules 覆蓋正式規則。
- App Store 尚未重新送審，隱私政策保存期限、App 內政策入口與新版截圖等見 [送審準備](../release/app-store-submission.md)。
- 完整視覺遷移僅涵蓋元件目錄列出的範圍；首頁自訂版面、每日出席／表現、成長報告、查詢及舊 `DsTheme` 仍有 legacy 樣式。
- 本次透過合併請求交付 master；不部署 Firebase，也不觸發 App Store 提交。
