/// Safe, actionable messages shared by cloud and offline adapters.
/// An unknown response must never be presented as a confirmed failed write.
class RosterCommandFailure implements Exception {
  final String code;
  final bool previousOutcomeUnknown;
  const RosterCommandFailure(this.code, {this.previousOutcomeUnknown = false});

  bool get conflict => code == 'aborted' && !previousOutcomeUnknown;
  bool get outcomeUnknown =>
      previousOutcomeUnknown ||
      !const {
        'aborted',
        'permission-denied',
        'unauthenticated',
        'invalid-argument',
        'failed-precondition',
        'not-found',
        'already-exists',
        'same-day-enrollment',
      }.contains(code);

  String get message {
    if (previousOutcomeUnknown) {
      return '原儲存結果尚未確認，本次重試也未能取得確認。請保留此頁；確認原帳號、網路及操作權限後再重試，或聯絡管理者協助核對。';
    }
    switch (code) {
      case 'aborted':
        return '儲存失敗：資料已被其他人修改。你的修改仍保留，請核對雲端內容後再儲存。';
      case 'permission-denied':
        return '儲存失敗：目前沒有操作權限。你的修改仍保留，請聯絡管理者確認權限。';
      case 'unauthenticated':
        return '儲存失敗：登入狀態已失效。請重新登入原帳號後確認並重試。';
      case 'invalid-argument':
        return '儲存失敗：資料格式或必填內容不符合要求。請檢查本筆內容後再儲存。';
      case 'failed-precondition':
        return '儲存失敗：目前的課次、就讀關係或系統狀態不允許此操作。請重新載入並核對；修改仍保留。';
      case 'not-found':
        return '儲存失敗：找不到對應資料。請重新載入名冊並核對；修改仍保留。';
      case 'already-exists':
        return '儲存失敗：操作資料不一致。請保留此頁並聯絡管理者協助核對。';
      case 'same-day-enrollment':
        return '無法執行：這位學生今天才入班，離班或轉據點最早要從明天開始生效。若是建錯資料，請聯絡管理者處理。';
      default:
        return '尚未確認是否儲存成功：未取得伺服器確認。修改仍保留，請確認網路後按「重試儲存」確認結果，勿重新建立相同紀錄。';
    }
  }

  @override
  String toString() => message;
}
