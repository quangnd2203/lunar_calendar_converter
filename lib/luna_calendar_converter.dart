library lunar_calendar_converter;

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xml2json/xml2json.dart';

import 'constants.dart';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;

enum Timezone {
  Chinese,
  Japanese,
  Korean,
  Vietnamese,
}

class LunaCalendarConverter {
  late final XmlDocument _nhiThapBatTuXml;
  late final XmlDocument _tuoiXungXml;
  late final List<Map<String, dynamic>> _listNgayHoangDaoHacDaoJson;
  late final Map<String, dynamic> _khongMinhLucDieuData;

  LunaCalendarConverter._();

  static LunaCalendarConverter? _instance;

  static Future<LunaCalendarConverter> instance() async {
    if (_instance == null) {
      _instance = LunaCalendarConverter._();
      await _instance!.init();
    }
    return _instance!;
  }

  Future<void> init() async {
    String dataString = '';
    dataString = await rootBundle.loadString('packages/luna_calendar_converter/assets/xmls/tb_thapnhibattu.xml');
    _nhiThapBatTuXml = XmlDocument.parse(dataString);
    dataString = await rootBundle.loadString('packages/luna_calendar_converter/assets/xmls/tb_tuoixung.xml');
    _tuoiXungXml = XmlDocument.parse(dataString);
    dataString = await rootBundle.loadString('packages/luna_calendar_converter/assets/jsons/ngayhoangdaohacdao.json');
    _listNgayHoangDaoHacDaoJson = (jsonDecode(dataString) as List<dynamic>).map<Map<String, dynamic>>((e) => e).toList();
    dataString = await rootBundle.loadString('packages/luna_calendar_converter/assets/jsons/khongminhlucdieu.json');
    _khongMinhLucDieuData = jsonDecode(dataString);
  }

  int INT(double value) {
    return value.floor();
  }

  Map<String, dynamic> getDateStar(DateTime date) {
    late int days;
    if (date.isBefore(dateStarMineStone)) {
      days = DateTimeRange(start: date, end: dateStarMineStone).duration.inDays;
      days = 29 - days % 28;
    } else {
      days = DateTimeRange(start: dateStarMineStone, end: date).duration.inDays;
      days = days % 28 + 1;
    }
    final starElements = _nhiThapBatTuXml.findAllElements('ROW').toList();
    final XmlElement element =
        starElements.firstWhere((e) => e.getElement('number')!.text == '$days');
    final Xml2Json xml2json = Xml2Json();
    xml2json.parse(element.toXmlString());
    return jsonDecode(xml2json.toGData());
  }

  //Chuyển đổi ngày tháng năm -> số ngày Julius
  int jdFromDate(int dd, int mm, int yy) {
    var a, y, m, jd;
    a = INT((14 - mm) / 12);
    y = yy + 4800 - a;
    m = mm + 12 * a - 3;
    jd = dd +
        INT((153 * m + 2) / 5) +
        365 * y +
        INT(y / 4) -
        INT(y / 100) +
        INT(y / 400) -
        32045;
    if (jd < 2299161) {
      jd = dd + INT((153 * m + 2) / 5) + 365 * y + INT(y / 4) - 32083;
    }
    return jd;
  }

  //Chuyển đổi số ngày Julius -> ngày tháng năm
  List<int?> jdToDate(int jd) {
    List<int?> result = new List.filled(3, null, growable: false);
    var a, b, c, d, e, m, day, month, year;
    if (jd > 2299160) {
      // After 5/10/1582, Gregorian calendar
      a = jd + 32044;
      b = INT((4 * a + 3) / 146097);
      c = a - INT((b * 146097) / 4);
    } else {
      b = 0;
      c = jd + 32082;
    }
    d = INT((4 * c + 3) / 1461);
    e = c - INT((1461 * d) / 4);
    m = INT((5 * e + 2) / 153);
    day = e - INT((153 * m + 2) / 5) + 1;
    month = m + 3 - 12 * INT(m / 10);
    year = b * 100 + d - 4800 + INT(m / 10);

    result[0] = day;
    result[1] = month;
    result[2] = year;

    return result;
  }

