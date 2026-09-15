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
  final normalized = _normalizedEventCode(eventType);
  final localized = switch (normalized) {
    'customernoteadded' => 'Nota agregada',
    'customerremindercreated' => 'Recordatorio creado',
    'customerremindercompleted' => 'Recordatorio completado',
    'customerstatuschanged' => 'Estado comercial actualizado',
    'customerupdated' => 'Cliente actualizado',
    'customercreated' => 'Cliente creado',
    'projectnoteadded' => 'Nota agregada',
    'projectremindercreated' => 'Recordatorio creado',
    'projectremindercompleted' => 'Recordatorio completado',
    'projectstatuschanged' => 'Estado de obra actualizado',
    'projectprogressupdated' ||
    'projectprogresschanged' => 'Avance actualizado',
    'projectupdated' => 'Obra actualizada',
    'projectcreated' => 'Obra creada',
    'projectvisitcheckedin' => 'Visita iniciada',
    'projectvisitcheckedout' || 'projectvisitcompleted' => 'Visita finalizada',
    'visitregistered' || 'visit' => 'Visita registrada',
    'attachmentuploaded' => 'Archivo agregado a la visita',
    'workdaystarted' => 'Jornada iniciada',
    'workdayended' || 'workdayclosed' => 'Jornada finalizada',
    _ => '',
  };
  final title = serverTitle.trim();
  if (localized.isNotEmpty) {
    if (title.toLowerCase().startsWith(localized.toLowerCase())) return title;
    return localized;
  }
  if (title.isNotEmpty &&
      (title.contains(RegExp(r'\s')) ||
          _normalizedEventCode(title) != normalized)) {
    return title;
  }
  return 'Actividad registrada';
}

String _normalizedEventCode(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

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
