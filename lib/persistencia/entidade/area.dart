enum Area { militar, economia, infraestrutura, sociedade, ciencia }

extension AreaLabel on Area {
  String get label {
    switch (this) {
      case Area.militar: return 'Militar';
      case Area.economia: return 'Economia';
      case Area.infraestrutura: return 'Infraestrutura';
      case Area.sociedade: return 'Sociedade';
      case Area.ciencia: return 'Ciência';
    }
  }
}
