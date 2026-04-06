class Player {
  final String name;

  const Player({required this.name});

  @override
  bool operator ==(Object other) =>
      other is Player && other.name.toLowerCase() == name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;

  @override
  String toString() => name;

  Map<String, dynamic> toJson() => {'name': name};

  factory Player.fromJson(Map<String, dynamic> json) =>
      Player(name: json['name'] as String);
}
