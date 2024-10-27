import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['zh_Hant', 'en'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? zh_HantText = '',
    String? enText = '',
  }) =>
      [zh_HantText, enText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // StudyInfo
  {
    'qukodrez': {
      'zh_Hant': '姓名',
      'en': 'Name',
    },
    'pxpkwmtv': {
      'zh_Hant': '性別',
      'en': '',
    },
    'b1b2yyng': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'wdnkcpuf': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    '4qy6fm2p': {
      'zh_Hant': 'y',
      'en': '',
    },
    'me2a2pcf': {
      'zh_Hant': 'n',
      'en': '',
    },
    '2aj8x90c': {
      'zh_Hant': '出生年月日',
      'en': '',
    },
    '61nlqlbb': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'ehkmcx4e': {
      'zh_Hant': '身分證字號',
      'en': '',
    },
    '1xwg60lz': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'vp6mbhxc': {
      'zh_Hant': '家用電話',
      'en': '',
    },
    'q7ue1aog': {
      'zh_Hant': '手機',
      'en': '',
    },
    'dwz6wzi0': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    '3om79a5e': {
      'zh_Hant': '住址',
      'en': '',
    },
    'vbxjteyv': {
      'zh_Hant': '學校',
      'en': '',
    },
    'r61x37qr': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'y04f81fb': {
      'zh_Hant': '電子郵件',
      'en': '',
    },
    'lm0exysg': {
      'zh_Hant': '父親姓名',
      'en': '',
    },
    'z289wxrr': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'vh5r2ssd': {
      'zh_Hant': '父親身分證',
      'en': '',
    },
    '4pz65111': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'wwwdr9hm': {
      'zh_Hant': '任職公司/單位',
      'en': '',
    },
    '63zcl7sw': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'm2sb0yrx': {
      'zh_Hant': '父親電話',
      'en': '',
    },
    'pptd1mzf': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'qi4b1ion': {
      'zh_Hant': '父親電子郵件',
      'en': '',
    },
    '1p4bi9ti': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'bklsa13y': {
      'zh_Hant': '母親姓名',
      'en': '',
    },
    'giqcgte0': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'kvv7k8w2': {
      'zh_Hant': '母親身分證',
      'en': '',
    },
    '2jr7ucnx': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'df9jmqmi': {
      'zh_Hant': '任職公司/單位',
      'en': '',
    },
    '9tukr0cl': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'haslnhy1': {
      'zh_Hant': '母親電話',
      'en': '',
    },
    'roran2a4': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'vaoemhcm': {
      'zh_Hant': '母親電子郵件',
      'en': '',
    },
    '45kjmd9a': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    '9m1a336b': {
      'zh_Hant': '緊急聯絡人姓名',
      'en': '',
    },
    '80wd6hka': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    '4uo04s0i': {
      'zh_Hant': '緊急聯絡人身分證',
      'en': '',
    },
    'jee4emyj': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'h9xq2qny': {
      'zh_Hant': '任職公司/單位',
      'en': '',
    },
    'belabm75': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'kenwp2h4': {
      'zh_Hant': '緊急聯絡人電話',
      'en': '',
    },
    '0fmtpgf8': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    '65xysoml': {
      'zh_Hant': '緊急聯絡人電子郵件',
      'en': '',
    },
    'q8nsr4ec': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    '6zi5qo32': {
      'zh_Hant': '是否有特殊疾病        ',
      'en': '',
    },
    'f4niuqwz': {
      'zh_Hant': '是',
      'en': '',
    },
    'l7jhpq5v': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'vk6ovepx': {
      'zh_Hant': '否',
      'en': '',
    },
    '6ed78cym': {
      'zh_Hant': '是否為特殊學生        ',
      'en': '',
    },
    't2slwhjg': {
      'zh_Hant': '是',
      'en': '',
    },
    'a9u3qntk': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    '4uje24eq': {
      'zh_Hant': '否',
      'en': '',
    },
    '1whtn0z4': {
      'zh_Hant': '是否需要接送           ',
      'en': '',
    },
    'hxe9m81l': {
      'zh_Hant': '是',
      'en': '',
    },
    'bcr243n8': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    '877kyifw': {
      'zh_Hant': '否',
      'en': '',
    },
    '0x82hy8e': {
      'zh_Hant': '雙親狀況',
      'en': '',
    },
    'bfl909wu': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    'y4li65ql': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'nc3z8dpv': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    'giaopih3': {
      'zh_Hant': '家庭狀況',
      'en': '',
    },
    'dcicju5i': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    'j6ehqw7e': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'iepgzq4k': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    '0tn09jqb': {
      'zh_Hant': '興趣       ',
      'en': '',
    },
    '2l4wy4rp': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    'k1z1k05l': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'zwd08m5j': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    '5da8h2om': {
      'zh_Hant': '個性       ',
      'en': '',
    },
    'nn40uiei': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    '6on7n8cx': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'zc4nwpr9': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    '92nlsc15': {
      'zh_Hant': '身心狀態',
      'en': '',
    },
    'oemjewt1': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    'k5ihvqwk': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'b7l9a4m1': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    'e01onku4': {
      'zh_Hant': '社交技巧',
      'en': '',
    },
    'alrovuro': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    'ee0qyq6m': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'urniwf3g': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    '3o5eq0jb': {
      'zh_Hant': '能力評估',
      'en': '',
    },
    '2s4lyato': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    'lb61qlu4': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'dmwx9hzr': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    'geqccbup': {
      'zh_Hant': '學習目標',
      'en': '',
    },
    'f36t7e4o': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    '6uo4w5qc': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'fvlnxe9r': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    '7o8abj3n': {
      'zh_Hant': '物資及獎助學金',
      'en': '',
    },
    'gp26mxh6': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    'wsu34663': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'qg0hpf2n': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    'oowk9369': {
      'zh_Hant': '主任、老師、社工相關',
      'en': '',
    },
    '0dp53i30': {
      'zh_Hant': '新增大類1',
      'en': '',
    },
    'ncfz3f1l': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    'km3y59um': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'ezuevt25': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    'g03h4q73': {
      'zh_Hant': '新增大類2',
      'en': '',
    },
    '8am2yus6': {
      'zh_Hant': 'Option 1',
      'en': '',
    },
    'v4kt7lle': {
      'zh_Hant': 'Please select...',
      'en': '',
    },
    'ubxkuk0e': {
      'zh_Hant': 'Search for an item...',
      'en': '',
    },
    'kzixsus6': {
      'zh_Hant': '新增大類3',
      'en': '',
    },
    'kdbnkrwl': {
      'zh_Hant': '新增大類4',
      'en': '',
    },
    'j38vvchn': {
      'zh_Hant': '備註',
      'en': '',
    },
    'nsbqkebn': {
      'zh_Hant': '學生資料表',
      'en': '',
    },
    'tm4grday': {
      'zh_Hant': 'Home',
      'en': '',
    },
  },
  // queryPage
  {
    'dv9z7es2': {
      'zh_Hant': '姓名',
      'en': '',
    },
    'cm3xgk8n': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    '2pucsupt': {
      'zh_Hant': '出生年月日',
      'en': '',
    },
    'k97roq67': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'a9dxvmj8': {
      'zh_Hant': 'Submit\n',
      'en': '',
    },
    '8ys5sqnb': {
      'zh_Hant': 'Field is required',
      'en': '',
    },
    'u77neefp': {
      'zh_Hant': 'Please choose an option from the dropdown',
      'en': '',
    },
    '0pnh7owf': {
      'zh_Hant': 'Field is required',
      'en': '',
    },
    '0ls9fbpf': {
      'zh_Hant': 'Please choose an option from the dropdown',
      'en': '',
    },
    'sb5mh90g': {
      'zh_Hant': 'Home',
      'en': 'Student Information',
    },
  },
  // test_feild_exp
  {
    'zr9j582k': {
      'zh_Hant': 'Page Title',
      'en': '',
    },
    '27emrxix': {
      'zh_Hant': 'Home',
      'en': 'Student Information',
    },
  },
  // Details38TransactionHistoryResponsive
  {
    'qo65x6ds': {
      'zh_Hant': 'Order Details',
      'en': '',
    },
  },
  // YellowRibbonTextField
  {
    'g3ve3hpf': {
      'zh_Hant': '',
      'en': 'Setting',
    },
  },
  // Miscellaneous
  {
    'mzke8nrn': {
      'zh_Hant': 'Label here...',
      'en': '',
    },
    'oifhcvcp': {
      'zh_Hant': '通知功能需要啟用通知權限',
      'en': 'please open notifcation',
    },
    's5ce57eu': {
      'zh_Hant': '',
      'en': '',
    },
    'biy6ro59': {
      'zh_Hant': '',
      'en': '',
    },
    '0f0c5v71': {
      'zh_Hant': '',
      'en': '',
    },
    'atghsbks': {
      'zh_Hant': '',
      'en': '',
    },
    'e1f7glpo': {
      'zh_Hant': '',
      'en': '',
    },
    'lrczwtfc': {
      'zh_Hant': '',
      'en': '',
    },
    'eib1cako': {
      'zh_Hant': '',
      'en': '',
    },
    'ht3thqvx': {
      'zh_Hant': '',
      'en': '',
    },
    '3w1lr1rz': {
      'zh_Hant': '',
      'en': '',
    },
    '44ynvmyt': {
      'zh_Hant': '',
      'en': '',
    },
    '4fua6oue': {
      'zh_Hant': '',
      'en': '',
    },
    'w4wjwwmf': {
      'zh_Hant': '',
      'en': '',
    },
    'fnzebac5': {
      'zh_Hant': '',
      'en': '',
    },
    'on3kgvai': {
      'zh_Hant': '',
      'en': '',
    },
    '33lfe94o': {
      'zh_Hant': '',
      'en': '',
    },
    'rzo79h6n': {
      'zh_Hant': '',
      'en': '',
    },
    'seinx1ox': {
      'zh_Hant': '',
      'en': '',
    },
    'xuxn0mas': {
      'zh_Hant': '',
      'en': '',
    },
    'y6ibzt08': {
      'zh_Hant': '',
      'en': '',
    },
    'hip9fcjw': {
      'zh_Hant': '',
      'en': '',
    },
    '5mumrpid': {
      'zh_Hant': '',
      'en': '',
    },
    'hi1wus54': {
      'zh_Hant': '',
      'en': '',
    },
    '6fjzj2q9': {
      'zh_Hant': '',
      'en': '',
    },
    'atvrbbi0': {
      'zh_Hant': '',
      'en': '',
    },
    '8muthvtx': {
      'zh_Hant': '',
      'en': '',
    },
  },
].reduce((a, b) => a..addAll(b));
