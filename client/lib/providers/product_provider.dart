import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  // --- Step 1: Core Details ---
  String name = '';
  String shortDescription = '';
  String description = '';
  String category = '';
  String brand = '';
  String hsnCode = '';
  String sku = '';
  String countryOfOrigin = '';
  
  List<(String, Uint8List)> images = [];

  // --- Step 2: Pricing & Stock ---
  double regularPrice = 0.0;
  double? salePrice;
  int stockQuantity = 0;
  
  double? weightKg;
  double? lengthCm;
  double? widthCm;
  double? heightCm;

  // --- Step 3: Channels ---
  // WooCommerce
  bool wooEnabled = false;
  bool wooUseCustomPrice = false;
  double? wooCustomPrice;
  String wooCatalogVisibility = 'visible';

  // ONDC
  bool ondcEnabled = false;
  bool ondcReturnable = true;
  bool ondcCancellable = true;
  bool ondcUseCustomPrice = false;
  double? ondcCustomPrice;
  String? ondcFulfillmentType;
  String ondcTimeToShip = '';
  String ondcCityCode = '';
  String? ondcLocationId;
  String ondcWarranty = '';

  // --- Actions ---

  void updateCore({
    String? name,
    String? shortDescription,
    String? description,
    String? category,
    String? brand,
    String? hsnCode,
    String? sku,
    String? countryOfOrigin,
  }) {
    if (name != null) this.name = name;
    if (shortDescription != null) this.shortDescription = shortDescription;
    if (description != null) this.description = description;
    if (category != null) this.category = category;
    if (brand != null) this.brand = brand;
    if (hsnCode != null) this.hsnCode = hsnCode;
    if (sku != null) this.sku = sku;
    if (countryOfOrigin != null) this.countryOfOrigin = countryOfOrigin;
    notifyListeners();
  }

  void setImages(List<(String, Uint8List)> newImages) {
    images = newImages;
    notifyListeners();
  }

  void updatePricing({
    double? regularPrice,
    double? salePrice,
    int? stockQuantity,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
  }) {
    if (regularPrice != null) this.regularPrice = regularPrice;
    this.salePrice = salePrice; // Nullable update
    if (stockQuantity != null) this.stockQuantity = stockQuantity;
    this.weightKg = weightKg;
    this.lengthCm = lengthCm;
    this.widthCm = widthCm;
    this.heightCm = heightCm;
    notifyListeners();
  }

  void updateWoo({
    bool? enabled,
    bool? useCustomPrice,
    double? customPrice,
    String? catalogVisibility,
  }) {
    if (enabled != null) wooEnabled = enabled;
    if (useCustomPrice != null) wooUseCustomPrice = useCustomPrice;
    this.wooCustomPrice = customPrice;
    if (catalogVisibility != null) wooCatalogVisibility = catalogVisibility;
    notifyListeners();
  }

  void updateOndc({
    bool? enabled,
    bool? returnable,
    bool? cancellable,
    bool? useCustomPrice,
    double? customPrice,
    String? fulfillmentType,
    String? timeToShip,
    String? cityCode,
    String? locationId,
    String? warranty,
  }) {
    if (enabled != null) ondcEnabled = enabled;
    if (returnable != null) ondcReturnable = returnable;
    if (cancellable != null) ondcCancellable = cancellable;
    if (useCustomPrice != null) ondcUseCustomPrice = useCustomPrice;
    this.ondcCustomPrice = customPrice;
    this.ondcFulfillmentType = fulfillmentType;
    if (timeToShip != null) ondcTimeToShip = timeToShip;
    if (cityCode != null) ondcCityCode = cityCode;
    this.ondcLocationId = locationId;
    if (warranty != null) ondcWarranty = warranty;
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    try {
      // Construct Data Map
      final data = {
        'name': name,
        'short_description': shortDescription,
        'description': description,
        'sku': sku,
        'brand': brand,
        'hsn_code': hsnCode,
        'country_of_origin': countryOfOrigin,
        'category_name': category,
        
        'regular_price': regularPrice,
        'sale_price': salePrice,
        'stock_quantity': stockQuantity,
        
        'weight_kg': weightKg,
        'length_cm': lengthCm,
        'width_cm': widthCm,
        'height_cm': heightCm,

        'woo': {
          'enabled': wooEnabled,
          'custom_price': wooUseCustomPrice ? wooCustomPrice : null,
          'catalog_visibility': wooCatalogVisibility,
        },
        'ondc': {
          'enabled': ondcEnabled,
          'returnable': ondcReturnable,
          'cancellable': ondcCancellable,
          'custom_price': ondcUseCustomPrice ? ondcCustomPrice : null,
          'fulfillment_type': ondcFulfillmentType,
          'time_to_ship': ondcTimeToShip,
          'city_code': ondcCityCode,
          'warranty': ondcWarranty,
          // location_id is not in backend DTO yet, but can be added later
        }
      };

      await _service.createProduct(data, images);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully!')),
      );
      
      // Navigate back to product list or dashboard
      // Assuming we are in a stack, pop until we are out of the add flow
      // Or just pop once if that's how it was entered.
      // Ideally, pop to root or products screen.
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
