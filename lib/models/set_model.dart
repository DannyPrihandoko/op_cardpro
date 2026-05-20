class SetModel {
  final String setCode;
  final String seriesId;
  final String name;
  final String type;
  final String releaseDate;
  final String productPage;
  final String cardlistUrl;
  final SetImages images;
  final int totalCards;
  final bool scraped;

  SetModel({
    required this.setCode,
    required this.seriesId,
    required this.name,
    required this.type,
    required this.releaseDate,
    required this.productPage,
    required this.cardlistUrl,
    required this.images,
    required this.totalCards,
    required this.scraped,
  });

  factory SetModel.fromJson(String setCode, Map<String, dynamic> json) {
    return SetModel(
      setCode: setCode,
      seriesId: json['series_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      releaseDate: json['release_date'] ?? '',
      productPage: json['product_page'] ?? '',
      cardlistUrl: json['cardlist_url'] ?? '',
      images: SetImages.fromJson(json['images'] ?? {}),
      totalCards: json['total_cards'] ?? 0,
      scraped: json['scraped'] ?? false,
    );
  }
}

class SetImages {
  final String boxImage;
  final String bannerImage;
  final String bgImage;
  final String cardsFolder;

  SetImages({
    required this.boxImage,
    required this.bannerImage,
    required this.bgImage,
    required this.cardsFolder,
  });

  factory SetImages.fromJson(Map<String, dynamic> json) {
    return SetImages(
      boxImage: json['box_image'] ?? '',
      bannerImage: json['banner_image'] ?? '',
      bgImage: json['bg_image'] ?? '',
      cardsFolder: json['cards_folder'] ?? '',
    );
  }
}
