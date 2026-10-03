  // 黃絲帶學習成長系統 — 專案架構總覽（code-review-canvas scene）
  // 核對基準：origin/master 2f2aabb（2026-10-03）。重新產生方式見 ../architecture.md。
  const W = 1480, H = 1990;

  // 架構總覽圖：沒有對應任何變更，所以全部是實線。
  const PLANES = {
    people:   { c: '#94A3B8', label: '使用者' },
    app:      { c: '#7DD3FC', label: 'App 殼層與頁面' },
    state:    { c: '#A78BFA', label: '狀態層（Cubit）' },
    data:     { c: '#FBBF24', label: '資料存取（Repository / Service）' },
    design:   { c: '#4ADE80', label: 'Design System' },
    firebase: { c: '#F6821F', label: 'Firebase 後端' },
    tooling:  { c: '#22D3EE', label: '開發支援' }
  };

  const BANDS = [
    { id: 'band-shell', plane: 'app', x: 160, y: 300, w: 1260, h: 180, alpha: 0.5,
      hdr:  { x: 184,  y: 330, t: '使用者與 App 殼層 — lib/main.dart · lib/flutter_flow/nav' },
      tagr: { x: 1396, y: 330, t: 'iPad 優先', alpha: 0.6 } },

    { id: 'band-feat', plane: null, x: 160, y: 540, w: 1260, h: 320, stroke: '#3A4250', alpha: 1,
      hdr:  { x: 184,  y: 570, t: '功能模組 — 上：頁面 lib/main/pages · 下：狀態 Cubit', fill: C.slate },
      tagr: { x: 1396, y: 570, t: '路由層建立 BlocProvider', fill: C.slate, alpha: 0.7 } },

    { id: 'band-data', plane: 'data', x: 160, y: 940, w: 1260, h: 212, alpha: 0.5,
      hdr:  { x: 184,  y: 970, t: '資料存取 — Repository' },
      tagr: { x: 1396, y: 970, t: '透過 GetIt 注入', alpha: 0.6 } },

    { id: 'band-fb', plane: 'firebase', x: 160, y: 1232, w: 1260, h: 284, alpha: 0.45,
      hdr:  { x: 184,  y: 1262, t: 'FIREBASE 後端' },
      tagr: { x: 1396, y: 1262, t: 'test-o9g27r', alpha: 0.6 } },

    { id: 'band-tool', plane: 'tooling', x: 160, y: 1596, w: 1260, h: 180, alpha: 0.45,
      hdr:  { x: 184,  y: 1626, t: '開發支援 — 不進正式導航' },
      tagr: { x: 1396, y: 1626, t: 'packages · widgetbook · test', alpha: 0.6 } }
  ];

  // 功能欄位：x 200 / 439 / 678 / 917 / 1156，寬 224，中心 312 / 551 / 790 / 1029 / 1268
  const BOXES = [
    // ---- 使用者與殼層
    { id: 'users', plane: 'people', band: 'band-shell', x: 200, y: 356, w: 265, h: 88, r: 10,
      name: '使用者', about: '學習輔導機構的老師與行政人員，主要在 iPad 上使用；Web 版只拿來預覽。',
      texts: [ ['bl', 224, 384, '使用者'], ['bs', 224, 406, '輔導老師 · 行政人員'], ['bs', 224, 422, 'iPad 為主，Web 只是預覽'] ] },

    { id: 'main', plane: 'app', band: 'band-shell', x: 505, y: 356, w: 265, h: 88, r: 10,
      name: 'main.dart', about: '啟動點：初始化 Firebase、在 _injectDependency() 註冊 Repository 與 DesignSystemStore、載入 FFAppState。',
      texts: [ ['bl', 529, 384, 'main.dart'], ['bs', 529, 406, 'Firebase 初始化 · GetIt 註冊'], ['bs', 529, 422, 'FFAppState · 主題 · 語系'] ] },

    { id: 'nav', plane: 'app', band: 'band-shell', x: 810, y: 356, w: 265, h: 88, r: 10,
      name: 'nav.dart — 路由', about: 'YbRoute + FFRoute（go_router）；AppStateNotifier 監聽登入狀態，受保護路由未登入一律導回 /。',
      texts: [ ['bl', 834, 384, 'nav.dart — 路由'], ['bs', 834, 406, 'go_router + FFRoute'], ['bs', 834, 422, '未登入一律導回 /'] ] },

    { id: 'home', plane: 'app', band: 'band-shell', x: 1115, y: 356, w: 265, h: 88, r: 10,
      name: '首頁 HomePage', about: '正式首頁只有四個業務入口（平板 2×2）；主題切換與 Design System 後台放在右上選單。',
      texts: [ ['bl', 1139, 384, '首頁 HomePage'], ['bs', 1139, 406, '學生 · 出席 · 表現 · 報告'], ['bs', 1139, 422, '右上選單：主題 / Design System'] ] },

    // ---- 功能模組：頁面
    { id: 'p-student', plane: 'app', band: 'band-feat', x: 200, y: 620, w: 224, h: 68, r: 10,
      name: '學生資料頁', about: '學生列表與學生詳情（查看 / 新增 / 編輯，含頭像與附件）。路由 /studentDetail/:operate/:sid。',
      texts: [ ['bl', 224, 648, '學生資料'], ['bs', 224, 670, 'StudentInfo · StudentDetail'] ] },
    { id: 'p-att', plane: 'app', band: 'band-feat', x: 439, y: 620, w: 224, h: 68, r: 10,
      name: '每日出席頁', about: '依日期與班級點名，離開或切換篩選前會先保存。',
      texts: [ ['bl', 463, 648, '每日出席'], ['bs', 463, 670, 'DailyAttendancePage'] ] },
    { id: 'p-perf', plane: 'app', band: 'band-feat', x: 678, y: 620, w: 224, h: 68, r: 10,
      name: '每日表現頁', about: '依日期與班級記錄每位學生的表現評分與品格標籤。',
      texts: [ ['bl', 702, 648, '每日表現'], ['bs', 702, 670, 'DailyPerformancePage'] ] },
    { id: 'p-report', plane: 'app', band: 'band-feat', x: 917, y: 620, w: 224, h: 68, r: 10,
      name: '成長報告 · 歷史表現', about: '成長報告列出學生卡片，點進去看個人歷史表現與表現明細。',
      texts: [ ['bl', 941, 648, '成長報告 · 歷史表現'], ['bs', 941, 670, 'GrowingReportPage'] ] },
    { id: 'p-ds', plane: 'design', band: 'band-feat', x: 1156, y: 620, w: 224, h: 68, r: 10,
      name: 'Design System 後台', about: '管理／預覽主題的後台，不是業務功能；入口在首頁右上選單最後一項。',
      texts: [ ['bl', 1180, 648, 'Design System 後台'], ['bs', 1180, 670, '首頁右上選單最後一項'] ] },

    // ---- 功能模組：Cubit
    { id: 'c-student', plane: 'state', band: 'band-feat', x: 200, y: 720, w: 224, h: 104, r: 10,
      name: '學生狀態', about: 'StudentsCubit（列表）、StudentDetailCubit（表單與儲存）、StudentActivityCubit（活動紀錄）。這是新頁面該照的範本。',
      texts: [ ['bl', 224, 746, '學生狀態'], ['bs', 224, 768, 'StudentsCubit'], ['bs', 224, 784, 'StudentDetailCubit'], ['bn', 224, 806, '路由層建立並觸發載入'] ] },
    { id: 'c-att', plane: 'state', band: 'band-feat', x: 439, y: 720, w: 224, h: 104, r: 10,
      name: '出席狀態', about: 'DailyAttendanceInfoCubit 用已儲存快照偵測修改；目前在頁面 initState 內建立，是舊模式。',
      texts: [ ['bl', 463, 746, '出席狀態'], ['bs', 463, 768, 'DailyAttendanceInfoCubit'], ['bs', 463, 784, '已儲存快照偵測修改'], ['bn', 463, 806, '頁面內自建（舊模式）'] ] },
    { id: 'c-perf', plane: 'state', band: 'band-feat', x: 678, y: 720, w: 224, h: 104, r: 10,
      name: '表現狀態', about: 'DailyPerformanceCubit 管表現紀錄，CharacterTagsCubit 管品格標籤；切換篩選前先保存，失敗不蓋掉草稿。',
      texts: [ ['bl', 702, 746, '表現狀態'], ['bs', 702, 768, 'DailyPerformanceCubit'], ['bs', 702, 784, 'CharacterTagsCubit'], ['bn', 702, 806, '切換篩選前先保存'] ] },
    { id: 'c-report', plane: 'state', band: 'band-feat', x: 917, y: 720, w: 224, h: 104, r: 10,
      name: '報告狀態', about: 'StudentPerformanceCubit 依學生彙整表現紀錄；報告列表共用 StudentsCubit。',
      texts: [ ['bl', 941, 746, '報告狀態'], ['bs', 941, 768, 'StudentPerformanceCubit'], ['bs', 941, 784, '共用 StudentsCubit'], ['bn', 941, 806, '依學生彙整表現紀錄'] ] },
    { id: 'c-ds', plane: 'design', band: 'band-feat', x: 1156, y: 720, w: 224, h: 104, r: 10,
      name: '草稿與發布', about: 'DesignSystemEditor 持有編輯草稿；DesignSystemStore 是全 App 共用的已發布主題。確認儲存後才發布。',
      texts: [ ['bl', 1180, 746, '草稿與發布'], ['bs', 1180, 768, 'DesignSystemEditor'], ['bs', 1180, 784, 'DesignSystemStore'], ['bn', 1180, 806, '確認儲存後才發布'] ] },

    // ---- 資料存取
    { id: 'r-students', plane: 'data', band: 'band-data', x: 200, y: 996, w: 224, h: 120, r: 10,
      name: 'StudentsRepo', about: 'students 集合的 CRUD；學生解析同時存在 getById() 與 load()，加欄位要兩處都改。',
      texts: [ ['bl', 224, 1024, 'StudentsRepo'], ['bs', 224, 1046, 'students 集合 CRUD'], ['bs', 224, 1062, 'getById() / load() 兩處解析'], ['bs', 224, 1078, '部分例外回傳 null'], ['bn', 224, 1100, '讀取仍是 .get()，非即時'] ] },
    { id: 'r-att', plane: 'data', band: 'band-data', x: 439, y: 996, w: 224, h: 120, r: 10,
      name: 'DailyAttendanceRepo', about: 'daily_attendance 集合；document ID 由 DateFormatter.formatToDocId 產生。文件不存在時 load() 會寫入預設出席。',
      texts: [ ['bl', 463, 1024, 'DailyAttendanceRepo'], ['bs', 463, 1046, 'daily_attendance'], ['bs', 463, 1062, 'docId：yyyy-MM-dd_班級'], ['bs', 463, 1078, '依日期 × 班級讀寫'], ['bn', 463, 1100, '無資料時會寫入預設值'] ] },
    { id: 'r-perf', plane: 'data', band: 'band-data', x: 678, y: 996, w: 224, h: 120, r: 10,
      name: 'DailyPerformanceRepo', about: 'daily_performances 集合，依賴 StudentsRepo；每日表現頁與成長報告都讀它。',
      texts: [ ['bl', 702, 1024, 'DailyPerformanceRepo'], ['bs', 702, 1046, 'daily_performances'], ['bs', 702, 1062, '依賴 StudentsRepo'], ['bs', 702, 1078, '同樣的 docId 規則'], ['bn', 702, 1100, '每日表現 · 報告共用'] ] },
    { id: 'r-other', plane: 'data', band: 'band-data', x: 917, y: 996, w: 224, h: 120, r: 10,
      name: '其他 Repo / Service', about: 'YellowRibbonRepo（黃絲帶計數）、CharacterTagsRepo（settings 內的品格標籤）、StudentAttachmentService / StorageService（頭像與附件）。',
      texts: [ ['bl', 941, 1024, '其他 Repo / Service'], ['bs', 941, 1046, 'YellowRibbonRepo'], ['bs', 941, 1062, 'CharacterTagsRepo'], ['bs', 941, 1078, 'StudentAttachmentService'], ['bn', 941, 1100, '附件：上傳→寫欄位→清舊檔'] ] },
    { id: 'r-ds', plane: 'design', band: 'band-data', x: 1156, y: 996, w: 224, h: 120, r: 10,
      name: 'DesignSystemRepository', about: '唯一的主題存取介面：正式 App 用 Firebase adapter，Widgetbook 用 Memory adapter。domain／Cubit 不直接碰 Firebase。',
      texts: [ ['bl', 1180, 1024, 'DesignSystemRepository'], ['bs', 1180, 1046, 'Firebase：正式 App'], ['bs', 1180, 1062, 'Memory：Widgetbook 用'], ['bs', 1180, 1078, '儲存前核對 revision'], ['bn', 1180, 1100, 'domain 不依賴 Firebase'] ] },

    // ---- Firebase
    { id: 'firestore', plane: 'firebase', band: 'band-fb', x: 200, y: 1288, w: 702, h: 104, r: 10,
      name: 'Cloud Firestore — 業務資料', about: '所有業務資料都在這裡；test-o9g27r 是雲端專案，不是本機 emulator。',
      texts: [ ['bl', 224, 1316, 'Cloud Firestore — 業務資料'], ['bs', 224, 1338, 'students · daily_attendance · daily_performances'], ['bs', 224, 1354, 'yellow_ribbon_counts · settings · users'], ['bn', 224, 1376, '專案名稱有 test，但連的是雲端，不是本機 emulator'] ] },
    { id: 'storage', plane: 'firebase', band: 'band-fb', x: 917, y: 1288, w: 224, h: 104, r: 10,
      name: 'Firebase Storage', about: '學生頭像與附件檔案；模型只存檔名，下載 URL 由服務取得。',
      texts: [ ['bl', 941, 1316, 'Firebase Storage'], ['bs', 941, 1338, 'avatars/ · profiles/'], ['bs', 941, 1354, '模型存檔名，取 URL'], ['bn', 941, 1376, 'Web / 行動兩條上傳分支'] ] },
    { id: 'themes', plane: 'firebase', band: 'band-fb', x: 1156, y: 1288, w: 224, h: 104, r: 10,
      name: 'Firestore — 主題資料', about: '主題獨立放在 design_systems/yellow_ribbon/themes，不和學生資料混在一起。',
      texts: [ ['bl', 1180, 1316, 'Firestore — 主題'], ['bs', 1180, 1338, 'design_systems/'], ['bs', 1180, 1354, 'yellow_ribbon/themes'], ['bn', 1180, 1376, '規則尚未部署'] ] },
    { id: 'auth', plane: 'firebase', band: 'band-fb', x: 200, y: 1412, w: 1180, h: 68, r: 10,
      name: 'Auth · Analytics · Crashlytics', about: 'Auth 的登入狀態驅動路由保護；Design System 管理權只看受信任的 custom claim designSystemAdmin。',
      texts: [ ['bl', 224, 1440, 'Firebase Auth · Analytics · Crashlytics'], ['bs', 224, 1462, '登入狀態驅動路由保護 · 管理權看 custom claim designSystemAdmin · 畫面事件與當機回報'] ] },

    // ---- 開發支援
    { id: 'uicomp', plane: 'tooling', band: 'band-tool', x: 200, y: 1652, w: 440, h: 88, r: 10,
      name: 'packages/ui_component', about: '獨立的 Flutter UI 套件，主程式以 path dependency 引用。',
      texts: [ ['bl', 224, 1680, 'packages/ui_component'], ['bs', 224, 1702, '獨立 UI 套件：按鈕、design token'], ['bs', 224, 1718, '主程式以 path dependency 引用'] ] },
    { id: 'widgetbook', plane: 'tooling', band: 'band-tool', x: 678, y: 1652, w: 463, h: 88, r: 10,
      name: 'widgetbook_gallery', about: '獨立的元件展示 App，引用主程式與 UI 套件；主題資料用 Memory adapter，不碰正式資料。',
      texts: [ ['bl', 702, 1680, 'widgetbook_gallery'], ['bs', 702, 1702, '元件與主題展示，用 Memory adapter'], ['bs', 702, 1718, 'usecases/ → build_runner 產生目錄'] ] },
    { id: 'tests', plane: 'tooling', band: 'band-tool', x: 1156, y: 1652, w: 224, h: 88, r: 10,
      name: 'test/ · firebase/', about: 'test/ 是根目錄的 widget 與單元測試；firebase/ 放 Firestore / Storage rules、indexes 與 Functions。',
      texts: [ ['bl', 1180, 1680, 'test/ · firebase/'], ['bs', 1180, 1702, 'widget / 單元測試'], ['bs', 1180, 1718, 'rules · indexes · Functions'] ] }
  ];

  const EDGES = [
    // 殼層內：開 App → 啟動 → 路由 → 首頁
    { from: 'users', to: 'main', pts: [[467,400],[499,400]] },
    { from: 'main',  to: 'nav',  pts: [[772,400],[804,400]] },
    { from: 'nav',   to: 'home', pts: [[1077,400],[1109,400]] },

    // 殼層 → 功能模組
    { from: 'nav', to: 'band-feat', pts: [[942,446],[942,534]],
      label: { s: 'al', x: 956, y: 500, t: '路由層建立 BlocProvider' } },
    { from: 'home', to: 'band-feat', pts: [[1247,446],[1247,534]],
      label: { s: 'al', x: 1261, y: 500, t: '四個入口 + 選單' } },

    // 頁面 → Cubit
    { from: 'p-student', to: 'c-student', pts: [[312,690],[312,714]] },
    { from: 'p-att',     to: 'c-att',     pts: [[551,690],[551,714]] },
    { from: 'p-perf',    to: 'c-perf',    pts: [[790,690],[790,714]] },
    { from: 'p-report',  to: 'c-report',  pts: [[1029,690],[1029,714]] },
    { from: 'p-ds',      to: 'c-ds',      pts: [[1268,690],[1268,714]] },

    // Cubit → Repository
    { from: 'c-student', to: 'r-students', pts: [[400,826],[400,990]],
      label: { s: 'al', x: 414, y: 900, t: 'GetIt 取得' } },
    { from: 'c-att',  to: 'r-att',  pts: [[551,826],[551,990]] },
    { from: 'c-perf', to: 'r-perf', pts: [[790,826],[790,990]] },
    { from: 'c-report', to: 'r-perf', pts: [[1000,826],[1000,900],[860,900],[860,990]],
      label: { s: 'al', x: 930, y: 890, t: '讀表現紀錄', anchor: 'center' } },
    { from: 'c-ds', to: 'r-ds', pts: [[1200,826],[1200,990]] },

    // Repository → Firebase
    { from: 'r-students', to: 'firestore', pts: [[400,1118],[400,1282]] },
    { from: 'r-att',      to: 'firestore', pts: [[551,1118],[551,1282]] },
    { from: 'r-perf',     to: 'firestore', pts: [[790,1118],[790,1282]],
      label: { s: 'al', x: 804, y: 1200, t: '多數仍是 .get() 讀一次' } },
    { from: 'r-other', to: 'storage', pts: [[1029,1118],[1029,1282]],
      label: { s: 'al', x: 1043, y: 1200, t: '頭像 · 附件' } },
    { from: 'r-ds', to: 'themes', pts: [[1200,1118],[1200,1282]],
      label: { s: 'al', x: 1214, y: 1200, t: '.snapshots()' } },

    // Auth → 路由保護（右側 gutter）
    { from: 'auth', to: 'nav', pts: [[1382,1446],[1440,1446],[1440,400],[1426,400]],
      label: { s: 'al', x: 1456, y: 920, t: '登入狀態串流 → AppStateNotifier 路由保護', rot: -90, anchor: 'center' } },

    // 開發支援
    { from: 'widgetbook', to: 'uicomp', pts: [[676,1696],[646,1696]] },
    { from: 'uicomp', to: 'band-feat', pts: [[198,1696],[100,1696],[100,700],[154,700]],
      label: { s: 'al', x: 84, y: 1200, t: '共用 UI 元件（path dependency）', rot: -90, anchor: 'center' } }
  ];

  const TEXTS = [
    { s: 'title', x: 160, y: 86,  t: '黃絲帶學習成長系統 — 專案架構總覽' },
    { s: 'sub',   x: 160, y: 118, t: 'Flutter iPad App：頁面 → Cubit → Repository → Firebase；Design System 是獨立的一條線' },
    { s: 'tag',   x: 160, y: 146, runs: [
        { t: '頁面',        fill: C.sky },
        { t: ' → 狀態交給 ', fill: '#4A5462' },
        { t: 'Cubit',       fill: '#A78BFA' },
        { t: ' → 存取走 ',   fill: '#4A5462' },
        { t: 'Repository',  fill: '#FBBF24' },
        { t: ' → 落在 ',     fill: '#4A5462' },
        { t: 'Firebase',    fill: C.orange } ] },

    { s: 'legend', x: 1082, y: 86,  t: '實線 — 目前的程式元件（總覽圖）' },
    { s: 'legend', x: 1082, y: 110, t: '使用者' },
    { s: 'legend', x: 1082, y: 134, t: 'App 殼層與頁面' },
    { s: 'legend', x: 1082, y: 158, t: '狀態層（Cubit）' },
    { s: 'legend', x: 1082, y: 182, t: '資料存取（Repository / Service）' },
    { s: 'legend', x: 1082, y: 206, t: 'Design System' },
    { s: 'legend', x: 1082, y: 230, t: 'Firebase 後端' },
    { s: 'legend', x: 1082, y: 254, t: '開發支援' },

    { s: 'bn', x: 160, y: 1846, t: '即時同步是系統規則，但業務 Repository 目前仍用 .get() 讀一次；只有 Design System 用 .snapshots() 訂閱 — 改造方案待規劃' },
    { s: 'bn', x: 160, y: 1866, t: '新頁面由路由層建立 BlocProvider 並觸發載入（學生資料是範本）；每日出席 / 表現在頁面內自建 Cubit，是舊模式' },
    { s: 'bn', x: 160, y: 1886, t: 'Design System 的 Firestore 規則尚未部署到 test-o9g27r；管理權只看受信任的 custom claim designSystemAdmin' },
    { s: 'bn', x: 160, y: 1906, t: '核對基準：origin/master 2f2aabb（2026-10-03）；codex/roster-migration 的新名冊資料模型尚未合併，未畫入' }
  ];

  const SWATCHES = [
    { x: 1046, y: 75, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill }
  ];

  const CHIPS = ['people', 'app', 'state', 'data', 'design', 'firebase', 'tooling']
    .map((id, i) => ({ x: 1046, y: 99 + i * 24, w: 26, h: 13, fill: planeColor(id) }));
