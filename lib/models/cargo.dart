/// A unit of cargo on a ship or in a warehouse.
class Cargo {
  final String commodityId;
  final int quantity;

  const Cargo({
    required this.commodityId,
    required this.quantity,
  });

  Cargo copyWith({String? commodityId, int? quantity}) {
    return Cargo(
      commodityId: commodityId ?? this.commodityId,
      quantity: quantity ?? this.quantity,
    );
  }
}