  //Tính ngày Sóc thứ k kể từ điểm Sóc ngày 1/1/1900.
  //Kết quả trả về là số ngày Julius của ngày Sóc cần tìm
  int getNewMoonDay(int k, int timeZone) {
    var T, T2, T3, dr, Jd1, M, Mpr, F, C1, deltat, JdNew;
    T = k / 1236.85; // Time in Julian centuries from 1900 January 0.5
    T2 = T * T;
    T3 = T2 * T;
    dr = pi / 180;
    Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
    Jd1 = Jd1 +
        0.00033 *
            sin((166.56 + 132.87 * T - 0.009173 * T2) * dr); // Mean new moon
    M = 359.2242 +
        29.10535608 * k -
        0.0000333 * T2 -
        0.00000347 * T3; // Sun's mean anomaly
    Mpr = 306.0253 +
        385.81691806 * k +
        0.0107306 * T2 +
        0.00001236 * T3; // Moon's mean anomaly
    F = 21.2964 +
        390.67050646 * k -
        0.0016528 * T2 -
        0.00000239 * T3; // Moon's argument of latitude
    C1 = (0.1734 - 0.000393 * T) * sin(M * dr) + 0.0021 * sin(2 * dr * M);
    C1 = C1 - 0.4068 * sin(Mpr * dr) + 0.0161 * sin(dr * 2 * Mpr);
    C1 = C1 - 0.0004 * sin(dr * 3 * Mpr);
    C1 = C1 + 0.0104 * sin(dr * 2 * F) - 0.0051 * sin(dr * (M + Mpr));
    C1 = C1 - 0.0074 * sin(dr * (M - Mpr)) + 0.0004 * sin(dr * (2 * F + M));
    C1 = C1 - 0.0004 * sin(dr * (2 * F - M)) - 0.0006 * sin(dr * (2 * F + Mpr));
    C1 = C1 +
        0.0010 * sin(dr * (2 * F - Mpr)) +
        0.0005 * sin(dr * (2 * Mpr + M));
    if (T < -11) {
      deltat = 0.001 +
          0.000839 * T +
          0.0002261 * T2 -
          0.00000845 * T3 -
          0.000000081 * T * T3;
    } else {
      deltat = -0.000278 + 0.000265 * T + 0.000262 * T2;
    }
    JdNew = Jd1 + C1 - deltat;
    return INT(JdNew + 0.5 + timeZone / 24);
  }

  //Tính tọa độ mặt trời để biết Trung khí nào nằm trong tháng âm lịch nào,
  //Tính xem mặt trời nằm ở khoảng nào trên đường hoàng đạo vào thời điểm bắt đầu một tháng âm lịch:
  //-chia đường hoàng đạo làm 12 phần và đánh số các cung này từ 0 đến 11: từ Xuân phân đến Cốc vũ là 0; từ Cốc vũ đến Tiểu mãn là 1; từ Tiểu mãn đến Hạ chí là 2; v.v..
  //-cho jdn là số ngày Julius của bất kỳ một ngày, phương pháp sau này sẽ trả lại số cung nói trên.
  int getSunLongitude(dayNumber, timeZone) {
    return INT(_getSunLongitude(dayNumber - 0.5 - timeZone / 24) / pi * 6);
  }

  int getSunLongitudeTietKhi(dayNumber, timeZone) {
    return INT(_getSunLongitude(dayNumber - 0.5 - timeZone / 24) / pi * 12);
  }

  num _getSunLongitude(jdn) {
    var T, T2, dr, M, L0, DL, L;
    T = (jdn - 2451545.0) /
        36525; // Time in Julian centuries from 2000-01-01 12:00:00 GMT
    T2 = T * T;
    dr = pi / 180; // degree to radian
    M = 357.52910 +
        35999.05030 * T -
        0.0001559 * T2 -
        0.00000048 * T * T2; // mean anomaly, degree
    L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2; // mean longitude, degree
    DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * sin(dr * M);
    DL = DL +
        (0.019993 - 0.000101 * T) * sin(dr * 2 * M) +
        0.000290 * sin(dr * 3 * M);
    L = L0 + DL; // true longitude, degree
    L = L * dr;
    L = L - pi * 2 * (INT(L / (pi * 2))); // Normalize to (0, 2*PI)
    return L;
  }

  //Tìm ngày bắt đầu tháng 11 âm lịch
  //Đông chí thường nằm vào khoảng 19/12-22/12, như vậy trước hết ta tìm ngày Sóc trước ngày 31/12.
  //Nếu tháng bắt đầu vào ngày đó không chứa Đông chí thì ta phải lùi lại 1 tháng nữa.
  int getLunarMonth11(int yy, int timeZone) {
    var k, off, nm, sunLong;
    off = jdFromDate(31, 12, yy) - 2415021;
    k = INT(off / 29.530588853);
    nm = getNewMoonDay(k, timeZone);
    sunLong = getSunLongitude(nm, timeZone); // sun longitude at local midnight
    if (sunLong >= 9) {
      nm = getNewMoonDay(k - 1, timeZone);
    }
    return nm;
  }

