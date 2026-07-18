/// Supported display currencies (amounts stay unitless; only formatting changes).
class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
    this.locale = 'en_US',
    this.decimalDigits = 2,
  });

  final String code;
  final String symbol;
  final String name;
  final String locale;
  final int decimalDigits;

  String get label => '$code · $symbol';

  static const usd = AppCurrency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    locale: 'en_US',
  );
  static const eur = AppCurrency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    locale: 'de_DE',
  );
  static const gbp = AppCurrency(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    locale: 'en_GB',
  );
  static const inr = AppCurrency(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    locale: 'en_IN',
  );
  static const jpy = AppCurrency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    locale: 'ja_JP',
    decimalDigits: 0,
  );
  static const cad = AppCurrency(
    code: 'CAD',
    symbol: 'CA\$',
    name: 'Canadian Dollar',
    locale: 'en_CA',
  );
  static const aud = AppCurrency(
    code: 'AUD',
    symbol: 'A\$',
    name: 'Australian Dollar',
    locale: 'en_AU',
  );
  static const chf = AppCurrency(
    code: 'CHF',
    symbol: 'CHF',
    name: 'Swiss Franc',
    locale: 'de_CH',
  );
  static const cny = AppCurrency(
    code: 'CNY',
    symbol: '¥',
    name: 'Chinese Yuan',
    locale: 'zh_CN',
  );
  static const aed = AppCurrency(
    code: 'AED',
    symbol: 'د.إ',
    name: 'UAE Dirham',
    locale: 'ar_AE',
  );
  static const sgd = AppCurrency(
    code: 'SGD',
    symbol: 'S\$',
    name: 'Singapore Dollar',
    locale: 'en_SG',
  );
  static const krw = AppCurrency(
    code: 'KRW',
    symbol: '₩',
    name: 'South Korean Won',
    locale: 'ko_KR',
    decimalDigits: 0,
  );
  static const brl = AppCurrency(
    code: 'BRL',
    symbol: 'R\$',
    name: 'Brazilian Real',
    locale: 'pt_BR',
  );
  static const mxn = AppCurrency(
    code: 'MXN',
    symbol: 'MX\$',
    name: 'Mexican Peso',
    locale: 'es_MX',
  );
  static const zar = AppCurrency(
    code: 'ZAR',
    symbol: 'R',
    name: 'South African Rand',
    locale: 'en_ZA',
  );
  static const try_ = AppCurrency(
    code: 'TRY',
    symbol: '₺',
    name: 'Turkish Lira',
    locale: 'tr_TR',
  );
  static const rub = AppCurrency(
    code: 'RUB',
    symbol: '₽',
    name: 'Russian Ruble',
    locale: 'ru_RU',
  );
  static const sek = AppCurrency(
    code: 'SEK',
    symbol: 'kr',
    name: 'Swedish Krona',
    locale: 'sv_SE',
  );
  static const nok = AppCurrency(
    code: 'NOK',
    symbol: 'kr',
    name: 'Norwegian Krone',
    locale: 'nb_NO',
  );
  static const dkk = AppCurrency(
    code: 'DKK',
    symbol: 'kr',
    name: 'Danish Krone',
    locale: 'da_DK',
  );
  static const pln = AppCurrency(
    code: 'PLN',
    symbol: 'zł',
    name: 'Polish Zloty',
    locale: 'pl_PL',
  );
  static const nzd = AppCurrency(
    code: 'NZD',
    symbol: 'NZ\$',
    name: 'New Zealand Dollar',
    locale: 'en_NZ',
  );
  static const hkd = AppCurrency(
    code: 'HKD',
    symbol: 'HK\$',
    name: 'Hong Kong Dollar',
    locale: 'zh_HK',
  );
  static const thr = AppCurrency(
    code: 'THB',
    symbol: '฿',
    name: 'Thai Baht',
    locale: 'th_TH',
  );
  static const idr = AppCurrency(
    code: 'IDR',
    symbol: 'Rp',
    name: 'Indonesian Rupiah',
    locale: 'id_ID',
    decimalDigits: 0,
  );
  static const php = AppCurrency(
    code: 'PHP',
    symbol: '₱',
    name: 'Philippine Peso',
    locale: 'en_PH',
  );
  static const myr = AppCurrency(
    code: 'MYR',
    symbol: 'RM',
    name: 'Malaysian Ringgit',
    locale: 'ms_MY',
  );
  static const pkr = AppCurrency(
    code: 'PKR',
    symbol: 'Rs',
    name: 'Pakistani Rupee',
    locale: 'en_PK',
  );
  static const bdt = AppCurrency(
    code: 'BDT',
    symbol: '৳',
    name: 'Bangladeshi Taka',
    locale: 'bn_BD',
  );
  static const ngn = AppCurrency(
    code: 'NGN',
    symbol: '₦',
    name: 'Nigerian Naira',
    locale: 'en_NG',
  );

  /// Curated list shown in Settings.
  static const List<AppCurrency> supported = [
    usd,
    eur,
    gbp,
    inr,
    jpy,
    cad,
    aud,
    chf,
    cny,
    aed,
    sgd,
    krw,
    brl,
    mxn,
    zar,
    try_,
    rub,
    sek,
    nok,
    dkk,
    pln,
    nzd,
    hkd,
    thr,
    idr,
    php,
    myr,
    pkr,
    bdt,
    ngn,
  ];

  static AppCurrency fromCode(String? code) {
    if (code == null || code.isEmpty) return usd;
    for (final c in supported) {
      if (c.code == code) return c;
    }
    return usd;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppCurrency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
