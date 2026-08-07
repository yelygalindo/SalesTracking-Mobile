enum VisitTargetType {
  customer,
  project;

  String get apiValue => name;

  String get label => switch (this) {
    VisitTargetType.customer => 'Cliente',
    VisitTargetType.project => 'Obra',
  };
}
