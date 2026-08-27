String customerStatusLabel(String value) {
  return switch (value.trim().toLowerCase()) {
    'prospect' || 'prospecto' => 'Prospecto',
    'active' || 'activo' => 'Activo',
    'inactive' || 'inactivo' => 'Inactivo',
    'contacted' || 'contactado' => 'Contactado',
    'cancelled' ||
    'canceled' ||
    'cancelado' ||
    'lost' ||
    'perdido' => 'Perdido',
    _ => _readableFallback(value),
  };
}

String projectStatusLabel(String value) {
  return switch (value.trim().toLowerCase()) {
    'draft' || 'borrador' => 'Borrador',
    'planned' || 'planificado' => 'Planificado',
    'inprogress' || 'in_progress' || 'en progreso' => 'En progreso',
    'completed' || 'completado' || 'finalizado' => 'Finalizado',
    'cancelled' ||
    'canceled' ||
    'cancelado' ||
    'lost' ||
    'perdido' => 'Perdido',
    _ => _readableFallback(value),
  };
}

String timelineEventTitle({
  required String eventType,
  required String serverTitle,
}) {
  final normalized = eventType.trim().toLowerCase();
  final localized = switch (normalized) {
    'customernoteadded' => 'Nota agregada',
    'customerremindercreated' => 'Recordatorio creado',
    'customerremindercompleted' => 'Recordatorio completado',
    'customerstatuschanged' => 'Estado comercial actualizado',
    'customerupdated' => 'Cliente actualizado',
    'customercreated' => 'Cliente creado',
    'projectvisitcheckedin' => 'Visita iniciada',
    'projectvisitcheckedout' => 'Visita finalizada',
    'visitregistered' || 'visit' => 'Visita registrada',
    'attachmentuploaded' => 'Archivo agregado a la visita',
    'workdaystarted' => 'Jornada iniciada',
    'workdayended' => 'Jornada finalizada',
    _ => '',
  };
  final title = serverTitle.trim();
  if (title.isNotEmpty && title.toLowerCase() != normalized) return title;
  if (localized.isNotEmpty) return localized;
  return title.isEmpty ? _readableFallback(eventType) : title;
}

String _readableFallback(String value) {
  final normalized = value
      .trim()
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim();
  if (normalized.isEmpty) return '';
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
