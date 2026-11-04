# WEB-A1 月出席報表後台

## 接續備忘

2026-11-05 更正已部署：以文末「使用者更正優先」及「修正驗證」為準；先前待核對問號、暫計星號與額外統計欄均已取消。只有使用者指定的測試學生被清理，其餘原值保留。

2026-11-04：已修正並部署到 [Firebase Hosting 後台](https://yellow-ribbon-growing-admin.web.app)，線上直接顯示 Firebase Email／密碼表單、示範報表 PDF 下載實測通過。先前 owner-private Sites 是代理選錯託管方式，已被取代，不是正式入口。[PR #30](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/30) 開啟待驗收，未合併 master。正式帳號／資料驗收仍待使用者確認。分支 `codex/monthly-attendance-admin`。

## 需求原話

「你直接做一版後台網頁給我…第一個功能就是瀏覽月出席報表然後就有下載就跟這個長得一模一樣做成pdf檔…做不了一模一樣就一定要做的好看」

使用者提供紙本照片：橫式逐生逐日點名表，日期／星期雙列，週末灰底、應到／實到／假別／出席率。先前已要求沿用 App 帳號與資料；固定月報範本已提供。

## 實作範圍與資料流

- 一個垂直任務 WEB-A1：獨立 Flutter Web 入口 `lib/admin_main.dart`；不改正式 App 四入口或發布 TestFlight。
- Auth → 既有 FirebaseRosterRepository／staff_access 據點授權 → 月範圍即時訂閱 → 月報 Service → Cubit → 正式 MonthlyAttendanceView／MonthlyAttendanceTable。
- 同一份報表 model 提供畫面與 PDF，避免兩套統計；PDF 採 A4 橫向，依人數自動分頁、重複表頭，繁體字型內嵌。
- 瀏覽與匯出唯讀；不修改資料、規則、權限。完整月資料不能套用既有歷史頁預設 100 筆截斷。
- 沿用 SystemTheme → SystemPage／SystemPageHeader／InfoBar／SystemSectionCard；新增公開元件同步登錄 Widgetbook，僅用合成 fixtures。
- 可使用原帳號登入；另有明確標示的合成示範入口，可驗證操作與下載，不包含任何正式學生資料。

## 業務規則

- 預設上個月（台灣日期）；可切換任意合法月份與授權據點。
- 月名冊為有效期間與既存本月紀錄的聯集，不因當前離班就遺失歷史；紀錄找不到有效期間列待核對。
- 應到依已確認 held 課次與有效就讀期間；cancelled 不計入；無課次不推定放假。週末灰底只表示星期。
- 無記錄不得補缺席；已確認課次且有效就讀但無紀錄顯示「?」未點名。
- 出席／遲到／早退計實到；校車缺席獨立，不冒充無故缺席。
- 病假／事假僅原原因恰為病假／事假時分類，其他維持未分類；不從姓名、家長、備註推測。
- 未確認出席狀態、未知課次與期間異常保留符號和待核對計數，不納入已確認統計。
- 出席率沿用現有 AttendanceStatistics 的 present / confirmed；未完整標暫計，無確認資料顯示待確認。
- 系統無年級欄位：年級留白，不猜測；組織抬頭使用專案名稱，不憑模糊照片臆造法定名稱。
- 下載須資料已完整取得雲端確認；載入、權限錯誤、離線快取、空名冊時停用，PDF 生成期間禁止重複點擊。撤權／帳號或範圍切換使舊匯出失效。

## 實作前驗收案例

| ID | 驗證 | 預期 |
| --- | --- | --- |
| T1 | 一個月超過 100 筆 | 全部載入，畫面／PDF 統計相同 |
| T2 | 轉點／離班／同日取消期間 | 依當日有效期間，不套用現役名單到整月 |
| T3 | 缺資料、取消課次、無課次、舊未確認資料 | 不補缺席，明確揭露；比率不冒充完成 |
| T4 | 病假／事假／其他原因／校車缺席／遲到早退 | 分類與現行規則一致 |
| T5 | 換月份／據點／登出或撤權後舊訂閱晚到 | 舊範圍與個資不再顯示，舊 PDF 不下載 |
| T6 | 載入／空／錯誤／離線／匯出失敗 | 對應提示與重試，停用操作清楚 |
| T7 | 合成資料 507、768、834、1024、1194 寬與明暗 | 文字／按鈕不溢位，報表可水平捲動，鍵盤可操作 |
| T8 | PDF 0／1／32／多頁長姓名 | 繁中文字形、表頭、格線、頁尾、月底統計完整不裁切 |
| W1 | 示範模式切月份與據點、下載 PDF | 示範資料標示，PDF 可開啟且與畫面一致 |
| W2 | 正式帳號登入並只讀授權據點 | 不使用管理憑證代替使用者權限；未實測則列待驗 |

## 驗證與交付證據

- `test/monthly_attendance_report_test.dart` 14 項通過：超過 100 筆、跨月與 leap year、有效期間／空期間、取消／未知課次、遲到早退／假別／校車分類、舊欄位確認、撤權與範圍切換取消匯出、更新／重複下載失效、暫時錯誤不被其他來源掩蓋、離線停用、PDF 多頁長名、五尺寸明暗與登入驗證。
- `tool/check_design_system.ps1` 完整通過：App **250**、Widgetbook **72** 項；Widgetbook analyze 0 issues；App gate 範圍有既存 info，非本次新增。另對新增功能路徑與測試 analyze 為 **0 issues**。Widgetbook 目錄由 build_runner 產生，未手改。
- Web release：`tool/build_admin_site.ps1` 成功，獨立入口；PDF 用開源 Noto Sans TC 的 400 字重靜態實例，完整字集與授權同包，產生時無遠端字型依賴。
- 真實瀏覽器操作：合成資料 2026/10 → 2026/09 空月份，PDF 下載停用；切回 10 月、換示範西區據點成功；Tab 可移動控制項焦點；按下載已取得 `示範東區據點_2026-10_出席紀錄表.pdf`，用 Poppler 實際渲染檢查。
- 實際 Web 目視：1194×834、1024×768、768×1024、834×1194、507×768；另外檢查窄版 Dark。月份與據點窄版堆疊、卡片單欄，下載仍可見；報表姓名固定、日期與統計水平捲動。截圖在本聊天工作區外 `C:/Users/USER/.codex/visualizations/2026/11/04/01a1a685-ac9f-7913-85a3-6cada727fddb/admin-browser-*.png`。測試亦檢查五尺寸 Light／Dark 無 overflow；測試 raster 不是實機驗收。
- PDF QA：0／1／32 人各一頁；65 人＋一筆超長合成姓名共 3 頁；各頁有重複日期與星期表頭、統計、說明及頁碼。pypdf／pdfplumber 核對頁數、中文字與文字邊界，Poppler 目視一頁 32 人及長姓名末頁；檔案在 `build/monthly-report-qa/`，不提交合成產物。
- 正式資料唯讀查詢：以目前操作環境的既有 Google 身分核對月查詢的 locationId＋dateKey 升序索引與 10 月資料，回傳 **527 筆**；沒有寫入資料，也不將此管理環境讀取當作終端使用者登入驗收。
- 網站身分：Sites project `appgprj_6aeb288e769c8191bbb2400363169759`；新建時維持 owner-private。發布成敗與實際 URL 另記於下方，不把 expected URL 當上線證據。

### Firebase Hosting 修正與線上交付（目前入口）

- 使用者原話：「你不是直接架在firebase web hosting媽然後就用firebase設定的email登入阿」。這是對託管方式的明確更正，原 Sites 的額外 ChatGPT 閘門不符合需求。
- Firebase 專案 `yellow-ribbon-growing-prod`，新建獨立 site `yellow-ribbon-growing-admin`；正式入口 [https://yellow-ribbon-growing-admin.web.app](https://yellow-ribbon-growing-admin.web.app)。保留原 default site `yellow-ribbon-growing-prod`，沒有覆蓋。
- 使用 `firebase deploy --only hosting --config firebase.admin.json --project yellow-ribbon-growing-prod --account <既有具權限帳號> --non-interactive`，CLI 回應 `success`；版本 `projects/310236133458/sites/yellow-ribbon-growing-admin/versions/46b194376737b4ea`。僅部署 Hosting，沒有改 Rules／Functions／Auth 帳號／學生資料。
- Identity Toolkit 設定唯讀核對：Email provider enabled、passwordRequired 均為 true。網站沿用同一 prod Web app 與 Firebase Auth SDK，沒有 ChatGPT 驗證代理或額外註冊步驟。
- HTTP GET 正式根網址為 200、正確後台標題。真實瀏覽器直接進入後看到帳號 Email、密碼、登入後台；不經 ChatGPT 登入。點合成示範後在正式 Firebase 網址按下載，取得 `示範東區據點_2026-10_出席紀錄表 (2).pdf`，再回到正式登入頁。
- 線上登入畫面證據：`C:/Users/USER/.codex/visualizations/2026/11/04/01a1a685-ac9f-7913-85a3-6cada727fddb/firebase-admin-login.png`。正式使用者密碼未取得，不宣稱已完成實際帳號登入驗收。
- 新增 `firebase.admin.json`（明確指定站點與產物、SPA rewrite 與必要 cache header）及 `tool/deploy_admin_site.ps1`（build → 明確 prod hosting-only deploy）；JSON 目標與 PowerShell syntax 核對通過。畫面與 PDF 程式未改，本次不重做已通過的 250／72 項測試。

### 先前 Sites 交付（歷史，已被 Firebase Hosting 取代）

- 私人網站已發布成功：[黃絲帶管理後台](https://yellow-ribbon-attendance-admin.e493af00-aa4c-4ba8-8256-090eeb002601.chatgpt.site)。2026-11-04 21:11（台灣時間）原生 Sites 回應 `succeeded`；deployment `appgdep_6aeb2ed57e0c8191884b2a4ad4e6d409`，saved version `appgprj_6aeb288e769c8191bbb2400363169759~appgver_7cfc36af6b348191948a71139f83b0d4`。
- 來源程式 commit `ef8e2396a9ff976d3cefe926c1e919ffaf9ff0cb`；Sites 靜態來源 commit `1055219559ba9848e55b02e4a13f3c8c6e89d3ce`，精確封裝並發布同一版本。編譯包僅程式／字型／既有產品資產／合成 fixtures，無正式名冊或匯出檔。
- Web 介面同包中文字型補強後再次 build／analyze 成功；重新由瀏覽器下載 PDF，再核對 12 位合成學生、單頁、中文與文字邊界通過。最終畫面證據：聊天輸出目錄 `admin-final-preview.png`。主驗證 App 250／Widgetbook 72；gate 的 50 個既有 info 沒有在本次無關清理。
- 部署 URL 實際開啟後顯示 owner-private 的 ChatGPT 登入閘門；本環境的網站瀏覽器未登入 ChatGPT，因此沒有繞過閘門或宣稱已在遠端登入正式資料。使用者先用建立網站的 ChatGPT 帳號開啟，再用 App 帳號登入，或點「先看示範報表」。本機同一 release build 的完整瀏覽／下載已實測。
- [PR #30](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/30) 提供可審查程式與案例；未自動合併。知識主題與索引已同步到主 checkout，供其他工作樹查閱。

### 待使用者驗收

- W2：用既有 App 的正式帳號登入新網站；確認可用據點、10 月學生與數字；未取得使用者密碼，因此未代替使用者做正式登入。
- 核對照片抬頭、年級來源、假別分類及正式出席率口徑；目前包含待核對／未點名／未分類與暫計揭露，不宣稱社會局已核准。
- iPad Safari 觸控與系統大字；目前是 Web 瀏覽器與測試矩陣，沒有 iPad 實機。
- App 的既有登入品牌版型、首頁、YbButton、其他 legacy 字級／配色不在本次遷移；未修改正式 Firebase Rules 或發布 TestFlight。
## 使用者更正優先（2026-11-04）

- 使用者明確指定只有「劉找了」為測試，其餘都是真實資料。禁止再以搬遷 provenance 自行稱為未確認或排除。
- 本次修正沿用 WEB-A1：月報服務按既存 status 計數；缺資料留白；移除自行增加的 `?`、`＊`、比率 `*`。資料庫其他學生與原始點名值不改寫。
- 修正前驗證案例：legacyUnverified／partiallyConfirmed 的出席都顯示 ○ 並計入；無課次或期間不符的既存紀錄也保留原值；沒有紀錄留白且不計缺席。
- 紙本輸出按範本保留六個統計欄（應出席天數、實際出席天數、病假、事假、無故、出席率）及缺席統計群組表頭；取消自行增加的統計欄與段落。
- 只刪除指定學生及其關聯文件，執行前留存私有備份。2026-11-04 已確認精確姓名／ID，原子刪除 5 份文件並移除 1 份共享索引中的該生項目，查詢驗證不存在；共享課次保留。備份不進 Git 或 Hosting。

## 修正驗證（2026-11-05）

- 原始來源重新查詢：10 月 526 筆；生效期間與紀錄聯集 32 位，全部已存狀態納入，實到 406，問號 0。其他學生原始資料未改寫；指定學生刪除只涉及 5 份文件與 1 份共享索引中的該生項目，先備份再提交，查詢驗證無殘留。
- 修正回歸 14 項通過；設計系統 gate 重新執行，App 250／Widgetbook 72 通過，變動的 Dart 路徑 analyze 無問題。正式元件 registry／Widgetbook 同步，目錄由 build_runner 生成。
- 10 月真實 PDF 使用正式 MonthlyAttendanceService／MonthlyAttendancePdf 產生，32 位、一頁 A4 橫式，逐日數值與原始狀態保留。已渲染檢查中文、雙列表頭、六個統計欄、週末灰底及完整格線；Excel 同版型、可計算公式、逐列核對與 A4 列印設定，無公式錯誤。
- Firebase Hosting 最終版本 `a3b221508fb628a7`，網址 https://yellow-ribbon-growing-admin.web.app/ 。瀏覽器實際重新整理根入口後顯示 Email／密碼，進合成示範已看到「點名紀錄／依原始紀錄顯示與統計」，無 ○? 或待處理計數；線上下載 PDF 核對一頁、缺席統計群組與無問號通過。正式帳號登入沒有代驗。
- 發現 Firebase 預設 main.dart.js 一小時快取會讓原分頁仍執行舊程式；build_admin_site.ps1 以 SHA256 命名 entry，並同步更新獨立 bootstrap 與 index 內嵌 bootstrap。第二次修正後一般 reload 已驗證載入新版，未要求使用者清除瀏覽器全部資料。
- 實際 Web 畫面：聊天私有輸出目錄 firebase-corrected-report.png（合成示範）；真實匯出與來源只留私有輸出目錄，不進 Git 或 Hosting。正式帳號／iPad Safari／抬頭與年級來源仍待驗收，不宣稱與紙本逐字完全相同；沒有補造年級或法定名稱。
- PR #30 更新待驗收；未合併 master，未發布 TestFlight。
