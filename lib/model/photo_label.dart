class PhotoLabel {
  final String label;
  final double confidence;

  PhotoLabel({
    required this.label,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
      };

  factory PhotoLabel.fromJson(Map<String, dynamic> json) => PhotoLabel(
        label: json['label'] as String,
        confidence: json['confidence'] as double,
      );
}
