# AUTH-A1：首頁登出

## 行為與範圍

- 首頁右上增加 `SignOutButton`，與政策／配色一起使用可換行工具列及共同 SystemThemeScope；維持品牌背景與四個業務入口。工具列占正常版面空間，不再浮蓋卡片。
- HomePageWidget 為 auth adapter，呼叫 FirebaseAuth.signOut，沿用 60 秒請求期限；重複點擊受阻，進行中停用首頁導覽。成功由既有 authStateChanges 路由保護返回登入；失敗提示重試，不自行清除帳號或學生資料。
- 元件只接收 callback／busy，不依賴 Firebase。Widgetbook 與正式 App 使用相同類別，收錄 ready、loading、disabled。錯誤提示由頁面負責。
- 登出入口只放首頁：由表單返回首頁時仍走原本保存／離開流程。帳號隔離草稿保留原契約；此次不是全裝置快取擦除，也不改刪除重裝時的登入政策。
- Firebase iOS SDK 將登入狀態保存在 Keychain，解除安裝後可能仍保留，故重裝不能替代 signOut。來源：https://firebase.google.com/docs/auth/flutter/password-auth （2026-10-05 查核）。

## 已執行證據

- Flutter 3.47.5：`tool/check_design_system.ps1` 通過，Widgetbook 60／App 230 項；generated catalog 由 build_runner 產生。
- 新增 13 項登出測試：單次呼叫／等待中停用、成功依 Auth 返回登入且受保護 deep link 仍被拒、失敗保留首頁並可重試、鍵盤 Enter、五尺寸 Light／Dark 及 2 倍文字可觸及／無重疊。
- 改動 Dart 分析 0 error／0 warning，3 個 info（沿用 opacity API 與測試 const 提示）；正式 prod 設定檢查及 iOS 靜態設定檢查通過。
- 真實 Flutter Web 渲染，memory theme repository／注入 Auth callback，未初始化 Firebase、未讀寫學生資料。實際點擊首頁登出回登入；不是 Firebase 真實帳號登出驗收。
- 目視五尺寸 `1024×768`、`768×1024`、`1194×834`、`834×1194`、`507×768`，各 Light／Dark：三個工具可辨識，四卡維持 2×2／窄版單欄，不遮擋。首頁與登出後登入頁在同主題比較。
- 本機證據：本 worktree `build/auth-a1-visual/web-home-<寬>x<高>-<light|dark>.jpg`（10 張），`web-login-after-signout-1024x768-light.jpg`；完整工具輸出 `build/auth-a1-design-check.log`。較早測試引擎 PNG 有缺字與未載入背景，不作正式目視證據。

## 尚未驗收／發布界線

- iPad 原生觸控、VoiceOver、Firebase 真實登入→登出→換帳號待 TestFlight 實機操作；本機 Windows 無 iOS runner。
- 既有 iOS 設定仍為 iPad 橫向 full-screen，直向與分割尺寸是介面回歸驗證，不代表已開啟原生分割模式。
- 自訂主題登出後完整保存仍屬 THEME-A1；此變更不宣稱解決。首頁原卡片與登入頁仍有 legacy geometry，不宣稱整頁完成 token 遷移。
- 發版、Apple 處理、內測可下載及 master 合併狀態各別記錄於 AUTH-A1；本文件的測試通過不等於已發版。
