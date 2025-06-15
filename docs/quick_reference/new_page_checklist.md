# 新增頁面快速檢查清單

## 🚀 快速開始

新增一個帶有數據載入的頁面時，請按照以下步驟：

### 1️⃣ 創建 Bloc/Cubit 結構
```bash
# 創建目錄結構
mkdir -p lib/domain/bloc/[feature_name]_cubit
touch lib/domain/bloc/[feature_name]_cubit/[feature_name]_cubit.dart
touch lib/domain/bloc/[feature_name]_cubit/[feature_name]_state.dart
```

### 2️⃣ 實作 State（複製模板）
```dart
// [feature_name]_state.dart
abstract class [FeatureName]State {
  final Operate operate;
  final [DataModel] detail;
  
  const [FeatureName]State({this.operate = Operate.view, required this.detail});
}

class [FeatureName]Initial extends [FeatureName]State {
  const [FeatureName]Initial({super.operate, required super.detail});
}

class [FeatureName]Loaded extends [FeatureName]State {
  const [FeatureName]Loaded({required super.detail, super.operate});
  
  [FeatureName]Loaded copyWith({[DataModel]? detail, Operate? operate}) {
    return [FeatureName]Loaded(
      detail: detail ?? this.detail,
      operate: operate ?? this.operate,
    );
  }
}

class [FeatureName]Error extends [FeatureName]State {
  final String message;
  const [FeatureName]Error(this.message, {super.operate, required super.detail});
}
```

### 3️⃣ 實作 Cubit（複製模板）
```dart
// [feature_name]_cubit.dart
class [FeatureName]Cubit extends Cubit<[FeatureName]State> {
  [FeatureName]Cubit(super.initialState);

  Future<void> loadById(String id, {Operate operate = Operate.view}) async {
    await tryCatchWrap(() async {
      final data = await GetIt.I<[DataRepo]>().getById(id);
      if (data != null) {
        emit([FeatureName]Loaded(detail: data, operate: operate));
      } else {
        emit([FeatureName]Error("找不到資料", detail: state.detail));
      }
    }, errorMessage: "載入資料失敗");
  }

  Future<void> tryCatchWrap(Future<void> Function() action, {required String errorMessage}) async {
    try {
      await action();
    } catch (e) {
      print('$runtimeType error: $e');
      Fluttertoast.showToast(msg: errorMessage);
      
      if (state is [FeatureName]Loaded) {
        final currentState = state as [FeatureName]Loaded;
        emit([FeatureName]Error(errorMessage, detail: currentState.detail));
      } else {
        emit([FeatureName]Error(errorMessage, detail: [DataModel].empty()));
      }
    }
  }
}
```

### 4️⃣ 配置路由（關鍵步驟）
```dart
// lib/flutter_flow/nav/nav.dart

// 1. 添加 imports
import 'package:your_project/domain/bloc/[feature_name]_cubit/[feature_name]_cubit.dart';
import 'package:your_project/domain/bloc/[feature_name]_cubit/[feature_name]_state.dart';
import 'package:your_project/domain/model/[data_model].dart';

// 2. 添加路由枚舉
enum YbRoute {
  // ... existing routes
  [featureName]("/[featureName]"),
}

// 3. 添加路由配置
FFRoute(
  name: YbRoute.[featureName].name,
  path: "${YbRoute.[featureName].routeName}/:operate/:id",
  builder: (context, fFParameters) {
    var params = fFParameters.state.pathParameters;
    var operate = Operate.values.where((o) => o.name == params["operate"]).first;
    var id = params['id'] ?? "";

    return BlocProvider<[FeatureName]Cubit>(
      create: (context) {
        final cubit = [FeatureName]Cubit(
          [FeatureName]Initial(operate: operate, detail: [DataModel].empty())
        );
        
        if (id.isNotEmpty && operate != Operate.create) {
          cubit.loadById(id, operate: operate);
        }
        
        return cubit;
      },
      child: const [FeatureName]PageWidget(),
    );
  },
),
```

### 5️⃣ 創建 Widget（複製模板）
```dart
// lib/main/pages/[feature_name]_page/[feature_name]_page_widget.dart
class [FeatureName]PageWidget extends StatefulWidget {
  const [FeatureName]PageWidget({super.key});

  @override
  State<[FeatureName]PageWidget> createState() => _[FeatureName]PageWidgetState();
}

class _[FeatureName]PageWidgetState extends State<[FeatureName]PageWidget> {
  late [FeatureName]PageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => [FeatureName]PageModel());
    logFirebaseEvent('screen_view', parameters: {'screen_name': '[FeatureName]Page'});
  }

  @override
  Widget build(BuildContext context) {
    return YbLayout(
      scaffoldKey: scaffoldKey,
      title: "[功能名稱]",
      child: BlocBuilder<[FeatureName]Cubit, [FeatureName]State>(
        builder: (context, state) {
          if (state is [FeatureName]Loaded) {
            return [FeatureName]MainSection(data: state.detail);
          } else if (state is [FeatureName]Error) {
            return _buildErrorWidget(state.message);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        }
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("返回"),
          ),
        ],
      ),
    );
  }
}
```

## ✅ 最終檢查清單

### 必須完成項目
- [ ] 創建了 State 類別（Initial, Loaded, Error）
- [ ] 創建了 Cubit 類別並實作 `loadById` 方法
- [ ] 在 `nav.dart` 中配置了 `BlocProvider`
- [ ] Widget 使用 `BlocBuilder` 監聽狀態
- [ ] 處理了所有狀態（Loading, Loaded, Error）
- [ ] 添加了必要的 imports

### 可選但建議項目
- [ ] 創建對應的 Repository `getById` 方法
- [ ] 添加單元測試
- [ ] 添加 Widget 測試
- [ ] 更新文檔

## 🔗 導航使用範例

```dart
// 查看模式
context.go('/[featureName]/view/[id]');

// 編輯模式  
context.go('/[featureName]/edit/[id]');

// 新建模式
context.go('/[featureName]/create/');
```

## 🚨 常見錯誤提醒

❌ **絕對不要**：
- 在 Widget constructor 中載入數據
- 在 `initState` 中載入數據
- 使用 `addPostFrameCallback` 載入數據
- 忘記處理 Error 狀態

✅ **一定要**：
- 在 `BlocProvider.create` 中載入數據
- 處理所有可能的狀態
- 使用標準的錯誤處理模式
- 遵循單一職責原則

## 💡 實用提示

1. **複製現有範例**：參考 `student_detail_cubit` 的實作
2. **使用 IDE 模板**：可以創建 Live Template 加速開發
3. **統一命名**：遵循專案的命名慣例
4. **及時測試**：每完成一個步驟就測試一次

---

有問題？查看 [詳細最佳實踐文檔](../best_practices/page_navigation_and_state_management.md) 