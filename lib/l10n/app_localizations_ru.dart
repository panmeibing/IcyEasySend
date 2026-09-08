// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => 'Версия';

  @override
  String get navHome => 'Главная';

  @override
  String get navHistory => 'История';

  @override
  String get navSettings => 'Настройки';

  @override
  String get homeTitle => 'Главная';

  @override
  String get serverStatus => 'Статус сервера';

  @override
  String get serverRunning => 'Работает';

  @override
  String get serverStopped => 'Остановлен';

  @override
  String get serverAddress => 'Адрес сервера';

  @override
  String get deviceName => 'Имя устройства';

  @override
  String get storageSpace => 'Место хранения';

  @override
  String get availableSpace => 'Доступно';

  @override
  String get sendFiles => 'Отправить файлы';

  @override
  String get receiveFiles => 'Получить файлы';

  @override
  String get selectFiles => 'Выбрать файлы';

  @override
  String get selectFolder => 'Выбрать папку';

  @override
  String get dragDropHint => 'Перетащите файлы сюда';

  @override
  String get noFilesSelected => 'Файлы не выбраны';

  @override
  String filesSelected(int count) {
    return 'Выбрано файлов: $count';
  }

  @override
  String get clearSelection => 'Очистить выбор';

  @override
  String get startSending => 'Начать отправку';

  @override
  String get sending => 'Отправка';

  @override
  String get sendSuccess => 'Успешно отправлено';

  @override
  String get sendFailed => 'Ошибка отправки';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get historyTitle => 'История передач';

  @override
  String get noHistory => 'История пуста';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get sent => 'Отправлено';

  @override
  String get received => 'Получено';

  @override
  String get failed => 'Ошибка';

  @override
  String get fileSize => 'Размер файла';

  @override
  String get time => 'Время';

  @override
  String get deleteItem => 'Удалить запись';

  @override
  String get deleteItemConfirm => 'Вы уверены, что хотите удалить эту запись?';

  @override
  String get openFile => 'Открыть файл';

  @override
  String get openFolder => 'Открыть папку';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get general => 'Общие';

  @override
  String get language => 'Язык';

  @override
  String get deviceNameSetting => 'Имя устройства';

  @override
  String get editDeviceName => 'Изменить имя устройства';

  @override
  String get deviceNameHint => 'Введите имя устройства';

  @override
  String get deviceNameEmpty => 'Имя устройства не может быть пустым';

  @override
  String get port => 'Порт';

  @override
  String get portHint => 'Введите номер порта';

  @override
  String get portInvalid => 'Неверный номер порта';

  @override
  String get portInUse => 'Порт уже используется';

  @override
  String get savePath => 'Путь сохранения';

  @override
  String get selectSavePath => 'Выбрать путь сохранения';

  @override
  String get savePathDesc =>
      'Полученные файлы сохраняются здесь. По умолчанию используется системная папка «Загрузки».';

  @override
  String get savePathDefaultBadge => 'По умолчанию';

  @override
  String get savePathUnavailable => 'Не удалось определить путь сохранения';

  @override
  String get savePathSavedSuccess => 'Путь сохранения успешно задан';

  @override
  String get savePathNotWritable =>
      'В эту папку нельзя записать. Выберите другое расположение или проверьте разрешения.';

  @override
  String get resetSavePathToDefault => 'Использовать папку по умолчанию';

  @override
  String get savePathResetSuccess => 'Восстановлена системная папка «Загрузки»';

  @override
  String get autoStart => 'Автозапуск';

  @override
  String get autoStartDesc =>
      'Автоматически запускать сервис при старте приложения';

  @override
  String get network => 'Сеть';

  @override
  String get networkDiagnostics => 'Диагностика сети';

  @override
  String get scanDevices => 'Сканировать устройства';

  @override
  String get scanDevicesTitle => 'Сканирование устройств в LAN';

  @override
  String get scanningDevices => 'Сканирование локальной сети...';

  @override
  String scanProgress(int scanned, int total, int found) {
    return 'Просканировано $scanned/$total, найдено устройств: $found';
  }

  @override
  String get noDevicesFound => 'Устройства не найдены';

  @override
  String get noDevicesFoundHint =>
      'Убедитесь, что на целевом устройстве запущен сервер и оно находится в той же сети. Проверьте AP-изоляцию роутера и настройки брандмауэра.';

  @override
  String scanDevicesFound(int count) {
    return 'Найдено устройств: $count';
  }

  @override
  String get rescan => 'Сканировать снова';

  @override
  String get runDiagnostics => 'Запустить диагностику';

  @override
  String get about => 'О программе';

  @override
  String get version => 'Версия';

  @override
  String get checkUpdate => 'Проверить обновления';

  @override
  String get feedback => 'Обратная связь';

  @override
  String get openSource => 'Лицензии открытого ПО';

  @override
  String get license => 'Лицензия';

  @override
  String get permissionRequired => 'Требуется разрешение';

  @override
  String get permissionDenied => 'Разрешение отклонено';

  @override
  String get permissionPermanentlyDenied => 'Разрешение отклонено навсегда';

  @override
  String get permissionStorage => 'Разрешение на хранилище';

  @override
  String get permissionStorageDesc =>
      'Требуется разрешение на хранилище для сохранения и чтения файлов';

  @override
  String get permissionNotification => 'Разрешение на уведомления';

  @override
  String get permissionNotificationDesc =>
      'Требуется разрешение на уведомления для отображения прогресса передачи';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get permissionWarning =>
      'Некоторые разрешения не предоставлены, функциональность может быть ограничена';

  @override
  String get error => 'Ошибка';

  @override
  String get errorUnknown => 'Неизвестная ошибка';

  @override
  String get errorNetwork => 'Ошибка сети';

  @override
  String get errorFileNotFound => 'Файл не найден';

  @override
  String get errorPermission => 'Ошибка разрешения';

  @override
  String get errorStorage => 'Ошибка хранилища';

  @override
  String get errorServer => 'Ошибка сервера';

  @override
  String get errorServerStart => 'Не удалось запустить сервер';

  @override
  String get errorServerStop => 'Не удалось остановить сервер';

  @override
  String get errorConnection => 'Ошибка подключения';

  @override
  String get errorTimeout => 'Время подключения истекло';

  @override
  String get retry => 'Повторить';

  @override
  String get copied => 'Скопировано';

  @override
  String get copyFailed => 'Не удалось скопировать';

  @override
  String get saved => 'Сохранено';

  @override
  String get saveFailed => 'Не удалось сохранить';

  @override
  String get deleted => 'Удалено';

  @override
  String get deleteFailed => 'Не удалось удалить';

  @override
  String get loading => 'Загрузка';

  @override
  String get success => 'Успешно';

  @override
  String get warning => 'Предупреждение';

  @override
  String get info => 'Информация';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get ok => 'ОК';

  @override
  String get close => 'Закрыть';

  @override
  String get selectFilesFailed => 'Не удалось выбрать файлы';

  @override
  String get selectFolderFailed => 'Не удалось выбрать папку';

  @override
  String folderFilesAdded(int count) {
    return 'Добавлено файлов из папки: $count';
  }

  @override
  String get folderContainsNoFiles =>
      'В выбранной папке нет файлов для отправки';

  @override
  String get openFileFailed => 'Не удалось открыть файл';

  @override
  String get openFolderFailed => 'Не удалось открыть папку';

  @override
  String get fileNotExist => 'Файл не существует';

  @override
  String get folderNotExist => 'Папка не существует';

  @override
  String get diagnosticsTitle => 'Диагностика сети';

  @override
  String get diagnosticsRunning => 'Выполняется диагностика...';

  @override
  String get diagnosticsComplete => 'Диагностика завершена';

  @override
  String get diagnosticsFailed => 'Диагностика не удалась';

  @override
  String get networkStatus => 'Состояние сети';

  @override
  String get wifiConnected => 'WiFi подключен';

  @override
  String get wifiDisconnected => 'WiFi отключен';

  @override
  String get mobileData => 'Мобильные данные';

  @override
  String get noConnection => 'Нет подключения к сети';

  @override
  String get ipAddress => 'IP-адрес';

  @override
  String get noIpAddress => 'Нет IP-адреса';

  @override
  String get serverStatusCheck => 'Проверка статуса сервера';

  @override
  String get portCheck => 'Проверка порта';

  @override
  String get portAvailable => 'Порт доступен';

  @override
  String get portUnavailable => 'Порт недоступен';

  @override
  String get suggestions => 'Рекомендации';

  @override
  String get syncClipboard => 'Синхронизировать буфер обмена';

  @override
  String filesCount(int count) {
    return 'Отправить файлов: $count';
  }

  @override
  String get sendFile => 'Отправить файл';

  @override
  String get shareViaQr => 'Поделиться по QR';

  @override
  String get webShareTitle => 'Сканируйте для получения';

  @override
  String get webShareHint =>
      'Получатель сканирует системной камерой и скачивает в браузере — без установки приложения. Будьте в одной Wi‑Fi / LAN. Некоторые сторонние сканеры блокируют локальные ссылки; используйте «Копировать ссылку».';

  @override
  String get webShareCopyLink => 'Копировать ссылку';

  @override
  String get webShareLinkCopied => 'Ссылка скопирована';

  @override
  String get webShareStopSharing => 'Остановить раздачу';

  @override
  String get webShareStopped => 'Веб-раздача остановлена';

  @override
  String get webShareServerRequired =>
      'Сначала запустите локальный сервер, затем делитесь по QR';

  @override
  String get webShareCreated =>
      'Веб-раздача создана. Получатель может сканировать и скачать.';

  @override
  String get webShareFailed => 'Не удалось создать веб-раздачу';

  @override
  String get webSharePeerName => 'Веб-раздача';

  @override
  String webShareFilesSummary(int count, String size) {
    return '$count файл(ов) · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return 'Истекает через $time';
  }

  @override
  String get releaseToAdd => 'Отпустите мышь, чтобы добавить файлы';

  @override
  String get serverNotRunning =>
      'Сервер не запущен, невозможно получить общие файлы';

  @override
  String get cannotReceiveFiles => 'Невозможно получить файлы';

  @override
  String get sendingInProgress => 'Идет отправка файлов, попробуйте позже';

  @override
  String get pleaseTryLater => 'Попробуйте позже';

  @override
  String filesAdded(int count) {
    return 'Добавлено общих файлов: $count';
  }

  @override
  String get preparingSend => 'Подготовка к отправке...';

  @override
  String get transferring => 'Передача';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: Передача...';
  }

  @override
  String get networkChanged => 'Сеть изменилась, адрес сервера обновлен';

  @override
  String get serverAddressUpdated => 'Адрес сервера обновлен';

  @override
  String get portCannotBeEmpty => 'Порт не может быть пустым';

  @override
  String get portMustBeNumber => 'Порт должен быть числом';

  @override
  String get portRange => 'Диапазон портов: 1-65535';

  @override
  String ipDeleted(String ip) {
    return 'IP удален: $ip';
  }

  @override
  String get runningDiagnostics => 'Выполняется диагностика сети...';

  @override
  String get targetDeviceInfo => 'Информация о целевом устройстве';

  @override
  String get fullAddress => 'Полный адрес';

  @override
  String get targetNotSet => 'Целевое устройство не установлено';

  @override
  String get diagnosticsReport => 'Отчет диагностики сети';

  @override
  String get reportCopied => 'Отчет диагностики скопирован в буфер обмена';

  @override
  String get deviceNameCannotBeEmpty => 'Имя устройства не может быть пустым';

  @override
  String get deviceNameSaved => 'Имя устройства сохранено';

  @override
  String get resetDeviceName => 'Сбросить имя устройства';

  @override
  String resetDeviceNameConfirm(String model) {
    return 'Вы уверены, что хотите сбросить имя устройства на \"$model\"?';
  }

  @override
  String get reset => 'Сбросить';

  @override
  String get confirmChange => 'Подтвердить изменение';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return 'Вы уверены, что хотите изменить количество одновременных передач с $from на $to?\n\nПодсказка: Увеличение количества одновременных передач может повысить скорость передачи, но также увеличит нагрузку на устройство';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return 'Вы уверены, что хотите изменить количество одновременных передач с $from на $to?\n\nПодсказка: Уменьшение количества одновременных передач может снизить нагрузку на устройство, но может снизить скорость передачи';
  }

  @override
  String get concurrentTransfersHint => 'Подсказка об одновременных передачах';

  @override
  String get concurrentTransfersSaved =>
      'Количество одновременных передач сохранено';

  @override
  String get enterValidNumber => 'Введите допустимое число';

  @override
  String historyCountRange(int min, int max) {
    return 'Диапазон количества записей истории: $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return 'Вы уверены, что хотите изменить максимальное количество записей истории с $from на $to?\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return 'Текущее количество записей истории: $count\n\n';
  }

  @override
  String get historyWarning =>
      '⚠️ Предупреждение: Количество сохраненных записей истории больше установленного.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return 'Будут сохранены только последние $max записей, $toDelete старых записей будут удалены.';
  }

  @override
  String get historyHint =>
      'Подсказка: Новые настройки вступят в силу при следующем сохранении истории.';

  @override
  String historyDeleted(int count) {
    return 'Настройки сохранены, удалено старых записей: $count';
  }

  @override
  String get maxHistorySaved =>
      'Максимальное количество записей истории сохранено';

  @override
  String clipboardSizeRange(int min, int max) {
    return 'Диапазон размера буфера обмена: $min-$max МБ';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return 'Вы уверены, что хотите изменить максимальный размер буфера обмена с $from МБ на $to МБ?\n\n';
  }

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ Подсказка: После уменьшения лимита содержимое буфера обмена, превышающее лимит, не сможет синхронизироваться, рекомендуется использовать функцию передачи файлов.';

  @override
  String get clipboardSizeIncreaseHint =>
      'Подсказка: После увеличения лимита вы сможете синхронизировать больший объем содержимого буфера обмена, но это может повлиять на скорость передачи.';

  @override
  String get maxClipboardSizeSaved =>
      'Максимальный размер буфера обмена сохранен';

  @override
  String get ipValidationEnabled => 'Проверка IP-адреса включена';

  @override
  String get ipValidationDisabled => 'Проверка IP-адреса отключена';

  @override
  String get deviceSecretKeyCleared => 'Секретный ключ устройства очищен';

  @override
  String get deviceSecretKeySaved => 'Секретный ключ устройства сохранен';

  @override
  String get loadingDevInfo => 'Загрузка информации для разработчиков...';

  @override
  String get copyLog => 'Копировать журнал';

  @override
  String logCopied(int lines) {
    return 'Последние $lines строк журнала скопированы в буфер обмена';
  }

  @override
  String get logFileEmpty => 'Файл журнала пуст';

  @override
  String get devInfo => 'Информация для разработчиков';

  @override
  String labelCopied(String label, String value) {
    return '$label скопировано: $value';
  }

  @override
  String get transferSettings => 'Настройки передачи';

  @override
  String get concurrentTransfers => 'Количество одновременных передач';

  @override
  String concurrentTransfersDesc(int max) {
    return 'Количество одновременно передаваемых файлов (1-$max)';
  }

  @override
  String get concurrentTransfersHintText =>
      'Большее количество одновременных передач может лучше использовать пропускную способность, но может увеличить нагрузку на устройство';

  @override
  String get maxHistory => 'Максимальное количество записей истории';

  @override
  String maxHistoryDesc(int min, int max) {
    return 'Максимальное количество сохраненных записей передач ($min-$max)';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return 'Введите количество ($min-$max)';
  }

  @override
  String get oldRecordsAutoDelete =>
      'Старые записи, превышающие установленное количество, будут автоматически удалены, сохранятся только последние';

  @override
  String get maxClipboard => 'Максимальный размер буфера обмена';

  @override
  String maxClipboardDesc(int min, int max) {
    return 'Максимальный размер буфера обмена для синхронизации ($min-$max МБ)';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return 'Введите размер ($min-$max МБ)';
  }

  @override
  String get clipboardSyncLimit =>
      'Содержимое буфера обмена, превышающее этот размер, не сможет синхронизироваться, рекомендуется использовать функцию передачи файлов';

  @override
  String get ipValidation => 'Проверка IP-адреса';

  @override
  String get ipValidationDesc =>
      'Проверять, находится ли IP целевого устройства в том же сегменте сети';

  @override
  String get ipValidationEnabledHint =>
      'При включении будет проверяться, находится ли целевой IP в том же сегменте сети, это может предотвратить подключение к неправильному устройству';

  @override
  String get ipValidationDisabledHint =>
      'При отключении не будет проверяться сегмент сети IP, подходит для сложных сетевых сред (например, точка доступа, VPN и т.д.)';

  @override
  String get deviceSecretKey => 'Локальный секретный ключ';

  @override
  String get deviceSecretKeyDesc =>
      'После установки другие устройства должны предоставить правильный ключ, чтобы пропустить подтверждение';

  @override
  String get deviceSecretKeyHint =>
      'Введите секретный ключ (оставьте пустым, чтобы не использовать ключ)';

  @override
  String get notSet => 'Не установлено';

  @override
  String get author => 'Автор';

  @override
  String get update => 'Обновление';

  @override
  String get github => 'GitHub';

  @override
  String get githubLinkCopied => 'Ссылка GitHub скопирована';

  @override
  String get openGitHubFailed =>
      'Не удалось открыть браузер; ссылка скопирована';

  @override
  String get appDescription =>
      'Простой и удобный инструмент для передачи файлов в локальной сети';

  @override
  String get targetDeviceIP => 'IP-адрес целевого устройства';

  @override
  String get ipHint => 'Например: 192.168.1.100';

  @override
  String get clear => 'Очистить';

  @override
  String get history => 'История';

  @override
  String get targetDevicePort => 'Порт целевого устройства';

  @override
  String resetToDefaultPort(int port) {
    return 'Сбросить на порт по умолчанию ($port)';
  }

  @override
  String get targetDeviceSecretKey =>
      'Секретный ключ целевого устройства (необязательно)';

  @override
  String get secretKeyHint => 'Правильный ключ может пропустить подтверждение';

  @override
  String get aboutSecretKey => 'О секретном ключе';

  @override
  String get secretKeyFeatureTitle => 'Описание функции секретного ключа';

  @override
  String get secretKeyFeatureDesc =>
      'Если целевое устройство установило секретный ключ, ввод правильного ключа позволит пропустить окно подтверждения и напрямую передавать файлы или синхронизировать буфер обмена.';

  @override
  String get secretKeyUsageSteps => 'Шаги использования:';

  @override
  String get secretKeyUsageStep1 =>
      '1. Целевое устройство устанавливает локальный секретный ключ на странице настроек';

  @override
  String get secretKeyUsageStep2 =>
      '2. Введите секретный ключ целевого устройства в это поле ввода';

  @override
  String get secretKeyUsageStep3 =>
      '3. При отправке файлов или запросе буфера обмена, если ключ правильный, другая сторона автоматически примет';

  @override
  String get secretKeyTip =>
      'Подсказка: Оставьте пустым, чтобы использовать традиционный метод ручного подтверждения';

  @override
  String get secretKeyDescription => 'Описание секретного ключа';

  @override
  String get clearSecretKey => 'Очистить секретный ключ';

  @override
  String get gotIt => 'Понятно';

  @override
  String get localIP => 'Локальный IP';

  @override
  String ipCopied(String ip) {
    return 'IP-адрес скопирован: $ip';
  }

  @override
  String get transferred => 'Передано';

  @override
  String get transferSpeed => 'Скорость передачи';

  @override
  String get remainingTime => 'Оставшееся время';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Передача $progressString%';
  }

  @override
  String get storagePermissionMessage =>
      'Требуется разрешение на хранилище для выбора файлов. Включите разрешение вручную в настройках.';

  @override
  String get checkingTargetDevice => 'Проверка целевого устройства...';

  @override
  String get targetDeviceUnavailable => 'Целевое устройство недоступно';

  @override
  String targetDeviceError(String error) {
    return 'Целевое устройство недоступно\nОшибка: $error';
  }

  @override
  String get connectionFailed => 'Не удалось подключиться';

  @override
  String get transferHistory => 'История передач';

  @override
  String get clearHistoryTitle => 'Очистить историю';

  @override
  String get clearHistoryMessage =>
      'Вы уверены, что хотите очистить всю историю передач? Это действие нельзя отменить.';

  @override
  String get noFilteredRecords => 'Нет соответствующих записей';

  @override
  String get filterAll => 'Все';

  @override
  String get filterSent => 'Отправленные';

  @override
  String get filterReceived => 'Полученные';

  @override
  String get statisticsInfo => 'Статистическая информация';

  @override
  String transfersCount(int count) {
    return 'Передач: $count';
  }

  @override
  String get totalTransfers => 'Всего передач';

  @override
  String get successfulTransfers => 'Успешно';

  @override
  String get failedTransfers => 'Ошибок';

  @override
  String get sentFiles => 'Отправлено';

  @override
  String get receivedFiles => 'Получено';

  @override
  String get totalSize => 'Общий размер';

  @override
  String get moreActions => 'Дополнительные действия';

  @override
  String get deleteRecord => 'Удалить запись';

  @override
  String get viewDetails => 'Просмотр деталей';

  @override
  String get deleteRecordTitle => 'Удалить запись';

  @override
  String deleteRecordMessage(String fileName) {
    return 'Вы уверены, что хотите удалить запись передачи \"$fileName\"?\n\nПримечание: Это удалит только запись, а не сам файл.';
  }

  @override
  String get deleteRecordNote =>
      'Примечание: Это удалит только запись, а не сам файл.';

  @override
  String get recordDeleted => 'Запись удалена';

  @override
  String get filePathNotExist => 'Путь к файлу не существует';

  @override
  String get cannotOpenFile => 'Невозможно открыть файл';

  @override
  String cannotOpenFileWithMessage(String message) {
    return 'Невозможно открыть файл: $message';
  }

  @override
  String get iosNoFolderSupport => 'iOS не поддерживает прямое открытие папок';

  @override
  String get cannotOpenFolder => 'Невозможно открыть папку';

  @override
  String get recentFilesOpened => 'Последние файлы открыты, найдите вручную';

  @override
  String get receiveRecord => 'Запись получения';

  @override
  String get sendRecord => 'Запись отправки';

  @override
  String get fileName => 'Имя файла';

  @override
  String get fromDevice => 'От устройства';

  @override
  String get toDevice => 'На устройство';

  @override
  String get deviceIP => 'IP устройства';

  @override
  String get transferTime => 'Время передачи';

  @override
  String get transferStatus => 'Статус передачи';

  @override
  String get statusSuccess => 'Успешно';

  @override
  String get statusFailed => 'Ошибка';

  @override
  String get savedLocation => 'Место сохранения';

  @override
  String get copy => 'Копировать';

  @override
  String get pathCopied => 'Путь скопирован в буфер обмена';

  @override
  String get from => 'От';

  @override
  String get sentTo => 'Отправлено на';

  @override
  String get clipboardRequest => 'Запрос буфера обмена';

  @override
  String clipboardRequestFrom(String deviceName) {
    return 'Устройство \"$deviceName\" запрашивает доступ к содержимому вашего буфера обмена';
  }

  @override
  String get allowClipboardRequest => 'Разрешить?';

  @override
  String get clipboardRequestMessage => 'Запрос буфера обмена';

  @override
  String autoRejectIn(int seconds) {
    return 'Автоматический отказ через $seconds сек';
  }

  @override
  String get reject => 'Отклонить';

  @override
  String get allow => 'Разрешить';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceName прошло проверку секретным ключом, автоматический обмен буфером обмена';
  }

  @override
  String get clipboardRequestRejected =>
      'Пользователь отклонил запрос буфера обмена';

  @override
  String get clipboardEmpty => 'Буфер обмена пуст';

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

    return 'Содержимое буфера обмена слишком большое ($actualSizeMBString МБ), превышает лимит целевого устройства ($maxSizeMB МБ). Рекомендуется использовать функцию передачи файлов.';
  }

  @override
  String get clipboardContentSuccess =>
      'Содержимое буфера обмена успешно получено';

  @override
  String get invalidJsonFormat => 'Неверный формат JSON';

  @override
  String get serverInternalError => 'Внутренняя ошибка сервера';

  @override
  String get backgroundRejectNeedsSecretKey =>
      'Устройство в фоне. Поддерживается только автосинхронизация/приём при совпадении секретного ключа.';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText =>
      'Ожидание передачи файлов и синхронизации буфера в фоне';

  @override
  String get androidBackgroundReceiveHint =>
      'В фоне только устройства с совпадающим секретным ключом могут автоматически синхронизировать или отправлять. Сохраняйте постоянное уведомление.';

  @override
  String get clipboardOverlay => 'Плавающая кнопка буфера обмена';

  @override
  String get clipboardOverlayDesc =>
      'Нажмите плавающую кнопку, чтобы обновить кэш текста/изображений для фоновой синхронизации';

  @override
  String get clipboardOverlayHint =>
      'В фоне синхронизируется только последнее обновлённое содержимое. Отключение очищает кэш и скрывает кнопку.';

  @override
  String get clipboardOverlayPermissionNeeded =>
      'Разрешите «Поверх других приложений» в настройках. Кнопка появится после возврата.';

  @override
  String get clipboardOverlayEnabledToast =>
      'Плавающая кнопка буфера обмена включена';

  @override
  String get clipboardBackgroundCacheMiss =>
      'В фоне системный буфер недоступен и нет кэша. Откройте приложение или нажмите плавающую кнопку для обновления.';

  @override
  String get requestingClipboard => 'Запрос буфера обмена...';

  @override
  String get clipboardSyncSuccess => 'Синхронизация буфера обмена успешна';

  @override
  String get textClipboardSyncSuccess =>
      'Синхронизация текстового буфера обмена успешна';

  @override
  String get fileClipboardSyncSuccess =>
      'Синхронизация файлового буфера обмена успешна\nМожно вставить в приложение или файловый менеджер';

  @override
  String get clipboardSyncFailed => 'Не удалось синхронизировать буфер обмена';

  @override
  String get syncFailed => 'Не удалось синхронизировать';

  @override
  String clipboardRequestError(String error) {
    return 'Ошибка при запросе буфера обмена: $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return 'Следующие файлы недействительны или недоступны:\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation =>
      'Ожидание подтверждения получателя...';

  @override
  String get fileSendSuccess => 'Файл успешно отправлен!';

  @override
  String filesSendSuccess(int count) {
    return 'Файлов успешно отправлено: $count!';
  }

  @override
  String get allFilesSendFailed => 'Не удалось отправить все файлы';

  @override
  String get failedFiles => 'Файлы с ошибками';

  @override
  String get transferComplete => 'Передача завершена';

  @override
  String get successCount => 'Успешно';

  @override
  String get failureCount => 'Ошибок';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) {
    return 'Успешно: $successCount файлов\nОшибок: $failureCount файлов\n\nФайлы с ошибками:\n$failedFiles';
  }

  @override
  String get preparingTransferInfo => 'Подготовка информации о передаче...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return 'Ожидание подтверждения получателем $count файлов...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return 'Передача файла $current/$total: $fileName';
  }

  @override
  String get receiverRejected => 'Получатель отклонил получение';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return 'Получатель отклонил получение\nКод состояния: $statusCode';
  }

  @override
  String get transferIdNotFound => 'ID передачи не найден';

  @override
  String get waitingForConfirmation => 'Ожидание подтверждения...';

  @override
  String get preparingToReceive => 'Подготовка к получению...';

  @override
  String get rejected => 'Отклонено';

  @override
  String get receiveComplete => 'Получение завершено';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Получение... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return 'Получение файлов: $count';
  }

  @override
  String receiveFilesCount(int count) {
    return 'Получить файлов: $count';
  }

  @override
  String get sender => 'Отправитель';

  @override
  String get totalSizeBatch => 'Общий размер';

  @override
  String get fileList => 'Список файлов';

  @override
  String get allFilesReceiveComplete => 'Все файлы получены!';

  @override
  String get receivingFiles2 => 'Получение файлов...';

  @override
  String autoRejectCountdown(int seconds) {
    return 'Получить эти файлы? (Автоматический отказ через $seconds сек)';
  }

  @override
  String get rejectAll => 'Отклонить все';

  @override
  String get acceptAll => 'Принять все';

  @override
  String get networkDiagnosticsReport => 'Отчет диагностики сети';

  @override
  String get localNetworkInterfaces => 'Локальные сетевые интерфейсы';

  @override
  String get noValidNetworkInterface =>
      'Не найден действительный сетевой интерфейс';

  @override
  String get privateNetworkAddress => 'Адрес частной сети';

  @override
  String get targetDeviceReachability => 'Доступность целевого устройства';

  @override
  String get canConnectToTarget => 'Можно подключиться к целевому устройству';

  @override
  String get cannotConnectToTarget =>
      'Невозможно подключиться к целевому устройству';

  @override
  String get healthCheckTest => 'Тест проверки работоспособности';

  @override
  String get healthCheckSuccess => 'Проверка работоспособности успешна';

  @override
  String get healthCheckFailed => 'Проверка работоспособности не удалась';

  @override
  String get statusCode => 'Код состояния';

  @override
  String get response => 'Ответ';

  @override
  String get internetConnection => 'Подключение к Интернету';

  @override
  String get hasInternetConnection => 'Есть подключение к Интернету';

  @override
  String get noInternetConnection => 'Нет подключения к Интернету';

  @override
  String get networkConnectionFailed =>
      'Невозможно подключиться к целевому устройству, проверьте сетевое подключение и IP-адрес';

  @override
  String get networkTimeout =>
      'Время подключения истекло, целевое устройство может быть не в сети или сеть нестабильна';

  @override
  String get networkRequestFailed =>
      'Не удалось выполнить сетевой запрос, проверьте сетевое подключение';

  @override
  String get transferTimeout =>
      'Время передачи истекло, проверьте сетевое подключение';

  @override
  String get transferInterrupted => 'Передача прервана, попробуйте снова';

  @override
  String get fileNotFound => 'Файл не существует';

  @override
  String get fileNotReadable =>
      'Невозможно прочитать файл, убедитесь, что файл существует и есть разрешение на доступ';

  @override
  String get fileAccessError =>
      'Ошибка доступа к файлу, проверьте разрешения файла';

  @override
  String get fileSaveFailed => 'Не удалось сохранить файл';

  @override
  String get fileSizeMismatch =>
      'Не удалось сохранить файл: размер файла не совпадает';

  @override
  String get invalidFileName => 'Имя файла содержит недопустимые символы';

  @override
  String get downloadsDirectoryUnavailable =>
      'Невозможно получить доступ к каталогу загрузок';

  @override
  String get storageInsufficient =>
      'Недостаточно места для хранения, невозможно получить файл';

  @override
  String get diskFullTitle => 'Диск заполнен';

  @override
  String get storageCheckFailed => 'Невозможно проверить место для хранения';

  @override
  String get networkPermissionDenied =>
      'Требуется разрешение на доступ к сети для передачи файлов';

  @override
  String get storagePermissionDenied =>
      'Требуется разрешение на доступ к хранилищу для сохранения файлов';

  @override
  String serverStartFailed(String reason) {
    return 'Невозможно запустить сервер: $reason';
  }

  @override
  String get serverPortsOccupied =>
      'Невозможно запустить сервер: все порты заняты';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return 'Невозможно запустить сервер: порты $defaultPort-$maxPort все заняты';
  }

  @override
  String get serverUnknownError =>
      'Невозможно запустить сервер: неизвестная ошибка';

  @override
  String get transferRejected => 'Другая сторона отклонила получение файла';

  @override
  String get fileTooLarge =>
      'Файл слишком большой, максимум поддерживается 2ГБ';

  @override
  String get fileOrStorageFull =>
      'Файл слишком большой или недостаточно места для хранения у другой стороны';

  @override
  String get receiveTimeout =>
      'Время получения истекло, автоматически отклонено';

  @override
  String get userRejected => 'Пользователь отклонил получение файла';

  @override
  String get ipAddressEmpty => 'IP-адрес не может быть пустым';

  @override
  String get ipAddressInvalidFormat =>
      'Неверный формат IP-адреса, используйте формат xxx.xxx.xxx.xxx';

  @override
  String get ipAddressInvalidRange =>
      'Неверный формат IP-адреса, каждое число должно быть в диапазоне 0-255';

  @override
  String get ipAddressSpecial1 =>
      'Нельзя использовать 0.0.0.0 в качестве целевого адреса';

  @override
  String get ipAddressSpecial2 =>
      'Нельзя использовать широковещательный адрес 255.255.255.255';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) {
    return '⚠️ Несоответствие сегмента сети\nЛокальный IP: $localIP (сегмент: $localNetwork.x)\nЦелевой IP: $targetIP (сегмент: $targetNetwork.x)\n\nПодсказка: Оба устройства должны находиться в одной локальной сети (одном сегменте) для передачи файлов.\nДля адресов IPv4 класса C первые три числа двух IP-адресов должны быть одинаковыми, например, оба 192.169.2, отличается только последнее число\nСамый простой способ - подключить оба устройства к одному WiFi или маршрутизатору.\n';
  }

  @override
  String get responseParseError => 'Невозможно разобрать ответ сервера';

  @override
  String get responseInvalidFormat =>
      'Неверный формат ответа целевого устройства';

  @override
  String responseStatusCodeError(int statusCode) {
    return 'Сервер вернул код ошибки: $statusCode';
  }

  @override
  String get fileSelectionError => 'Ошибка при выборе файла';

  @override
  String get fileSelectionCancelled => 'Выбор файла отменен';

  @override
  String genericError(String operation) {
    return 'Не удалось выполнить $operation';
  }

  @override
  String unexpectedError(String details) {
    return 'Произошла неожиданная ошибка: $details';
  }

  @override
  String networkError(String context) {
    return 'Ошибка сети: $context';
  }

  @override
  String fileError(String context) {
    return 'Ошибка файла: $context';
  }

  @override
  String permissionError(String permissionType) {
    return 'Требуется разрешение $permissionType для продолжения операции';
  }

  @override
  String get foregroundServiceChannelName => 'Фоновая служба передачи';

  @override
  String get foregroundServiceChannelDescription =>
      'Позволяет приложению принимать LAN-файлы и запросы буфера обмена в фоне';

  @override
  String get peerUnreachable => 'Не удалось подключиться к целевому устройству';

  @override
  String get peerUnreachableBoth =>
      'Устройство недоступно (ни локально, ни через ретранслятор)';

  @override
  String get peerUnsupported =>
      'Версия другого устройства не поддерживает сопряжение';

  @override
  String get identityMismatch =>
      'Код устройства не соответствует его открытому ключу, сопряжение прервано';

  @override
  String get cannotPairSelf => 'Нельзя выполнить сопряжение с самим собой';

  @override
  String get pairingTitle => 'Сопряжение устройств';

  @override
  String get compareHint =>
      'Убедитесь, что на обоих устройствах отображается одно и то же число. Иначе соединение могло быть подменено.';

  @override
  String get compareHintRelay =>
      'Это устройство не в вашей сети. Сверьте 6 цифр с собеседником по телефону и подтверждайте только при полном совпадении. Без сверки защиты нет вообще.';

  @override
  String get pairOverRelay => 'Сопряжение через ретранслятор';

  @override
  String get enterDeviceCode => 'Введите 32-значный код другого устройства';

  @override
  String get invalidDeviceCode =>
      'Код устройства должен состоять из 32 шестнадцатеричных символов';

  @override
  String get alreadyPaired => 'Это устройство уже в списке доверенных';

  @override
  String get peerAlreadyPaired =>
      'The other device still trusts this one; unpair on that device first';

  @override
  String get relayUnavailable => 'Сначала подключитесь к серверу ретрансляции';

  @override
  String get peerBusy => 'Устройство обрабатывает другой запрос сопряжения';

  @override
  String get peerPairingBlocked =>
      'The other device has blocked this one; ask them to unblock it first';

  @override
  String get peerRelayPairingOff =>
      'Устройство не принимает запросы сопряжения через ретранслятор';

  @override
  String incomingRequest(String deviceName) {
    return '«$deviceName» запрашивает сопряжение с этим устройством';
  }

  @override
  String outgoingRequest(String deviceName) {
    return 'Сопряжение с «$deviceName»';
  }

  @override
  String get waitingPeer => 'Ожидание подтверждения…';

  @override
  String get peerAccepted => 'Другое устройство подтвердило';

  @override
  String get peerRejected => 'Другое устройство отклонило сопряжение';

  @override
  String get peerTimeout => 'Другое устройство не подтвердило вовремя';

  @override
  String get pairingFailed => 'Сбой сопряжения';

  @override
  String pairingSucceeded(String deviceName) {
    return 'Сопряжение с «$deviceName» завершено';
  }

  @override
  String get codesMatch => 'Числа совпадают, выполнить сопряжение';

  @override
  String get codesDiffer => 'Не совпадают, отменить';

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
  String get pairedDevicesTitle => 'Сопряжённые устройства';

  @override
  String get pairedDevicesEmpty => 'Сопряжённых устройств пока нет';

  @override
  String get addPairedDevice => 'Сопрячь новое устройство';

  @override
  String get unpair => 'Разорвать сопряжение';

  @override
  String unpairConfirm(String deviceName) {
    return 'После удаления «$deviceName» потребуется снова сверить числа. Продолжить?';
  }

  @override
  String get deviceCodeLabel => 'Код этого устройства';

  @override
  String get title => 'Сервер ретрансляции';

  @override
  String get description =>
      'Передаёт файлы через ваш собственный сервер, когда устройства не в одной сети. Прямое соединение всегда в приоритете.';

  @override
  String get encryptionNotice =>
      'Файлы шифруются сквозным образом между двумя сопряжёнными устройствами, расшифровать их может только получатель. Сервер видит лишь время передачи и объём.';

  @override
  String get acceptPairingLabel =>
      'Принимать запросы сопряжения через ретранслятор';

  @override
  String get acceptPairingHint =>
      'Любое устройство с токеном сервера может запросить сопряжение с вашим кодом. Отклонённое устройство больше не появится.';

  @override
  String get iosForegroundNotice =>
      'На iOS приём через ретрансляцию работает только при открытом приложении.';

  @override
  String get enableLabel => 'Включить ретрансляцию';

  @override
  String get serverUrlLabel => 'Адрес сервера';

  @override
  String get tokenLabel => 'Токен доступа';

  @override
  String get invalidUrl => 'Адрес должен начинаться с http:// или https://';

  @override
  String get insecureUrlWarning =>
      'С http:// трафик не шифруется, только для локальной отладки';

  @override
  String get testConnection => 'Проверить подключение';

  @override
  String get testSucceeded => 'Подключение выполнено';

  @override
  String get save => 'Сохранить';

  @override
  String get statusDisabled => 'Выключено';

  @override
  String get statusConnecting => 'Подключение…';

  @override
  String get statusConnected => 'Подключено';

  @override
  String get statusReconnecting => 'Переподключение…';

  @override
  String get statusRejected => 'Отклонено сервером';

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
  String get lanRouteUnavailable => 'Устройство недоступно по локальной сети';

  @override
  String get relayRouteUnavailable =>
      'Устройство недоступно через сервер ретрансляции';

  @override
  String get relayNotConnected => 'Нет подключения к серверу ретрансляции';

  @override
  String get relayPeerOffline =>
      'Получатель должен открыть приложение, чтобы принять через ретрансляцию';

  @override
  String get relayPeerNotPaired =>
      'Получатель не добавил это устройство в список доверенных';

  @override
  String get relayPeerBusy => 'Получатель обрабатывает другую партию файлов';

  @override
  String get relayNeedsPairedDevice =>
      'Для передачи через ретрансляцию нужно сначала выполнить сопряжение';

  @override
  String get relayNegotiatingSession => 'Установка зашифрованного сеанса…';

  @override
  String get relayIdentityMismatch =>
      'Недействительная подпись: возможно, это не сопряжённое устройство';

  @override
  String get relayTransferNotice =>
      'Передача через сервер ретрансляции, скорость ограничена его каналом';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return 'Соединение прервано, повтор ($attempt/$maxAttempts)…';
  }
}
