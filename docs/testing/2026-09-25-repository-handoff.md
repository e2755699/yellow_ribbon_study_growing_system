# 2026-09-25 整理與交接

## 第二輪：升級前的主線整合

依使用者要求，Flutter 升級交由另一項工作執行；本次維持 Flutter 3.24.5，將既有完成內容交付 master：

- `codex/ipad-testflight-20260919`：已由 PR #1 合併。
- `codex/ipad-appstore-privacy`（`9dd3db7`）：完整納入政策 JSON、離線 Dart 內容、登入／首頁入口、正式元件與 Widgetbook、測試及 iPad 截圖工具。並收錄原工作目錄的政策定稿／送審紀錄，以及發布工作目錄的審查帳號驗證補充。
- `widgetbook`（`72f4c53`）：已檢視分叉點後全部變更；保留新版正式實作，舊範例原始碼與逐項取捨記錄於 [歷史目錄](../archive/widgetbook-2025/README.md)。合併其歷史不代表重新套用已廢棄的空白頁實驗。
- `gh-pages`（`c4c1c44`）：部署分支只含 `index.html`、`.nojekyll`，對應原始碼已完整納入 `docs/privacy-site/`；核對 HTML 與發布分支內容相同。保留既有 Pages 發布設定，不將網站根目錄搬到 Flutter 根目錄。

合併後的 `tool/check_design_system.ps1` 通過：App **109** 項、Widgetbook **23** 項。Widgetbook 目錄由 build_runner 產生並核對；指定遷移範圍分析仍只有 4 項既有 info。這次沒有重做人工畫面比對或 iPad 原生驗收；原生建置／正式送審仍由上架工作依實際结果更新。

政策已由使用者確認保留 1 年並公開；先前「待確認草稿」敘述屬歷史狀態。網站、政策原始碼和產生工具都可從 master 取得。Flutter SDK、Firebase SDK 與 Android 工具鏈沒有在這次整合升級。

以下保留第一輪整理紀錄；狀態以本節及最新發布紀錄為準。

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
- 第一輪的隱私政策為「待確認草稿」；第二輪已納入定稿，詳見上方更新。App 是否送審或上架仍以發布紀錄為準。

## 本次重跑驗證

- `tool/check_design_system.ps1` 通過：Widgetbook 20 項、App 97 項測試；Widgetbook 靜態分析無問題，指定遷移範圍分析 0 error／0 warning、4 項既有 info。
- Widgetbook `main.directories.g.dart` 以 build_runner 重新產生，內容沒有差異；App 與 Widgetbook 使用同一個 `StudentProfileOverview`。
- Firestore emulator：`demo-yellow-ribbon-theme` 本機專案，5 項通過、0 失敗，沒有跳過測試。
- Info.plist 可正常解析，iPad 的兩個方向值與 Flutter 啟動設定一致。
- `git diff --check` 通過。

這次以整理、回歸檢查與交接為範圍，沒有重新執行人工畫面比對或 iPad 原生建置／實機驗收；之前的視覺證據見 [Design System 驗證紀錄](../design-system.md)。目前提交包含 build 3 之後的原生設定修改，不能直接當作 TestFlight 已測版本。

## 尚待處理

- 線上 Firebase 規則合併、管理權授予與真實權限驗收仍待處理；不可用舊版整份本機 rules 覆蓋正式規則。
- App Store 建置、截圖與送審最新進度見 [送審準備](../release/app-store-submission.md)；政策期限及 App 內入口已在第二輪完成整合。
- 完整視覺遷移僅涵蓋元件目錄列出的範圍；首頁自訂版面、每日出席／表現、成長報告、查詢及舊 `DsTheme` 仍有 legacy 樣式。
- 本次透過合併請求交付 master；不部署 Firebase，也不觸發 App Store 提交。
