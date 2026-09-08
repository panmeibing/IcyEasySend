// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => 'Versión';

  @override
  String get navHome => 'Inicio';

  @override
  String get navHistory => 'Historial';

  @override
  String get navSettings => 'Configuración';

  @override
  String get homeTitle => 'Inicio';

  @override
  String get serverStatus => 'Estado del servidor';

  @override
  String get serverRunning => 'En ejecución';

  @override
  String get serverStopped => 'Detenido';

  @override
  String get serverAddress => 'Dirección del servidor';

  @override
  String get deviceName => 'Nombre del dispositivo';

  @override
  String get storageSpace => 'Espacio de almacenamiento';

  @override
  String get availableSpace => 'Espacio disponible';

  @override
  String get sendFiles => 'Enviar archivos';

  @override
  String get receiveFiles => 'Recibir archivos';

  @override
  String get selectFiles => 'Seleccionar archivos';

  @override
  String get selectFolder => 'Seleccionar carpeta';

  @override
  String get dragDropHint => 'Arrastra archivos aquí';

  @override
  String get noFilesSelected => 'No hay archivos seleccionados';

  @override
  String filesSelected(int count) {
    return '$count archivos seleccionados';
  }

  @override
  String get clearSelection => 'Limpiar selección';

  @override
  String get startSending => 'Comenzar envío';

  @override
  String get sending => 'Enviando';

  @override
  String get sendSuccess => 'Envío exitoso';

  @override
  String get sendFailed => 'Envío fallido';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get historyTitle => 'Historial de transferencias';

  @override
  String get noHistory => 'Sin historial';

  @override
  String get clearHistory => 'Limpiar historial';

  @override
  String get sent => 'Enviado';

  @override
  String get received => 'Recibido';

  @override
  String get failed => 'Fallido';

  @override
  String get fileSize => 'Tamaño del archivo';

  @override
  String get time => 'Hora';

  @override
  String get deleteItem => 'Eliminar registro';

  @override
  String get deleteItemConfirm =>
      '¿Está seguro de que desea eliminar este registro?';

  @override
  String get openFile => 'Abrir archivo';

  @override
  String get openFolder => 'Abrir carpeta';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get general => 'General';

  @override
  String get language => 'Idioma';

  @override
  String get deviceNameSetting => 'Nombre del dispositivo';

  @override
  String get editDeviceName => 'Editar nombre del dispositivo';

  @override
  String get deviceNameHint => 'Ingrese el nombre del dispositivo';

  @override
  String get deviceNameEmpty =>
      'El nombre del dispositivo no puede estar vacío';

  @override
  String get port => 'Puerto';

  @override
  String get portHint => 'Ingrese el número de puerto';

  @override
  String get portInvalid => 'Número de puerto inválido';

  @override
  String get portInUse => 'Puerto en uso';

  @override
  String get savePath => 'Ruta de guardado';

  @override
  String get selectSavePath => 'Seleccionar ruta de guardado';

  @override
  String get savePathDesc =>
      'Los archivos recibidos se guardan aquí. Por defecto se usa la carpeta de descargas del sistema.';

  @override
  String get savePathDefaultBadge => 'Predeterminado';

  @override
  String get savePathUnavailable => 'No se puede obtener la ruta de guardado';

  @override
  String get savePathSavedSuccess =>
      'Ruta de guardado configurada correctamente';

  @override
  String get savePathNotWritable =>
      'No se puede escribir en esta carpeta. Elija otra ubicación o compruebe los permisos.';

  @override
  String get resetSavePathToDefault => 'Usar carpeta predeterminada';

  @override
  String get savePathResetSuccess =>
      'Restaurado a la carpeta de descargas del sistema';

  @override
  String get autoStart => 'Inicio automático';

  @override
  String get autoStartDesc =>
      'Iniciar servicio automáticamente al abrir la aplicación';

  @override
  String get network => 'Red';

  @override
  String get networkDiagnostics => 'Diagnóstico de red';

  @override
  String get scanDevices => 'Buscar dispositivos';

  @override
  String get scanDevicesTitle => 'Buscar dispositivos en la LAN';

  @override
  String get scanningDevices => 'Escaneando la red local...';

  @override
  String scanProgress(int scanned, int total, int found) {
    String _temp0 = intl.Intl.pluralLogic(
      found,
      locale: localeName,
      other: 'Escaneado $scanned/$total, $found dispositivos encontrados',
      one: 'Escaneado $scanned/$total, $found dispositivo encontrado',
    );
    return '$_temp0';
  }

  @override
  String get noDevicesFound => 'No se encontraron dispositivos';

  @override
  String get noDevicesFoundHint =>
      'Asegúrese de que el dispositivo destino haya iniciado el servidor y esté en la misma red. Revise el aislamiento AP del router y el firewall.';

  @override
  String scanDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos encontrados',
      one: '$count dispositivo encontrado',
    );
    return '$_temp0';
  }

  @override
  String get rescan => 'Volver a buscar';

  @override
  String get runDiagnostics => 'Ejecutar diagnóstico';

  @override
  String get about => 'Acerca de';

  @override
  String get version => 'Versión';

  @override
  String get checkUpdate => 'Buscar actualizaciones';

  @override
  String get feedback => 'Comentarios';

  @override
  String get openSource => 'Licencias de código abierto';

  @override
  String get license => 'Licencia';

  @override
  String get permissionRequired => 'Permiso requerido';

  @override
  String get permissionDenied => 'Permiso denegado';

  @override
  String get permissionPermanentlyDenied => 'Permiso denegado permanentemente';

  @override
  String get permissionStorage => 'Permiso de almacenamiento';

  @override
  String get permissionStorageDesc =>
      'Se requiere permiso de almacenamiento para guardar y leer archivos';

  @override
  String get permissionNotification => 'Permiso de notificaciones';

  @override
  String get permissionNotificationDesc =>
      'Se requiere permiso de notificaciones para mostrar el progreso de transferencia';

  @override
  String get openSettings => 'Abrir configuración';

  @override
  String get permissionWarning =>
      'Algunos permisos no fueron otorgados, algunas funciones pueden estar limitadas';

  @override
  String get error => 'Error';

  @override
  String get errorUnknown => 'Error desconocido';

  @override
  String get errorNetwork => 'Error de red';

  @override
  String get errorFileNotFound => 'Archivo no encontrado';

  @override
  String get errorPermission => 'Error de permiso';

  @override
  String get errorStorage => 'Error de almacenamiento';

  @override
  String get errorServer => 'Error del servidor';

  @override
  String get errorServerStart => 'Error al iniciar el servidor';

  @override
  String get errorServerStop => 'Error al detener el servidor';

  @override
  String get errorConnection => 'Error de conexión';

  @override
  String get errorTimeout => 'Tiempo de espera agotado';

  @override
  String get retry => 'Reintentar';

  @override
  String get copied => 'Copiado';

  @override
  String get copyFailed => 'Error al copiar';

  @override
  String get saved => 'Guardado';

  @override
  String get saveFailed => 'Error al guardar';

  @override
  String get deleted => 'Eliminado';

  @override
  String get deleteFailed => 'Error al eliminar';

  @override
  String get loading => 'Cargando';

  @override
  String get success => 'Éxito';

  @override
  String get warning => 'Advertencia';

  @override
  String get info => 'Información';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get ok => 'Aceptar';

  @override
  String get close => 'Cerrar';

  @override
  String get selectFilesFailed => 'Error al seleccionar archivos';

  @override
  String get selectFolderFailed => 'Error al seleccionar carpeta';

  @override
  String folderFilesAdded(int count) {
    return 'Se agregaron $count archivos de la carpeta';
  }

  @override
  String get folderContainsNoFiles =>
      'La carpeta seleccionada no contiene archivos para enviar';

  @override
  String get openFileFailed => 'Error al abrir archivo';

  @override
  String get openFolderFailed => 'Error al abrir carpeta';

  @override
  String get fileNotExist => 'El archivo no existe';

  @override
  String get folderNotExist => 'La carpeta no existe';

  @override
  String get diagnosticsTitle => 'Diagnóstico de red';

  @override
  String get diagnosticsRunning => 'Ejecutando diagnóstico...';

  @override
  String get diagnosticsComplete => 'Diagnóstico completado';

  @override
  String get diagnosticsFailed => 'Diagnóstico fallido';

  @override
  String get networkStatus => 'Estado de la red';

  @override
  String get wifiConnected => 'WiFi conectado';

  @override
  String get wifiDisconnected => 'WiFi desconectado';

  @override
  String get mobileData => 'Datos móviles';

  @override
  String get noConnection => 'Sin conexión de red';

  @override
  String get ipAddress => 'Dirección IP';

  @override
  String get noIpAddress => 'Sin dirección IP';

  @override
  String get serverStatusCheck => 'Verificación del estado del servidor';

  @override
  String get portCheck => 'Verificación de puerto';

  @override
  String get portAvailable => 'Puerto disponible';

  @override
  String get portUnavailable => 'Puerto no disponible';

  @override
  String get suggestions => 'Sugerencias';

  @override
  String get syncClipboard => 'Sincronizar portapapeles de otro dispositivo';

  @override
  String filesCount(int count) {
    return 'Enviar $count archivos';
  }

  @override
  String get sendFile => 'Enviar archivo';

  @override
  String get shareViaQr => 'Compartir por QR';

  @override
  String get webShareTitle => 'Escanear para recibir';

  @override
  String get webShareHint =>
      'El receptor puede escanear con la cámara del sistema y descargar en el navegador, sin instalar la app. Manténganse en la misma Wi‑Fi / LAN. Algunos escáneres de terceros pueden bloquear enlaces LAN; use Copiar enlace.';

  @override
  String get webShareCopyLink => 'Copiar enlace';

  @override
  String get webShareLinkCopied => 'Enlace copiado';

  @override
  String get webShareStopSharing => 'Detener compartición';

  @override
  String get webShareStopped => 'Compartición web detenida';

  @override
  String get webShareServerRequired =>
      'Inicie el servidor local antes de compartir por QR';

  @override
  String get webShareCreated =>
      'Compartición web creada. El receptor puede escanear para descargar.';

  @override
  String get webShareFailed => 'Error al crear la compartición web';

  @override
  String get webSharePeerName => 'Compartición web';

  @override
  String webShareFilesSummary(int count, String size) {
    return '$count archivo(s) · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return 'Expira en $time';
  }

  @override
  String get releaseToAdd => 'Suelta para agregar archivos';

  @override
  String get serverNotRunning =>
      'El servidor no está en ejecución, no se pueden recibir archivos compartidos';

  @override
  String get cannotReceiveFiles => 'No se pueden recibir archivos';

  @override
  String get sendingInProgress =>
      'Enviando archivos, por favor intente más tarde';

  @override
  String get pleaseTryLater => 'Por favor intente más tarde';

  @override
  String filesAdded(int count) {
    return 'Se agregaron $count archivos compartidos';
  }

  @override
  String get preparingSend => 'Preparando envío...';

  @override
  String get transferring => 'Transfiriendo';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: Transfiriendo...';
  }

  @override
  String get networkChanged =>
      'La red ha cambiado, la dirección del servidor se ha actualizado';

  @override
  String get serverAddressUpdated => 'Dirección del servidor actualizada';

  @override
  String get portCannotBeEmpty => 'El puerto no puede estar vacío';

  @override
  String get portMustBeNumber => 'El puerto debe ser un número';

  @override
  String get portRange => 'Rango de puerto: 1-65535';

  @override
  String ipDeleted(String ip) {
    return 'IP eliminada: $ip';
  }

  @override
  String get runningDiagnostics => 'Ejecutando diagnóstico de red...';

  @override
  String get targetDeviceInfo => 'Información del dispositivo de destino';

  @override
  String get fullAddress => 'Dirección completa';

  @override
  String get targetNotSet => 'Dispositivo de destino no configurado';

  @override
  String get diagnosticsReport => 'Informe de diagnóstico de red';

  @override
  String get reportCopied => 'Informe de diagnóstico copiado al portapapeles';

  @override
  String get deviceNameCannotBeEmpty =>
      'El nombre del dispositivo no puede estar vacío';

  @override
  String get deviceNameSaved => 'Nombre del dispositivo guardado';

  @override
  String get resetDeviceName => 'Restablecer nombre del dispositivo';

  @override
  String resetDeviceNameConfirm(String model) {
    return '¿Está seguro de que desea restablecer el nombre del dispositivo a \"$model\"?';
  }

  @override
  String get reset => 'Restablecer';

  @override
  String get confirmChange => 'Confirmar cambio';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return '¿Está seguro de que desea cambiar el número de transferencias concurrentes de $from a $to?\n\nConsejo: Aumentar las transferencias concurrentes puede mejorar la velocidad de transferencia, pero también aumentará la carga del dispositivo';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return '¿Está seguro de que desea cambiar el número de transferencias concurrentes de $from a $to?\n\nConsejo: Reducir las transferencias concurrentes puede disminuir la carga del dispositivo, pero puede reducir la velocidad de transferencia';
  }

  @override
  String get concurrentTransfersHint =>
      'Consejo de transferencias concurrentes';

  @override
  String get concurrentTransfersSaved =>
      'Número de transferencias concurrentes guardado';

  @override
  String get enterValidNumber => 'Por favor ingrese un número válido';

  @override
  String historyCountRange(int min, int max) {
    return 'Rango de registros de historial: $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return '¿Está seguro de que desea cambiar el número máximo de registros de historial de $from a $to?\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return 'Registros de historial actuales: $count\n\n';
  }

  @override
  String get historyWarning =>
      '⚠️ Advertencia: El número de registros de historial guardados es mayor que el número configurado.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return 'Solo se conservarán los $max registros más recientes, se eliminarán $toDelete registros antiguos.';
  }

  @override
  String get historyHint =>
      'Consejo: La nueva configuración entrará en vigor la próxima vez que se guarde el historial.';

  @override
  String historyDeleted(int count) {
    return 'Configuración guardada, se eliminaron $count registros antiguos';
  }

  @override
  String get maxHistorySaved =>
      'Número máximo de registros de historial guardado';

  @override
  String clipboardSizeRange(int min, int max) {
    return 'Rango de tamaño del portapapeles: $min-$max MB';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return '¿Está seguro de que desea cambiar el tamaño máximo del portapapeles de $from MB a $to MB?\n\n';
  }

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ Consejo: Después de reducir el límite, el contenido del portapapeles que exceda el límite no se sincronizará, se recomienda usar la función de transferencia de archivos.';

  @override
  String get clipboardSizeIncreaseHint =>
      'Consejo: Después de aumentar el límite, se puede sincronizar contenido de portapapeles más grande, pero puede afectar la velocidad de transferencia.';

  @override
  String get maxClipboardSizeSaved => 'Tamaño máximo del portapapeles guardado';

  @override
  String get ipValidationEnabled => 'Validación de dirección IP habilitada';

  @override
  String get ipValidationDisabled => 'Validación de dirección IP deshabilitada';

  @override
  String get deviceSecretKeyCleared => 'Clave secreta del dispositivo borrada';

  @override
  String get deviceSecretKeySaved => 'Clave secreta del dispositivo guardada';

  @override
  String get loadingDevInfo => 'Cargando información de desarrollo...';

  @override
  String get copyLog => 'Copiar registro';

  @override
  String logCopied(int lines) {
    return 'Se copiaron las últimas $lines líneas del registro al portapapeles';
  }

  @override
  String get logFileEmpty => 'El archivo de registro está vacío';

  @override
  String get devInfo => 'Información de desarrollo';

  @override
  String labelCopied(String label, String value) {
    return '$label copiado: $value';
  }

  @override
  String get transferSettings => 'Configuración de transferencia';

  @override
  String get concurrentTransfers => 'Número de transferencias concurrentes';

  @override
  String concurrentTransfersDesc(int max) {
    return 'Número de archivos transferidos simultáneamente (1-$max)';
  }

  @override
  String get concurrentTransfersHintText =>
      'Un mayor número de transferencias concurrentes puede utilizar mejor el ancho de banda, pero puede aumentar la carga del dispositivo';

  @override
  String get maxHistory => 'Número máximo de registros de historial';

  @override
  String maxHistoryDesc(int min, int max) {
    return 'Número máximo de registros de transferencia guardados ($min-$max)';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return 'Ingrese el número ($min-$max)';
  }

  @override
  String get oldRecordsAutoDelete =>
      'Los registros antiguos que excedan el número configurado se eliminarán automáticamente, solo se conservarán los más recientes';

  @override
  String get maxClipboard => 'Tamaño máximo del portapapeles';

  @override
  String maxClipboardDesc(int min, int max) {
    return 'Tamaño máximo del portapapeles permitido para sincronizar ($min-$max MB)';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return 'Ingrese el tamaño ($min-$max MB)';
  }

  @override
  String get clipboardSyncLimit =>
      'El contenido del portapapeles que exceda este tamaño no se sincronizará, se recomienda usar la función de transferencia de archivos';

  @override
  String get ipValidation => 'Validación de dirección IP';

  @override
  String get ipValidationDesc =>
      'Validar si la IP del dispositivo de destino está en el mismo segmento de red';

  @override
  String get ipValidationEnabledHint =>
      'Cuando está habilitado, verificará si la IP de destino está en el mismo segmento de red, puede evitar conectarse al dispositivo incorrecto';

  @override
  String get ipValidationDisabledHint =>
      'Cuando está deshabilitado, no verificará el segmento de red IP, adecuado para entornos de red complejos (como hotspot, VPN, etc.)';

  @override
  String get deviceSecretKey => 'Clave secreta del dispositivo';

  @override
  String get deviceSecretKeyDesc =>
      'Después de configurar, otros dispositivos necesitan proporcionar la clave correcta para omitir la confirmación';

  @override
  String get deviceSecretKeyHint =>
      'Ingrese la clave secreta (dejar vacío significa no usar clave)';

  @override
  String get notSet => 'No configurado';

  @override
  String get author => 'Autor';

  @override
  String get update => 'Actualización';

  @override
  String get github => 'GitHub';

  @override
  String get githubLinkCopied => 'Enlace de GitHub copiado';

  @override
  String get openGitHubFailed =>
      'No se pudo abrir el navegador; enlace copiado';

  @override
  String get appDescription =>
      'Una herramienta simple y fácil de usar para transferir archivos en red local';

  @override
  String get targetDeviceIP => 'Dirección IP del dispositivo de destino';

  @override
  String get ipHint => 'Por ejemplo: 192.168.1.100';

  @override
  String get clear => 'Limpiar';

  @override
  String get history => 'Historial';

  @override
  String get targetDevicePort => 'Puerto del dispositivo de destino';

  @override
  String resetToDefaultPort(int port) {
    return 'Restablecer al puerto predeterminado ($port)';
  }

  @override
  String get targetDeviceSecretKey =>
      'Clave secreta del dispositivo de destino (opcional)';

  @override
  String get secretKeyHint =>
      'La clave correcta puede omitir la confirmación de otro dispositivo';

  @override
  String get aboutSecretKey => 'Acerca de la clave secreta';

  @override
  String get secretKeyFeatureTitle =>
      'Descripción de la función de clave secreta';

  @override
  String get secretKeyFeatureDesc =>
      'Si el dispositivo de destino ha configurado una clave secreta, ingresar la clave correcta puede omitir el cuadro de confirmación y transferir archivos o sincronizar el portapapeles directamente.';

  @override
  String get secretKeyUsageSteps => 'Pasos de uso:';

  @override
  String get secretKeyUsageStep1 =>
      '1. El dispositivo de destino configura la clave secreta del dispositivo en la página de configuración';

  @override
  String get secretKeyUsageStep2 =>
      '2. Ingrese la clave secreta del dispositivo de destino en este campo de entrada';

  @override
  String get secretKeyUsageStep3 =>
      '3. Al enviar archivos o solicitar el portapapeles, si la clave es correcta, el dispositivo receptor aceptará automáticamente';

  @override
  String get secretKeyTip =>
      'Consejo: Dejar vacío usará el método de confirmación manual tradicional';

  @override
  String get secretKeyDescription => 'Descripción de la clave secreta';

  @override
  String get clearSecretKey => 'Borrar clave secreta';

  @override
  String get gotIt => 'Entendido';

  @override
  String get localIP => 'IP local';

  @override
  String ipCopied(String ip) {
    return 'Dirección IP copiada: $ip';
  }

  @override
  String get transferred => 'Transferido';

  @override
  String get transferSpeed => 'Velocidad de transferencia';

  @override
  String get remainingTime => 'Tiempo restante';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Transfiriendo $progressString%';
  }

  @override
  String get storagePermissionMessage =>
      'Se requiere permiso de almacenamiento para seleccionar archivos. Por favor habilite el permiso manualmente en la configuración.';

  @override
  String get checkingTargetDevice => 'Verificando dispositivo de destino...';

  @override
  String get targetDeviceUnavailable => 'Dispositivo de destino no disponible';

  @override
  String targetDeviceError(String error) {
    return 'Dispositivo de destino no disponible\nError: $error';
  }

  @override
  String get connectionFailed => 'Conexión fallida';

  @override
  String get transferHistory => 'Historial de transferencias';

  @override
  String get clearHistoryTitle => 'Limpiar historial';

  @override
  String get clearHistoryMessage =>
      '¿Está seguro de que desea limpiar todo el historial de transferencias? Esta acción no se puede deshacer.';

  @override
  String get noFilteredRecords =>
      'No hay registros que coincidan con los criterios';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterSent => 'Enviados';

  @override
  String get filterReceived => 'Recibidos';

  @override
  String get statisticsInfo => 'Información estadística';

  @override
  String transfersCount(int count) {
    return '$count transferencias';
  }

  @override
  String get totalTransfers => 'Total de transferencias';

  @override
  String get successfulTransfers => 'Exitosas';

  @override
  String get failedTransfers => 'Fallidas';

  @override
  String get sentFiles => 'Enviados';

  @override
  String get receivedFiles => 'Recibidos';

  @override
  String get totalSize => 'Tamaño total';

  @override
  String get moreActions => 'Más acciones';

  @override
  String get deleteRecord => 'Eliminar registro';

  @override
  String get viewDetails => 'Ver detalles';

  @override
  String get deleteRecordTitle => 'Eliminar registro';

  @override
  String deleteRecordMessage(String fileName) {
    return '¿Está seguro de que desea eliminar el registro de transferencia de \"$fileName\"?\n\nNota: Esto solo eliminará el registro, no el archivo en sí.';
  }

  @override
  String get deleteRecordNote =>
      'Nota: Esto solo eliminará el registro, no el archivo en sí.';

  @override
  String get recordDeleted => 'Registro eliminado';

  @override
  String get filePathNotExist => 'La ruta del archivo no existe';

  @override
  String get cannotOpenFile => 'No se puede abrir el archivo';

  @override
  String cannotOpenFileWithMessage(String message) {
    return 'No se puede abrir el archivo: $message';
  }

  @override
  String get iosNoFolderSupport => 'iOS no admite abrir carpetas directamente';

  @override
  String get cannotOpenFolder => 'No se puede abrir la carpeta';

  @override
  String get recentFilesOpened =>
      'Se abrieron archivos recientes, por favor busque manualmente';

  @override
  String get receiveRecord => 'Registro de recepción';

  @override
  String get sendRecord => 'Registro de envío';

  @override
  String get fileName => 'Nombre del archivo';

  @override
  String get fromDevice => 'Desde dispositivo';

  @override
  String get toDevice => 'Enviado a dispositivo';

  @override
  String get deviceIP => 'IP del dispositivo';

  @override
  String get transferTime => 'Hora de transferencia';

  @override
  String get transferStatus => 'Estado de transferencia';

  @override
  String get statusSuccess => 'Exitoso';

  @override
  String get statusFailed => 'Fallido';

  @override
  String get savedLocation => 'Ubicación guardada';

  @override
  String get copy => 'Copiar';

  @override
  String get pathCopied => 'Ruta copiada al portapapeles';

  @override
  String get from => 'Desde';

  @override
  String get sentTo => 'Enviado a';

  @override
  String get clipboardRequest => 'Solicitud de portapapeles';

  @override
  String clipboardRequestFrom(String deviceName) {
    return 'El dispositivo \"$deviceName\" solicita obtener el contenido de su portapapeles';
  }

  @override
  String get allowClipboardRequest => '¿Permitir?';

  @override
  String get clipboardRequestMessage => 'Solicitud de portapapeles';

  @override
  String autoRejectIn(int seconds) {
    return 'Rechazo automático en $seconds segundos';
  }

  @override
  String get reject => 'Rechazar';

  @override
  String get allow => 'Permitir';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceName verificado con clave secreta, compartiendo portapapeles automáticamente';
  }

  @override
  String get clipboardRequestRejected =>
      'El usuario rechazó la solicitud de portapapeles';

  @override
  String get clipboardEmpty => 'El portapapeles está vacío';

  @override
  String clipboardContentTooLarge(double actualSizeMB, int maxSizeMB) {
    final intl.NumberFormat actualSizeMBNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String actualSizeMBString = actualSizeMBNumberFormat.format(
      actualSizeMB,
    );

    return 'El contenido del portapapeles es demasiado grande ($actualSizeMBString MB), excede el límite del dispositivo receptor ($maxSizeMB MB). Se recomienda usar la función de transferencia de archivos.';
  }

  @override
  String get clipboardContentSuccess =>
      'Contenido del portapapeles obtenido exitosamente';

  @override
  String get invalidJsonFormat => 'Formato JSON inválido';

  @override
  String get serverInternalError => 'Error interno del servidor';

  @override
  String get backgroundRejectNeedsSecretKey =>
      'El dispositivo está en segundo plano. Solo se admite sincronización/recepción automática con clave secreta coincidente.';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText =>
      'Esperando transferencias y sincronización del portapapeles en segundo plano';

  @override
  String get androidBackgroundReceiveHint =>
      'En segundo plano, solo los dispositivos con clave secreta coincidente pueden sincronizar o enviar automáticamente. Mantenga la notificación persistente.';

  @override
  String get clipboardOverlay => 'Botón flotante del portapapeles';

  @override
  String get clipboardOverlayDesc =>
      'Toque el botón flotante para actualizar la caché de texto/imagen para sincronizar en segundo plano';

  @override
  String get clipboardOverlayHint =>
      'En segundo plano solo se sincroniza el último contenido actualizado. Desactivar borra la caché y oculta el botón.';

  @override
  String get clipboardOverlayPermissionNeeded =>
      'Permita \"Mostrar sobre otras aplicaciones\" en ajustes. El botón aparecerá al volver.';

  @override
  String get clipboardOverlayEnabledToast =>
      'Botón flotante del portapapeles activado';

  @override
  String get clipboardBackgroundCacheMiss =>
      'No se puede leer el portapapeles del sistema en segundo plano y no hay caché. Abra la app o toque el botón flotante para actualizar.';

  @override
  String get requestingClipboard => 'Solicitando portapapeles...';

  @override
  String get clipboardSyncSuccess => 'Sincronización de portapapeles exitosa';

  @override
  String get textClipboardSyncSuccess =>
      'Sincronización de portapapeles de texto exitosa';

  @override
  String get fileClipboardSyncSuccess =>
      'Sincronización de portapapeles de archivos exitosa\nPuede pegar en la aplicación o administrador de archivos';

  @override
  String get clipboardSyncFailed => 'Sincronización de portapapeles fallida';

  @override
  String get syncFailed => 'Sincronización fallida';

  @override
  String clipboardRequestError(String error) {
    return 'Error al solicitar portapapeles: $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return 'Los siguientes archivos son inválidos o no se pueden acceder:\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation =>
      'Esperando confirmación del receptor...';

  @override
  String get fileSendSuccess => '¡Archivo enviado exitosamente!';

  @override
  String filesSendSuccess(int count) {
    return '¡$count archivos enviados exitosamente!';
  }

  @override
  String get allFilesSendFailed => 'Todos los archivos fallaron al enviar';

  @override
  String get failedFiles => 'Archivos fallidos';

  @override
  String get transferComplete => 'Transferencia completada';

  @override
  String get successCount => 'Exitosos';

  @override
  String get failureCount => 'Fallidos';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) {
    return 'Exitosos: $successCount archivos\nFallidos: $failureCount archivos\n\nArchivos fallidos:\n$failedFiles';
  }

  @override
  String get preparingTransferInfo =>
      'Preparando información de transferencia...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return 'Esperando confirmación del receptor para $count archivos...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return 'Transfiriendo archivo $current/$total: $fileName';
  }

  @override
  String get receiverRejected => 'El receptor rechazó la recepción';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return 'El receptor rechazó la recepción\nCódigo de estado: $statusCode';
  }

  @override
  String get transferIdNotFound => 'ID de transferencia no encontrado';

  @override
  String get waitingForConfirmation => 'Esperando confirmación...';

  @override
  String get preparingToReceive => 'Preparando para recibir...';

  @override
  String get rejected => 'Rechazado';

  @override
  String get receiveComplete => 'Recepción completada';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Recibiendo... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return 'Recibiendo $count archivos';
  }

  @override
  String receiveFilesCount(int count) {
    return 'Recibir $count archivos';
  }

  @override
  String get sender => 'Remitente';

  @override
  String get totalSizeBatch => 'Tamaño total';

  @override
  String get fileList => 'Lista de archivos';

  @override
  String get allFilesReceiveComplete =>
      '¡Todos los archivos recibidos completamente!';

  @override
  String get receivingFiles2 => 'Recibiendo archivos...';

  @override
  String autoRejectCountdown(int seconds) {
    return '¿Recibir estos archivos? (Rechazo automático en $seconds segundos)';
  }

  @override
  String get rejectAll => 'Rechazar todos';

  @override
  String get acceptAll => 'Aceptar todos';

  @override
  String get networkDiagnosticsReport => 'Informe de diagnóstico de red';

  @override
  String get localNetworkInterfaces => 'Interfaces de red locales';

  @override
  String get noValidNetworkInterface =>
      'No se encontró una interfaz de red válida';

  @override
  String get privateNetworkAddress => 'Dirección de red privada';

  @override
  String get targetDeviceReachability =>
      'Accesibilidad del dispositivo de destino';

  @override
  String get canConnectToTarget =>
      'Se puede conectar al dispositivo de destino';

  @override
  String get cannotConnectToTarget =>
      'No se puede conectar al dispositivo de destino';

  @override
  String get healthCheckTest => 'Prueba de verificación de salud';

  @override
  String get healthCheckSuccess => 'Verificación de salud exitosa';

  @override
  String get healthCheckFailed => 'Verificación de salud fallida';

  @override
  String get statusCode => 'Código de estado';

  @override
  String get response => 'Respuesta';

  @override
  String get internetConnection => 'Conexión a Internet';

  @override
  String get hasInternetConnection => 'Tiene conexión a Internet';

  @override
  String get noInternetConnection => 'Sin conexión a Internet';

  @override
  String get networkConnectionFailed =>
      'No se puede conectar al dispositivo de destino, por favor verifique la conexión de red y la dirección IP';

  @override
  String get networkTimeout =>
      'Tiempo de espera de conexión agotado, el dispositivo de destino puede estar fuera de línea o la red es inestable';

  @override
  String get networkRequestFailed =>
      'Solicitud de red fallida, por favor verifique la conexión de red';

  @override
  String get transferTimeout =>
      'Tiempo de espera de transferencia agotado, por favor verifique la conexión de red';

  @override
  String get transferInterrupted =>
      'Transferencia interrumpida, por favor intente nuevamente';

  @override
  String get fileNotFound => 'El archivo no existe';

  @override
  String get fileNotReadable =>
      'No se puede leer el archivo, por favor asegúrese de que el archivo existe y tiene permisos de acceso';

  @override
  String get fileAccessError =>
      'Error de acceso al archivo, por favor verifique los permisos del archivo';

  @override
  String get fileSaveFailed => 'Error al guardar el archivo';

  @override
  String get fileSizeMismatch =>
      'Error al guardar el archivo: El tamaño del archivo no coincide';

  @override
  String get invalidFileName =>
      'El nombre del archivo contiene caracteres ilegales';

  @override
  String get downloadsDirectoryUnavailable =>
      'No se puede acceder al directorio de descargas';

  @override
  String get storageInsufficient =>
      'Espacio de almacenamiento insuficiente, no se puede recibir el archivo';

  @override
  String get diskFullTitle => 'Disco lleno';

  @override
  String get storageCheckFailed =>
      'No se puede verificar el espacio de almacenamiento';

  @override
  String get networkPermissionDenied =>
      'Se requiere permiso de acceso a la red para transferir archivos';

  @override
  String get storagePermissionDenied =>
      'Se requiere permiso de acceso al almacenamiento para guardar archivos';

  @override
  String serverStartFailed(String reason) {
    return 'No se puede iniciar el servidor: $reason';
  }

  @override
  String get serverPortsOccupied =>
      'No se puede iniciar el servidor: Todos los puertos están ocupados';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return 'No se puede iniciar el servidor: Los puertos $defaultPort-$maxPort están todos ocupados';
  }

  @override
  String get serverUnknownError =>
      'No se puede iniciar el servidor: Error desconocido';

  @override
  String get transferRejected =>
      'El dispositivo receptor rechazó recibir el archivo';

  @override
  String get fileTooLarge =>
      'El archivo es demasiado grande, el tamaño máximo admitido es 2GB';

  @override
  String get fileOrStorageFull =>
      'El archivo es demasiado grande o el espacio de almacenamiento del dispositivo receptor es insuficiente';

  @override
  String get receiveTimeout =>
      'Tiempo de espera de recepción agotado, rechazado automáticamente';

  @override
  String get userRejected => 'El usuario rechazó recibir el archivo';

  @override
  String get ipAddressEmpty => 'La dirección IP no puede estar vacía';

  @override
  String get ipAddressInvalidFormat =>
      'Formato de dirección IP inválido, por favor use el formato xxx.xxx.xxx.xxx';

  @override
  String get ipAddressInvalidRange =>
      'Formato de dirección IP inválido, cada número debe estar entre 0-255';

  @override
  String get ipAddressSpecial1 =>
      'No se puede usar 0.0.0.0 como dirección de destino';

  @override
  String get ipAddressSpecial2 =>
      'No se puede usar la dirección de difusión 255.255.255.255';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) {
    return '⚠️ Segmento de red no coincide\nIP local: $localIP (Segmento: $localNetwork.x)\nIP de destino: $targetIP (Segmento: $targetNetwork.x)\n\nConsejo: Los dos dispositivos deben estar en la misma red local (mismo segmento de red) para transferir archivos.\nPara direcciones IPv4 de clase C, los primeros tres números de las dos direcciones IP deben ser iguales, por ejemplo, ambos son 192.169.2, solo el último número es diferente\nLa forma más sencilla es conectar ambos dispositivos al mismo WiFi o enrutador.\n';
  }

  @override
  String get responseParseError =>
      'No se puede analizar la respuesta del servidor';

  @override
  String get responseInvalidFormat =>
      'El formato de respuesta del dispositivo de destino es incorrecto';

  @override
  String responseStatusCodeError(int statusCode) {
    return 'El servidor devolvió un código de estado de error: $statusCode';
  }

  @override
  String get fileSelectionError => 'Error al seleccionar archivos';

  @override
  String get fileSelectionCancelled => 'Selección de archivos cancelada';

  @override
  String genericError(String operation) {
    return '$operation fallido';
  }

  @override
  String unexpectedError(String details) {
    return 'Ocurrió un error inesperado: $details';
  }

  @override
  String networkError(String context) {
    return 'Error de red: $context';
  }

  @override
  String fileError(String context) {
    return 'Error de archivo: $context';
  }

  @override
  String permissionError(String permissionType) {
    return 'Se requiere permiso de $permissionType para continuar la operación';
  }

  @override
  String get foregroundServiceChannelName =>
      'Servicio de transferencia en segundo plano';

  @override
  String get foregroundServiceChannelDescription =>
      'Mantiene la app lista para recibir archivos LAN y solicitudes del portapapeles en segundo plano';

  @override
  String get peerUnreachable =>
      'No se puede conectar con el dispositivo de destino';

  @override
  String get peerUnreachableBoth =>
      'Dispositivo inaccesible (red local y retransmisión)';

  @override
  String get peerUnsupported =>
      'La versión del otro dispositivo no admite el emparejamiento';

  @override
  String get identityMismatch =>
      'El código del dispositivo no coincide con su clave pública; emparejamiento cancelado';

  @override
  String get cannotPairSelf =>
      'No se puede emparejar el dispositivo consigo mismo';

  @override
  String get pairingTitle => 'Emparejamiento de dispositivos';

  @override
  String get compareHint =>
      'Comprueba que ambos dispositivos muestren exactamente el mismo número. Si no, la conexión puede haber sido manipulada.';

  @override
  String get compareHintRelay =>
      'Este dispositivo no está en la misma red. Compara los 6 dígitos por teléfono o voz y confirma solo si coinciden exactamente. Sin esa comprobación no hay ninguna protección.';

  @override
  String get pairOverRelay => 'Emparejar por retransmisión';

  @override
  String get enterDeviceCode =>
      'Introduce el código de 32 caracteres del otro dispositivo';

  @override
  String get invalidDeviceCode =>
      'El código debe tener 32 caracteres hexadecimales';

  @override
  String get alreadyPaired =>
      'Ese dispositivo ya está en la lista de confianza';

  @override
  String get peerAlreadyPaired =>
      'The other device still trusts this one; unpair on that device first';

  @override
  String get relayUnavailable =>
      'Primero hay que conectar con el servidor de retransmisión';

  @override
  String get peerBusy => 'El otro dispositivo está atendiendo otra solicitud';

  @override
  String get peerPairingBlocked =>
      'The other device has blocked this one; ask them to unblock it first';

  @override
  String get peerRelayPairingOff =>
      'El otro dispositivo no acepta solicitudes por retransmisión';

  @override
  String incomingRequest(String deviceName) {
    return '«$deviceName» solicita emparejarse con este dispositivo';
  }

  @override
  String outgoingRequest(String deviceName) {
    return 'Emparejando con «$deviceName»';
  }

  @override
  String get waitingPeer => 'Esperando confirmación…';

  @override
  String get peerAccepted => 'El otro dispositivo ha confirmado';

  @override
  String get peerRejected => 'El otro dispositivo rechazó el emparejamiento';

  @override
  String get peerTimeout => 'El otro dispositivo no confirmó a tiempo';

  @override
  String get pairingFailed => 'Error de emparejamiento';

  @override
  String pairingSucceeded(String deviceName) {
    return 'Emparejamiento con «$deviceName» completado';
  }

  @override
  String get codesMatch => 'Los números coinciden, emparejar';

  @override
  String get codesDiffer => 'No coinciden, cancelar';

  @override
  String get blockPeer => 'Block';

  @override
  String get pairingBlocklistTitle => 'Pairing blocklist';

  @override
  String get pairingBlocklistEmpty => 'No blocked devices';

  @override
  String get pairingBlocklistManage => 'Blocklist';

  @override
  String get unblockPeer => 'Unblock';

  @override
  String unblockPeerConfirm(String name) {
    return 'Unblock \"$name\"? They will be able to request pairing again.';
  }

  @override
  String get pairedDevicesTitle => 'Dispositivos emparejados';

  @override
  String get pairedDevicesEmpty => 'Aún no hay dispositivos emparejados';

  @override
  String get addPairedDevice => 'Emparejar un dispositivo';

  @override
  String get unpair => 'Desemparejar';

  @override
  String unpairConfirm(String deviceName) {
    return 'Tras eliminar «$deviceName» habrá que volver a comparar los números. ¿Continuar?';
  }

  @override
  String get deviceCodeLabel => 'Código de este dispositivo';

  @override
  String get title => 'Servidor de retransmisión';

  @override
  String get description =>
      'Reenvía archivos a través de tu propio servidor cuando los dispositivos no están en la misma red. La conexión directa siempre tiene prioridad.';

  @override
  String get encryptionNotice =>
      'Los archivos van cifrados de extremo a extremo entre los dos dispositivos emparejados; solo ellos pueden descifrarlos. El servidor solo ve la hora y el número de bytes.';

  @override
  String get acceptPairingLabel =>
      'Aceptar solicitudes de emparejamiento por retransmisión';

  @override
  String get acceptPairingHint =>
      'Cualquier dispositivo con el token del servidor puede solicitar emparejarse con tu código. Un dispositivo rechazado no vuelve a aparecer.';

  @override
  String get iosForegroundNotice =>
      'En iOS solo se pueden recibir archivos por retransmisión con la aplicación abierta.';

  @override
  String get enableLabel => 'Activar retransmisión';

  @override
  String get serverUrlLabel => 'Dirección del servidor';

  @override
  String get tokenLabel => 'Token de acceso';

  @override
  String get invalidUrl => 'La dirección debe empezar por http:// o https://';

  @override
  String get insecureUrlWarning =>
      'Con http:// el tráfico no va cifrado, úsalo solo para pruebas locales';

  @override
  String get testConnection => 'Probar conexión';

  @override
  String get testSucceeded => 'Conexión correcta';

  @override
  String get save => 'Guardar';

  @override
  String get statusDisabled => 'Desactivado';

  @override
  String get statusConnecting => 'Conectando…';

  @override
  String get statusConnected => 'Conectado';

  @override
  String get statusReconnecting => 'Reconectando…';

  @override
  String get statusRejected => 'Rechazado por el servidor';

  @override
  String get clipboardNeedsPairing => 'Pair with the device first';

  @override
  String get clipboardRelayUnavailable => 'Not connected to the relay server';

  @override
  String get clipboardPeerOffline => 'The peer is not online on the relay';

  @override
  String get clipboardFailed => 'Clipboard sync over the relay failed';

  @override
  String get clipboardPeerNoUi =>
      'The peer cannot confirm the request right now';

  @override
  String get clipboardPeerBusy => 'The peer is busy, try again later';

  @override
  String get clipboardTooLargeForRelay =>
      'Clipboard content exceeds the configured size limit';

  @override
  String get clipboardStreamFailed =>
      'Failed to fetch clipboard data over the relay stream';

  @override
  String get clipboardPeerTimeout =>
      'The peer did not answer the clipboard request';

  @override
  String get clipboardDeclined => 'The peer declined the clipboard request';

  @override
  String selectedRelayPeer(String name) {
    return 'Selected relay peer: $name';
  }

  @override
  String get clearSelectedPeer => 'Clear selection';

  @override
  String get lanRouteUnavailable =>
      'No se puede acceder al dispositivo por la red local';

  @override
  String get relayRouteUnavailable =>
      'No se puede acceder al dispositivo por el servidor de retransmisión';

  @override
  String get relayNotConnected => 'No conectado al servidor de retransmisión';

  @override
  String get relayPeerOffline =>
      'El destinatario debe abrir la aplicación para recibir por retransmisión';

  @override
  String get relayPeerNotPaired =>
      'El destinatario no tiene este dispositivo en su lista de confianza';

  @override
  String get relayPeerBusy =>
      'El destinatario está procesando otro lote de archivos';

  @override
  String get relayNeedsPairedDevice =>
      'La transferencia por retransmisión requiere emparejar primero';

  @override
  String get relayNegotiatingSession => 'Estableciendo una sesión cifrada…';

  @override
  String get relayIdentityMismatch =>
      'Firma no válida; puede no ser el dispositivo emparejado';

  @override
  String get relayTransferNotice =>
      'Transfiriendo por el servidor de retransmisión; la velocidad depende de su ancho de banda';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return 'Conexión interrumpida, reintentando ($attempt/$maxAttempts)…';
  }
}
