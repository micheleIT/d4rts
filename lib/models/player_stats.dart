class PlayerStats {
  final String playerName;
  double threeDartAverage;
  double firstNineAverage;
  double checkoutPercentage;
  int highestCheckout;
  int count180s;
  int count140plus;
  int count100plus;
  int bestLegDarts;
  int worstLegDarts;
  int gamesPlayed;
  int gamesWon;
  int legsPlayed;
  int legsWon;

  PlayerStats({
    required this.playerName,
    this.threeDartAverage = 0.0,
    this.firstNineAverage = 0.0,
    this.checkoutPercentage = 0.0,
    this.highestCheckout = 0,
    this.count180s = 0,
    this.count140plus = 0,
    this.count100plus = 0,
    this.bestLegDarts = 0,
    this.worstLegDarts = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.legsPlayed = 0,
    this.legsWon = 0,
  });

  Map<String, dynamic> toJson() => {
        'playerName': playerName,
        'threeDartAverage': threeDartAverage,
        'firstNineAverage': firstNineAverage,
        'checkoutPercentage': checkoutPercentage,
        'highestCheckout': highestCheckout,
        'count180s': count180s,
        'count140plus': count140plus,
        'count100plus': count100plus,
        'bestLegDarts': bestLegDarts,
        'worstLegDarts': worstLegDarts,
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'legsPlayed': legsPlayed,
        'legsWon': legsWon,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        playerName: json['playerName'] as String,
        threeDartAverage: (json['threeDartAverage'] as num).toDouble(),
        firstNineAverage: (json['firstNineAverage'] as num).toDouble(),
        checkoutPercentage: (json['checkoutPercentage'] as num).toDouble(),
        highestCheckout: json['highestCheckout'] as int,
        count180s: json['count180s'] as int,
        count140plus: json['count140plus'] as int,
        count100plus: json['count100plus'] as int,
        bestLegDarts: json['bestLegDarts'] as int,
        worstLegDarts: json['worstLegDarts'] as int,
        gamesPlayed: json['gamesPlayed'] as int,
        gamesWon: json['gamesWon'] as int,
        legsPlayed: json['legsPlayed'] as int,
        legsWon: json['legsWon'] as int,
      );
}
