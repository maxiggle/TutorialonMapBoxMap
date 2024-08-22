class AirPorts {
  String thumbImage;
  List<Media> media;
  List<Interest> interest;
  String code;
  String lat;
  String lon;
  String name;
  String city;
  String state;
  Country country;
  String? woeid;
  Tz? tz;
  String? phone;
  AirPortType? type;
  String? email;
  String? url;
  String? runwayLength;
  String? elev;
  String? icao;
  String? directFlights;
  String? carriers;

  AirPorts({
    required this.thumbImage,
    required this.media,
    required this.interest,
    required this.code,
    required this.lat,
    required this.lon,
    required this.name,
    required this.city,
    required this.state,
    required this.country,
    this.woeid,
    this.tz,
    this.phone,
    this.type,
    this.email,
    this.url,
    this.runwayLength,
    this.elev,
    this.icao,
    this.directFlights,
    this.carriers,
  });

  factory AirPorts.fromJson(Map<String, dynamic> json) => AirPorts(
        thumbImage: json["thumbImage"],
        media: List<Media>.from(json["media"].map((x) => Media.fromJson(x))),
        interest: List<Interest>.from(
            json["interest"].map((x) => Interest.fromJson(x))),
        code: json["code"],
        lat: json["lat"],
        lon: json["lon"],
        name: json["name"],
        city: json["city"],
        state: json["state"],
        country: countryValues.map[json["country"]]!,
        woeid: json["woeid"],
        tz: tzValues.map[json["tz"]]!,
        phone: json["phone"],
        type: airPortTypeValues.map[json["type"]]!,
        email: json["email"],
        url: json["url"],
        runwayLength: json["runway_length"],
        elev: json["elev"],
        icao: json["icao"],
        directFlights: json["direct_flights"],
        carriers: json["carriers"],
      );

  Map<String, dynamic> toJson() => {
        "thumbImage": thumbImage,
        "media": List<dynamic>.from(media.map((x) => x.toJson())),
        "interest": List<dynamic>.from(interest.map((x) => x.toJson())),
        "code": code,
        "lat": lat,
        "lon": lon,
        "name": name,
        "city": city,
        "state": state,
        "country": countryValues.reverse[country],
        "woeid": woeid,
        "tz": tzValues.reverse[tz],
        "phone": phone,
        "type": airPortTypeValues.reverse[type],
        "email": email,
        "url": url,
        "runway_length": runwayLength,
        "elev": elev,
        "icao": icao,
        "direct_flights": directFlights,
        "carriers": carriers,
      };
}

enum Country { JAPAN }

final countryValues = EnumValues({"Japan": Country.JAPAN});

class Interest {
  String id;
  String name;

  Interest({
    required this.id,
    required this.name,
  });

  factory Interest.fromJson(Map<String, dynamic> json) => Interest(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class Media {
  MediaType type;
  bool liked;
  String src;
  List<String>? tags;

  Media({
    required this.type,
    required this.liked,
    required this.src,
    this.tags,
  });

  factory Media.fromJson(Map<String, dynamic> json) => Media(
        type: mediaTypeValues.map[json["type"]]!,
        liked: json["liked"],
        src: json["src"],
        tags: json["tags"] == null
            ? []
            : List<String>.from(json["tags"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "type": mediaTypeValues.reverse[type],
        "liked": liked,
        "src": src,
        "tags": tags == null ? [] : List<dynamic>.from(tags!.map((x) => x)),
      };
}

enum MediaType { IMAGE }

final mediaTypeValues = EnumValues({"image": MediaType.IMAGE});

enum AirPortType { AIRPORTS }

final airPortTypeValues = EnumValues({"Airports": AirPortType.AIRPORTS});

enum Tz { ASIA_TOKYO }

final tzValues = EnumValues({"Asia/Tokyo": Tz.ASIA_TOKYO});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