  //Xác định tháng nhuận
  //Nếu giữa hai tháng 11 âm lịch (tức tháng có chứa Đông chí) có 13 tháng âm lịch thì năm âm lịch đó có tháng nhuận.
  int? getLeapMonthOffset(int a11, int timeZone) {
    var k, last, arc, i;
    k = INT((a11 - 2415021.076998695) / 29.530588853 + 0.5);
    last = 0;
    i = 1; // We start with the month following lunar month 11
    arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    do {
      last = arc;
      i++;
      arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    } while (arc != last && i < 14);
    return i - 1;
  }

  //Get timezone by locate
  int getTimeZoneValue(Timezone timezone) {
    switch (timezone) {
      case Timezone.Chinese:
        return 8; //UTC +08
      case Timezone.Japanese:
        return 9; //UTC +09
      case Timezone.Korean:
        return 9; //UTC +09
      case Timezone.Vietnamese:
        return 7; //UTC +07
    }
  }

  //Convert solar day to lunar day
  List<int?> solarToLunar(
      int solarYear, int solarMonth, int solarDay, Timezone timezone) {
    List<int?> result = new List.filled(3, null, growable: false);

    var utcValue = getTimeZoneValue(timezone);
    var k,
        dayNumber,
        monthStart,
        a11,
        b11,
        lunarDay,
        lunarMonth,
        lunarYear,
        lunarLeap;
    dayNumber = jdFromDate(solarDay, solarMonth, solarYear);
    k = INT((dayNumber - 2415021.076998695) / 29.530588853);
    monthStart = getNewMoonDay(k + 1, utcValue);
    if (monthStart > dayNumber) {
      monthStart = getNewMoonDay(k, utcValue);
    }
    a11 = getLunarMonth11(solarYear, utcValue);
    b11 = a11;
    if (a11 >= monthStart) {
      lunarYear = solarYear;
      a11 = getLunarMonth11(solarYear - 1, utcValue);
    } else {
      lunarYear = solarYear + 1;
      b11 = getLunarMonth11(solarYear + 1, utcValue);
    }
    lunarDay = dayNumber - monthStart + 1;
    var diff = INT((monthStart - a11) / 29);
    lunarLeap = 0;
    lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      var leapMonthDiff = getLeapMonthOffset(a11, utcValue)!;
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        if (diff == leapMonthDiff) {
          lunarLeap = 1;
        }
      }
    }
    if (lunarMonth > 12) {
      lunarMonth = lunarMonth - 12;
    }
    if (lunarMonth >= 11 && diff < 4) {
      lunarYear -= 1;
    }

    result[0] = lunarDay;
    result[1] = lunarMonth;
    result[2] = lunarYear;

    return result;
  }

  //Convert lunar day to solar day
  List<int?> lunarToSolar(int lunarYear, int lunarMonth, int lunarDay,
      int lunarLeap, Timezone timezone) {
    List<int?> result = new List.filled(3, null, growable: false);

    var utcValue = getTimeZoneValue(timezone);
    var k, a11, b11, off, leapOff, leapMonth, monthStart;
    if (lunarMonth < 11) {
      a11 = getLunarMonth11(lunarYear - 1, utcValue);
      b11 = getLunarMonth11(lunarYear, utcValue);
    } else {
      a11 = getLunarMonth11(lunarYear, utcValue);
      b11 = getLunarMonth11(lunarYear + 1, utcValue);
    }
    off = lunarMonth - 11;
    if (off < 0) {
      off += 12;
    }
    if (b11 - a11 > 365) {
      leapOff = getLeapMonthOffset(a11, utcValue);
      leapMonth = leapOff - 2;
      if (leapMonth < 0) {
        leapMonth += 12;
      }
      if (lunarLeap != 0 && lunarMonth != leapMonth) {
        result[0] = 0;
        result[1] = 0;
        result[2] = 0;
      } else if (lunarLeap != 0 || off >= leapOff) {
        off += 1;
      }
    }
    k = INT(0.5 + (a11 - 2415021.076998695) / 29.530588853);
    monthStart = getNewMoonDay(k + off, utcValue);
    return jdToDate(monthStart + lunarDay - 1);
  }

  getCanChiYear(int year) {
    var can = canList[year % 10];
    var chi = chiList[year % 12];
    return '$can $chi';
  }

  getCanChiMonth(int month, int year) {
    var chi = chiForMonthList[month - 1];
    var indexCan = 0;
    var can = canList[year % 10];

    if (can == "Giáp" || can == "Kỉ") {
      indexCan = 6;
    }
    if (can == "Ất" || can == "Canh") {
      indexCan = 8;
    }
    if (can == "Bính" || can == "Tân") {
      indexCan = 0;
    }
    if (can == "Đinh" || can == "Nhâm") {
      indexCan = 2;
    }
    if (can == "Mậu" || can == "Quý") {
      indexCan = 4;
    }
    return '${canList[(indexCan + month - 1) % 10]} $chi';
  }

  getYearCanChi(year) {
    return CAN[(year + 6) % 10] + " " + CHI[(year + 8) % 12];
  }

  getCanHour(jdn) {
    return CAN[(jdn - 1) * 2 % 10];
  }

  getCanDay(jdn) {
    var dayName, monthName, yearName;
    dayName = CAN[(jdn + 9) % 10] + " " + CHI[(jdn + 1) % 12];
    return dayName;
  }

  //Tính tuổi xung khắc
  String getCounterAgeOfDay(jdn) {
    var dayName = CAN[(jdn + 9) % 10] + " " + CHI[(jdn + 1) % 12];
    final starElements = _tuoiXungXml.findAllElements('ROW').toList();
    final XmlElement element = starElements
        .firstWhere((e) => e.getElement('ngay')!.text == '$dayName');
    return element.getElement('tuoixung')!.text;
  }

  Map<String, dynamic> getLucDieuDay(int lunarDay, int lunarMonth){
    assert (lunarDay > 0);
    assert (lunarMonth > 0 || lunarMonth < 13);
    int idLucDieuFirstDayOfMonth = (_khongMinhLucDieuData['dataMonth'] as List).firstWhere((e) => e['month'].contains(lunarMonth))['firstDay'];
    int remainder = lunarDay % 6 - 1;
    int dayId = remainder == 0 ? idLucDieuFirstDayOfMonth : idLucDieuFirstDayOfMonth + remainder;
    return (_khongMinhLucDieuData['dataDay'] as List).firstWhere((e) => e['id'] == (dayId > 6 ? dayId - 6 : dayId));
  }

  Map<String, dynamic> getLucDieuOfMonthData(int lunarMonth){
    assert (lunarMonth > 0 || lunarMonth < 13);
    return (_khongMinhLucDieuData['dataMonth'] as List).firstWhere((e) => e['month'].contains(lunarMonth));
  }

  List<Map<String, dynamic>> getAllLucDieuData(){
    return (_khongMinhLucDieuData['dataDay'] as List).map<Map<String, dynamic>>((e) => e).toList();
  }

  List<String> getHours(int jd, {bool isGoodDay = true}) {
    final int chiOfDay = (jd + 1) % 12;
    final int beginCanOffset = (jd - 1) * 2 % 10;
    final gioHD = GIO_HD[chiOfDay %
        6]; // same values for Ty' (1) and Ngo. (6), for Suu and Mui etc.
    final List<String> result = [];
    for (int i = 0; i < 12; i++) {
      final String item =
          '${CAN[(i + beginCanOffset) % 10]} ${CHI[i]} (${(i * 2 + 23) % 24}h-${(i * 2 + 1) % 24}h)';
      final bool condition =
          gioHD.substring(i, i + 1) == (isGoodDay ? '1' : '0');
      if (condition) {
        result.add(item);
      }
    }
    return result;
  }

  List<Map<String, dynamic>> getGoodBadDays(int month,
      {bool isGoodDay = true}) {
    return _listNgayHoangDaoHacDaoJson
        .firstWhere((e) => e['thang'].contains(month))[isGoodDay ? 'hoangDao' : 'hacDao']
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  getTietKhi(jd) {
    return TIETKHI[getSunLongitudeTietKhi(jd + 1, 7.0)];
  }

  getBeginHour(jdn) {
    return CAN[(jdn - 1) * 2 % 10] + ' ' + CHI[0];
  }

  jdn(dd, mm, yy) {
    var a = INT((14 - mm) / 12);
    var y = yy + 4800 - a;
    var m = mm + 12 * a - 3;
    var jd = dd +
        INT((153 * m + 2) / 5) +
        365 * y +
        INT(y / 4) -
        INT(y / 100) +
        INT(y / 400) -
        32045;
    return jd;
  }


}
