import 'dart:math';

class CoordTransform {
  static const double _pi = pi;
  static const double _a = 6378245.0;
  static const double _ee = 0.00669342162296594323;

  static bool _outOfChina(double lat, double lon) {
    if (lon < 72.004 || lon > 137.8347) {
      return true;
    }
    if (lat < 0.8293 || lat > 55.8271) {
      return true;
    }
    return false;
  }

  static double _transformLat(double x, double y) {
    double ret =
        -100.0 +
        2.0 * x +
        3.0 * y +
        0.2 * y * y +
        0.1 * x * y +
        0.2 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * _pi) + 20.0 * sin(2.0 * x * _pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * _pi) + 40.0 * sin(y / 3.0 * _pi)) * 2.0 / 3.0;
    ret +=
        (160.0 * sin(y / 12.0 * _pi) + 320 * sin(y * _pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double _transformLon(double x, double y) {
    double ret =
        300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * _pi) + 20.0 * sin(2.0 * x * _pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * _pi) + 40.0 * sin(x / 3.0 * _pi)) * 2.0 / 3.0;
    ret +=
        (150.0 * sin(x / 12.0 * _pi) + 300.0 * sin(x / 30.0 * _pi)) * 2.0 / 3.0;
    return ret;
  }

  /// Converts WGS84 coordinates to GCJ-02.
  static List<double> wgs84ToGcj02(double lat, double lon) {
    if (_outOfChina(lat, lon)) {
      return [lat, lon];
    }
    double dLat = _transformLat(lon - 105.0, lat - 35.0);
    double dLon = _transformLon(lon - 105.0, lat - 35.0);
    double radLat = lat / 180.0 * _pi;
    double magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * _pi);
    dLon = (dLon * 180.0) / (_a / sqrtMagic * cos(radLat) * _pi);
    double mgLat = lat + dLat;
    double mgLon = lon + dLon;
    return [mgLat, mgLon];
  }
}
