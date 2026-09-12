/// 등락 방향입니다. 국내 관행대로 상승은 빨강, 하락은 파랑으로 그립니다.
enum PriceDirection {
  up,
  down,
  flat;

  static PriceDirection of(num change) {
    if (change > 0) return PriceDirection.up;
    if (change < 0) return PriceDirection.down;
    return PriceDirection.flat;
  }
}
