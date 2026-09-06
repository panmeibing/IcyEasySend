// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => 'Versão';

  @override
  String get navHome => 'Início';

  @override
  String get navHistory => 'Histórico';

  @override
  String get navSettings => 'Configurações';

  @override
  String get homeTitle => 'Início';

  @override
  String get serverStatus => 'Status do Servidor';

  @override
  String get serverRunning => 'Em Execução';

  @override
  String get serverStopped => 'Parado';

  @override
  String get serverAddress => 'Endereço do Servidor';

  @override
  String get deviceName => 'Nome do Dispositivo';

  @override
  String get storageSpace => 'Espaço de Armazenamento';

  @override
  String get availableSpace => 'Espaço Disponível';

  @override
  String get sendFiles => 'Enviar Arquivos';

  @override
  String get receiveFiles => 'Receber Arquivos';

  @override
  String get selectFiles => 'Selecionar Arquivos';

  @override
  String get selectFolder => 'Selecionar Pasta';

  @override
  String get dragDropHint => 'Arraste arquivos para aqui';

  @override
  String get noFilesSelected => 'Nenhum arquivo selecionado';

  @override
  String filesSelected(int count) {
    return '$count arquivos selecionados';
  }

  @override
  String get clearSelection => 'Limpar Seleção';

  @override
  String get startSending => 'Iniciar Envio';

  @override
  String get sending => 'Enviando';

  @override
  String get sendSuccess => 'Envio Bem-sucedido';

  @override
  String get sendFailed => 'Falha no Envio';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get historyTitle => 'Histórico de Transferências';

  @override
  String get noHistory => 'Nenhum histórico';

  @override
  String get clearHistory => 'Limpar Histórico';

  @override
  String get sent => 'Enviado';

  @override
  String get received => 'Recebido';

  @override
  String get failed => 'Falhou';

  @override
  String get fileSize => 'Tamanho do Arquivo';

  @override
  String get time => 'Hora';

  @override
  String get deleteItem => 'Excluir Registro';

  @override
  String get deleteItemConfirm =>
      'Tem certeza de que deseja excluir este registro?';

  @override
  String get openFile => 'Abrir Arquivo';

  @override
  String get openFolder => 'Abrir Pasta';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get general => 'Geral';

  @override
  String get language => 'Idioma';

  @override
  String get deviceNameSetting => 'Nome do Dispositivo';

  @override
  String get editDeviceName => 'Editar Nome do Dispositivo';

  @override
  String get deviceNameHint => 'Digite o nome do dispositivo';

  @override
  String get deviceNameEmpty => 'O nome do dispositivo não pode estar vazio';

  @override
  String get port => 'Porta';

  @override
  String get portHint => 'Digite o número da porta';

  @override
  String get portInvalid => 'Número de porta inválido';

  @override
  String get portInUse => 'Porta já em uso';

  @override
  String get savePath => 'Caminho de Salvamento';

  @override
  String get selectSavePath => 'Selecionar Caminho de Salvamento';

  @override
  String get savePathDesc =>
      'Os arquivos recebidos são salvos aqui. Por padrão, usa-se a pasta de downloads do sistema.';

  @override
  String get savePathDefaultBadge => 'Padrão';

  @override
  String get savePathUnavailable =>
      'Não foi possível obter o caminho de salvamento';

  @override
  String get savePathSavedSuccess =>
      'Caminho de salvamento definido com sucesso';

  @override
  String get savePathNotWritable =>
      'Não é possível gravar nesta pasta. Escolha outro local ou verifique as permissões.';

  @override
  String get resetSavePathToDefault => 'Usar pasta padrão';

  @override
  String get savePathResetSuccess =>
      'Restaurado para a pasta de downloads do sistema';

  @override
  String get autoStart => 'Iniciar Automaticamente';

  @override
  String get autoStartDesc =>
      'Iniciar serviço automaticamente ao abrir o aplicativo';

  @override
  String get network => 'Rede';

  @override
  String get networkDiagnostics => 'Diagnóstico de Rede';

  @override
  String get scanDevices => 'Procurar dispositivos';

  @override
  String get scanDevicesTitle => 'Procurar dispositivos na LAN';

  @override
  String get scanningDevices => 'A procurar na rede local...';

  @override
  String scanProgress(int scanned, int total, int found) {
    String _temp0 = intl.Intl.pluralLogic(
      found,
      locale: localeName,
      other: 'Analisado $scanned/$total, $found dispositivos encontrados',
      one: 'Analisado $scanned/$total, $found dispositivo encontrado',
    );
    return '$_temp0';
  }

  @override
  String get noDevicesFound => 'Nenhum dispositivo encontrado';

  @override
  String get noDevicesFoundHint =>
      'Certifique-se de que o dispositivo de destino iniciou o servidor e está na mesma rede. Verifique o isolamento AP do router e a firewall.';

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
  String get rescan => 'Procurar novamente';

  @override
  String get runDiagnostics => 'Executar Diagnóstico';

  @override
  String get about => 'Sobre';

  @override
  String get version => 'Versão';

  @override
  String get checkUpdate => 'Verificar Atualização';

  @override
  String get feedback => 'Feedback';

  @override
  String get openSource => 'Licenças de Código Aberto';

  @override
  String get license => 'Licença';

  @override
  String get permissionRequired => 'Permissão Necessária';

  @override
  String get permissionDenied => 'Permissão Negada';

  @override
  String get permissionPermanentlyDenied => 'Permissão Negada Permanentemente';

  @override
  String get permissionStorage => 'Permissão de Armazenamento';

  @override
  String get permissionStorageDesc =>
      'Permissão de armazenamento necessária para salvar e ler arquivos';

  @override
  String get permissionNotification => 'Permissão de Notificação';

  @override
  String get permissionNotificationDesc =>
      'Permissão de notificação necessária para exibir progresso de transferência';

  @override
  String get openSettings => 'Abrir Configurações';

  @override
  String get permissionWarning =>
      'Algumas permissões não foram concedidas, algumas funcionalidades podem ser limitadas';

  @override
  String get error => 'Erro';

  @override
  String get errorUnknown => 'Erro Desconhecido';

  @override
  String get errorNetwork => 'Erro de Rede';

  @override
  String get errorFileNotFound => 'Arquivo Não Encontrado';

  @override
  String get errorPermission => 'Erro de Permissão';

  @override
  String get errorStorage => 'Erro de Armazenamento';

  @override
  String get errorServer => 'Erro do Servidor';

  @override
  String get errorServerStart => 'Falha ao Iniciar Servidor';

  @override
  String get errorServerStop => 'Falha ao Parar Servidor';

  @override
  String get errorConnection => 'Erro de Conexão';

  @override
  String get errorTimeout => 'Tempo de Conexão Esgotado';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get copied => 'Copiado';

  @override
  String get copyFailed => 'Falha ao Copiar';

  @override
  String get saved => 'Salvo';

  @override
  String get saveFailed => 'Falha ao Salvar';

  @override
  String get deleted => 'Excluído';

  @override
  String get deleteFailed => 'Falha ao Excluir';

  @override
  String get loading => 'Carregando';

  @override
  String get success => 'Sucesso';

  @override
  String get warning => 'Aviso';

  @override
  String get info => 'Informação';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Fechar';

  @override
  String get selectFilesFailed => 'Falha ao selecionar arquivos';

  @override
  String get selectFolderFailed => 'Falha ao selecionar pasta';

  @override
  String folderFilesAdded(int count) {
    return '$count arquivos adicionados da pasta';
  }

  @override
  String get folderContainsNoFiles =>
      'A pasta selecionada não contém arquivos para enviar';

  @override
  String get openFileFailed => 'Falha ao abrir arquivo';

  @override
  String get openFolderFailed => 'Falha ao abrir pasta';

  @override
  String get fileNotExist => 'Arquivo não existe';

  @override
  String get folderNotExist => 'Pasta não existe';

  @override
  String get diagnosticsTitle => 'Diagnóstico de Rede';

  @override
  String get diagnosticsRunning => 'Diagnóstico em execução...';

  @override
  String get diagnosticsComplete => 'Diagnóstico concluído';

  @override
  String get diagnosticsFailed => 'Diagnóstico falhou';

  @override
  String get networkStatus => 'Status da Rede';

  @override
  String get wifiConnected => 'WiFi Conectado';

  @override
  String get wifiDisconnected => 'WiFi Desconectado';

  @override
  String get mobileData => 'Dados Móveis';

  @override
  String get noConnection => 'Sem Conexão de Rede';

  @override
  String get ipAddress => 'Endereço IP';

  @override
  String get noIpAddress => 'Sem Endereço IP';

  @override
  String get serverStatusCheck => 'Verificação de Status do Servidor';

  @override
  String get portCheck => 'Verificação de Porta';

  @override
  String get portAvailable => 'Porta Disponível';

  @override
  String get portUnavailable => 'Porta Indisponível';

  @override
  String get suggestions => 'Sugestões';

  @override
  String get syncClipboard =>
      'Sincronizar área de transferência do outro dispositivo';

  @override
  String filesCount(int count) {
    return 'Enviar $count arquivos';
  }

  @override
  String get sendFile => 'Enviar Arquivo';

  @override
  String get shareViaQr => 'Compartilhar por QR';

  @override
  String get webShareTitle => 'Escanear para receber';

  @override
  String get webShareHint =>
      'O receptor pode escanear com a câmera do sistema e baixar no navegador, sem instalar o app. Fiquem na mesma Wi‑Fi / LAN. Alguns scanners de terceiros podem bloquear links LAN; use Copiar link.';

  @override
  String get webShareCopyLink => 'Copiar link';

  @override
  String get webShareLinkCopied => 'Link copiado';

  @override
  String get webShareStopSharing => 'Parar compartilhamento';

  @override
  String get webShareStopped => 'Compartilhamento web parado';

  @override
  String get webShareServerRequired =>
      'Inicie o servidor local antes de compartilhar por QR';

  @override
  String get webShareCreated =>
      'Compartilhamento web criado. O receptor pode escanear para baixar.';

  @override
  String get webShareFailed => 'Falha ao criar compartilhamento web';

  @override
  String get webSharePeerName => 'Compartilhamento web';

  @override
  String webShareFilesSummary(int count, String size) {
    return '$count arquivo(s) · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return 'Expira em $time';
  }

  @override
  String get releaseToAdd => 'Solte para adicionar arquivos';

  @override
  String get serverNotRunning =>
      'Servidor não está em execução, não é possível receber arquivos compartilhados';

  @override
  String get cannotReceiveFiles => 'Não é possível receber arquivos';

  @override
  String get sendingInProgress =>
      'Enviando arquivos, tente novamente mais tarde';

  @override
  String get pleaseTryLater => 'Tente novamente mais tarde';

  @override
  String filesAdded(int count) {
    return '$count arquivos compartilhados adicionados';
  }

  @override
  String get preparingSend => 'Preparando envio...';

  @override
  String get transferring => 'Transferindo';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: Transferindo...';
  }

  @override
  String get networkChanged => 'Rede alterada, endereço do servidor atualizado';

  @override
  String get serverAddressUpdated => 'Endereço do servidor atualizado';

  @override
  String get portCannotBeEmpty => 'Porta não pode estar vazia';

  @override
  String get portMustBeNumber => 'Porta deve ser um número';

  @override
  String get portRange => 'Faixa de porta: 1-65535';

  @override
  String ipDeleted(String ip) {
    return 'IP excluído: $ip';
  }

  @override
  String get runningDiagnostics => 'Executando diagnóstico de rede...';

  @override
  String get targetDeviceInfo => 'Informações do Dispositivo de Destino';

  @override
  String get fullAddress => 'Endereço Completo';

  @override
  String get targetNotSet => 'Dispositivo de destino não configurado';

  @override
  String get diagnosticsReport => 'Relatório de Diagnóstico de Rede';

  @override
  String get reportCopied =>
      'Relatório de diagnóstico copiado para a área de transferência';

  @override
  String get deviceNameCannotBeEmpty =>
      'Nome do dispositivo não pode estar vazio';

  @override
  String get deviceNameSaved => 'Nome do dispositivo salvo';

  @override
  String get resetDeviceName => 'Redefinir Nome do Dispositivo';

  @override
  String resetDeviceNameConfirm(String model) {
    return 'Tem certeza de que deseja redefinir o nome do dispositivo para \"$model\"?';
  }

  @override
  String get reset => 'Redefinir';

  @override
  String get confirmChange => 'Confirmar Alteração';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return 'Tem certeza de que deseja alterar o número de transferências simultâneas de $from para $to?\n\nDica: Aumentar a simultaneidade pode melhorar a velocidade de transferência, mas também aumentará a carga do dispositivo';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return 'Tem certeza de que deseja alterar o número de transferências simultâneas de $from para $to?\n\nDica: Diminuir a simultaneidade pode reduzir a carga do dispositivo, mas pode diminuir a velocidade de transferência';
  }

  @override
  String get concurrentTransfersHint => 'Dica de Transferências Simultâneas';

  @override
  String get concurrentTransfersSaved =>
      'Número de transferências simultâneas salvo';

  @override
  String get enterValidNumber => 'Digite um número válido';

  @override
  String historyCountRange(int min, int max) {
    return 'Faixa de contagem de histórico: $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return 'Tem certeza de que deseja alterar o número máximo de registros de histórico de $from para $to?\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return 'Contagem atual de histórico: $count registros\n\n';
  }

  @override
  String get historyWarning =>
      '⚠️ Aviso: O número de registros de histórico salvos é maior que o número definido.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return 'Apenas os $max registros mais recentes serão mantidos, os $toDelete registros antigos excedentes serão excluídos.';
  }

  @override
  String get historyHint =>
      'Dica: A nova configuração entrará em vigor na próxima vez que o histórico for salvo.';

  @override
  String historyDeleted(int count) {
    return 'Configuração salva, $count registros antigos excluídos';
  }

  @override
  String get maxHistorySaved => 'Número máximo de registros de histórico salvo';

  @override
  String clipboardSizeRange(int min, int max) {
    return 'Faixa de tamanho da área de transferência: $min-$max MB';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return 'Tem certeza de que deseja alterar o tamanho máximo da área de transferência de $from MB para $to MB?\n\n';
  }

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ Dica: Após reduzir o limite, o conteúdo da área de transferência que exceder o limite não poderá ser sincronizado, recomenda-se usar a função de transferência de arquivos.';

  @override
  String get clipboardSizeIncreaseHint =>
      'Dica: Após aumentar o limite, você pode sincronizar conteúdo maior da área de transferência, mas pode afetar a velocidade de transferência.';

  @override
  String get maxClipboardSizeSaved =>
      'Tamanho máximo da área de transferência salvo';

  @override
  String get ipValidationEnabled => 'Validação de endereço IP ativada';

  @override
  String get ipValidationDisabled => 'Validação de endereço IP desativada';

  @override
  String get deviceSecretKeyCleared => 'Chave secreta do dispositivo limpa';

  @override
  String get deviceSecretKeySaved => 'Chave secreta do dispositivo salva';

  @override
  String get loadingDevInfo => 'Carregando informações de desenvolvimento...';

  @override
  String get copyLog => 'Copiar Log';

  @override
  String logCopied(int lines) {
    return 'Últimas $lines linhas do log copiadas para a área de transferência';
  }

  @override
  String get logFileEmpty => 'Arquivo de log vazio';

  @override
  String get devInfo => 'Informações de Desenvolvimento';

  @override
  String labelCopied(String label, String value) {
    return '$label copiado: $value';
  }

  @override
  String get transferSettings => 'Configurações de Transferência';

  @override
  String get concurrentTransfers => 'Número de Transferências Simultâneas';

  @override
  String concurrentTransfersDesc(int max) {
    return 'Número de arquivos transferidos simultaneamente (1-$max)';
  }

  @override
  String get concurrentTransfersHintText =>
      'Um número maior de transferências simultâneas pode utilizar melhor a largura de banda, mas pode aumentar a carga do dispositivo';

  @override
  String get maxHistory => 'Número Máximo de Registros de Histórico';

  @override
  String maxHistoryDesc(int min, int max) {
    return 'Número máximo de registros de transferência salvos ($min-$max)';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return 'Digite o número ($min-$max)';
  }

  @override
  String get oldRecordsAutoDelete =>
      'Registros antigos que excederem o número definido serão excluídos automaticamente, mantendo apenas os mais recentes';

  @override
  String get maxClipboard => 'Tamanho Máximo da Área de Transferência';

  @override
  String maxClipboardDesc(int min, int max) {
    return 'Tamanho máximo da área de transferência permitido para sincronização ($min-$max MB)';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return 'Digite o tamanho ($min-$max MB)';
  }

  @override
  String get clipboardSyncLimit =>
      'Conteúdo da área de transferência que exceder este tamanho não poderá ser sincronizado, recomenda-se usar a função de transferência de arquivos';

  @override
  String get ipValidation => 'Validação de Endereço IP';

  @override
  String get ipValidationDesc =>
      'Verificar se o IP do dispositivo de destino está no mesmo segmento de rede';

  @override
  String get ipValidationEnabledHint =>
      'Quando ativado, verificará se o IP de destino está no mesmo segmento de rede, pode evitar conexão com dispositivo errado';

  @override
  String get ipValidationDisabledHint =>
      'Quando desativado, não verificará o segmento de rede do IP, adequado para ambientes de rede complexos (como hotspot, VPN, etc.)';

  @override
  String get deviceSecretKey => 'Chave secreta deste dispositivo';

  @override
  String get deviceSecretKeyDesc =>
      'Após configurar, outros dispositivos precisam fornecer a chave correta para ignorar a confirmação';

  @override
  String get deviceSecretKeyHint =>
      'Digite a chave secreta (deixe em branco para não usar chave)';

  @override
  String get notSet => 'Não Definido';

  @override
  String get author => 'Autor';

  @override
  String get appDescription =>
      'Uma ferramenta simples e fácil de usar para transferência de arquivos em rede local';

  @override
  String get targetDeviceIP => 'Endereço IP do Dispositivo de Destino';

  @override
  String get ipHint => 'Por exemplo: 192.168.1.100';

  @override
  String get clear => 'Limpar';

  @override
  String get history => 'Histórico';

  @override
  String get targetDevicePort => 'Porta do Dispositivo de Destino';

  @override
  String resetToDefaultPort(int port) {
    return 'Redefinir para porta padrão ($port)';
  }

  @override
  String get targetDeviceSecretKey =>
      'Chave Secreta do Dispositivo de Destino (Opcional)';

  @override
  String get secretKeyHint => 'Chave correta pode ignorar confirmação';

  @override
  String get aboutSecretKey => 'Sobre Chave Secreta';

  @override
  String get secretKeyFeatureTitle => 'Descrição da Função de Chave Secreta';

  @override
  String get secretKeyFeatureDesc =>
      'Se o dispositivo de destino tiver configurado uma chave secreta, inserir a chave correta pode ignorar a caixa de confirmação e transferir arquivos ou sincronizar a área de transferência diretamente.';

  @override
  String get secretKeyUsageSteps => 'Passos de uso:';

  @override
  String get secretKeyUsageStep1 =>
      '1. O dispositivo de destino configura a chave secreta local na página de configurações';

  @override
  String get secretKeyUsageStep2 =>
      '2. Digite a chave secreta do dispositivo de destino nesta caixa de entrada';

  @override
  String get secretKeyUsageStep3 =>
      '3. Ao enviar arquivos ou solicitar área de transferência, se a chave estiver correta, o outro lado aceitará automaticamente';

  @override
  String get secretKeyTip =>
      'Dica: Deixe em branco para usar o método de confirmação manual tradicional';

  @override
  String get secretKeyDescription => 'Descrição da Chave Secreta';

  @override
  String get clearSecretKey => 'Limpar Chave Secreta';

  @override
  String get gotIt => 'Entendi';

  @override
  String get localIP => 'IP Local';

  @override
  String ipCopied(String ip) {
    return 'Endereço IP copiado: $ip';
  }

  @override
  String get transferred => 'Transferido';

  @override
  String get transferSpeed => 'Velocidade de Transferência';

  @override
  String get remainingTime => 'Tempo Restante';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Transferindo $progressString%';
  }

  @override
  String get storagePermissionMessage =>
      'Permissão de armazenamento necessária para selecionar arquivos. Ative a permissão manualmente nas configurações.';

  @override
  String get checkingTargetDevice => 'Verificando dispositivo de destino...';

  @override
  String get targetDeviceUnavailable => 'Dispositivo de destino indisponível';

  @override
  String targetDeviceError(String error) {
    return 'Dispositivo de destino indisponível\nErro: $error';
  }

  @override
  String get connectionFailed => 'Falha na conexão';

  @override
  String get transferHistory => 'Histórico de Transferências';

  @override
  String get clearHistoryTitle => 'Limpar Histórico';

  @override
  String get clearHistoryMessage =>
      'Tem certeza de que deseja limpar todo o histórico de transferências? Esta operação não pode ser desfeita.';

  @override
  String get noFilteredRecords => 'Nenhum registro correspondente';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterSent => 'Enviados';

  @override
  String get filterReceived => 'Recebidos';

  @override
  String get statisticsInfo => 'Informações Estatísticas';

  @override
  String transfersCount(int count) {
    return '$count transferências';
  }

  @override
  String get totalTransfers => 'Total de Transferências';

  @override
  String get successfulTransfers => 'Sucesso';

  @override
  String get failedTransfers => 'Falha';

  @override
  String get sentFiles => 'Enviados';

  @override
  String get receivedFiles => 'Recebidos';

  @override
  String get totalSize => 'Tamanho Total';

  @override
  String get moreActions => 'Mais Ações';

  @override
  String get deleteRecord => 'Excluir Registro';

  @override
  String get viewDetails => 'Ver Detalhes';

  @override
  String get deleteRecordTitle => 'Excluir Registro';

  @override
  String deleteRecordMessage(String fileName) {
    return 'Tem certeza de que deseja excluir o registro de transferência de \"$fileName\"?\n\nNota: Isso excluirá apenas o registro, não o arquivo em si.';
  }

  @override
  String get deleteRecordNote =>
      'Nota: Isso excluirá apenas o registro, não o arquivo em si.';

  @override
  String get recordDeleted => 'Registro excluído';

  @override
  String get filePathNotExist => 'Caminho do arquivo não existe';

  @override
  String get cannotOpenFile => 'Não é possível abrir o arquivo';

  @override
  String cannotOpenFileWithMessage(String message) {
    return 'Não é possível abrir o arquivo: $message';
  }

  @override
  String get iosNoFolderSupport => 'iOS não suporta abrir pastas diretamente';

  @override
  String get cannotOpenFolder => 'Não é possível abrir a pasta';

  @override
  String get recentFilesOpened =>
      'Arquivos recentes abertos, por favor procure manualmente';

  @override
  String get receiveRecord => 'Registro de Recebimento';

  @override
  String get sendRecord => 'Registro de Envio';

  @override
  String get fileName => 'Nome do Arquivo';

  @override
  String get fromDevice => 'Do Dispositivo';

  @override
  String get toDevice => 'Para o Dispositivo';

  @override
  String get deviceIP => 'IP do Dispositivo';

  @override
  String get transferTime => 'Hora da Transferência';

  @override
  String get transferStatus => 'Status da Transferência';

  @override
  String get statusSuccess => 'Sucesso';

  @override
  String get statusFailed => 'Falha';

  @override
  String get savedLocation => 'Local de Salvamento';

  @override
  String get copy => 'Copiar';

  @override
  String get pathCopied => 'Caminho copiado para a área de transferência';

  @override
  String get from => 'De';

  @override
  String get sentTo => 'Enviado para';

  @override
  String get clipboardRequest => 'Solicitação de Área de Transferência';

  @override
  String clipboardRequestFrom(String deviceName) {
    return 'O dispositivo \"$deviceName\" solicita obter o conteúdo da sua área de transferência';
  }

  @override
  String get allowClipboardRequest => 'Permitir?';

  @override
  String get clipboardRequestMessage => 'Solicitação de Área de Transferência';

  @override
  String autoRejectIn(int seconds) {
    return 'Rejeição automática em $seconds segundos';
  }

  @override
  String get reject => 'Rejeitar';

  @override
  String get allow => 'Permitir';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceName passou na verificação da chave secreta, área de transferência compartilhada automaticamente';
  }

  @override
  String get clipboardRequestRejected =>
      'Usuário rejeitou a solicitação de área de transferência';

  @override
  String get clipboardEmpty => 'Área de transferência vazia';

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

    return 'Conteúdo da área de transferência muito grande ($actualSizeMBString MB), excede o limite do dispositivo de destino ($maxSizeMB MB). Recomenda-se usar a função de transferência de arquivos.';
  }

  @override
  String get clipboardContentSuccess =>
      'Conteúdo da área de transferência obtido com sucesso';

  @override
  String get invalidJsonFormat => 'Formato JSON inválido';

  @override
  String get serverInternalError => 'Erro interno do servidor';

  @override
  String get backgroundRejectNeedsSecretKey =>
      'O dispositivo está em segundo plano. Somente sincronização/recebimento automático com chave secreta correspondente é suportado.';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText =>
      'Aguardando transferências e sincronização da área de transferência em segundo plano';

  @override
  String get androidBackgroundReceiveHint =>
      'Em segundo plano, apenas dispositivos com chave secreta correspondente podem sincronizar ou enviar automaticamente. Mantenha a notificação persistente.';

  @override
  String get clipboardOverlay => 'Botão flutuante da área de transferência';

  @override
  String get clipboardOverlayDesc =>
      'Toque no botão flutuante para atualizar o cache de texto/imagem para sincronização em segundo plano';

  @override
  String get clipboardOverlayHint =>
      'Em segundo plano, apenas o último conteúdo atualizado pode ser sincronizado. Desativar limpa o cache e oculta o botão.';

  @override
  String get clipboardOverlayPermissionNeeded =>
      'Permita \"Exibir sobre outros apps\" nas configurações. O botão aparecerá ao retornar.';

  @override
  String get clipboardOverlayEnabledToast =>
      'Botão flutuante da área de transferência ativado';

  @override
  String get clipboardBackgroundCacheMiss =>
      'Não é possível ler a área de transferência do sistema em segundo plano e não há cache. Abra o app ou toque no botão flutuante para atualizar.';

  @override
  String get requestingClipboard => 'Solicitando área de transferência...';

  @override
  String get clipboardSyncSuccess =>
      'Sincronização da área de transferência bem-sucedida';

  @override
  String get textClipboardSyncSuccess =>
      'Sincronização de texto da área de transferência bem-sucedida';

  @override
  String get fileClipboardSyncSuccess =>
      'Sincronização de arquivo da área de transferência bem-sucedida\nPode ser colado no aplicativo ou gerenciador de arquivos';

  @override
  String get clipboardSyncFailed =>
      'Falha na sincronização da área de transferência';

  @override
  String get syncFailed => 'Falha na sincronização';

  @override
  String clipboardRequestError(String error) {
    return 'Erro ao solicitar área de transferência: $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return 'Os seguintes arquivos são inválidos ou inacessíveis:\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation =>
      'Aguardando confirmação do destinatário...';

  @override
  String get fileSendSuccess => 'Arquivo enviado com sucesso!';

  @override
  String filesSendSuccess(int count) {
    return '$count arquivos enviados com sucesso!';
  }

  @override
  String get allFilesSendFailed => 'Falha no envio de todos os arquivos';

  @override
  String get failedFiles => 'Arquivos com falha';

  @override
  String get transferComplete => 'Transferência concluída';

  @override
  String get successCount => 'Sucesso';

  @override
  String get failureCount => 'Falha';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) {
    return 'Sucesso: $successCount arquivos\nFalha: $failureCount arquivos\n\nArquivos com falha:\n$failedFiles';
  }

  @override
  String get preparingTransferInfo =>
      'Preparando informações de transferência...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return 'Aguardando confirmação do destinatário para $count arquivos...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return 'Transferindo arquivo $current/$total: $fileName';
  }

  @override
  String get receiverRejected => 'Destinatário rejeitou o recebimento';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return 'Destinatário rejeitou o recebimento\nCódigo de status: $statusCode';
  }

  @override
  String get transferIdNotFound => 'ID de transferência não encontrado';

  @override
  String get waitingForConfirmation => 'Aguardando confirmação...';

  @override
  String get preparingToReceive => 'Preparando para receber...';

  @override
  String get rejected => 'Rejeitado';

  @override
  String get receiveComplete => 'Recebimento concluído';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Recebendo... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return 'Recebendo $count arquivos';
  }

  @override
  String receiveFilesCount(int count) {
    return 'Receber $count arquivos';
  }

  @override
  String get sender => 'Remetente';

  @override
  String get totalSizeBatch => 'Tamanho Total';

  @override
  String get fileList => 'Lista de Arquivos';

  @override
  String get allFilesReceiveComplete => 'Todos os arquivos recebidos!';

  @override
  String get receivingFiles2 => 'Recebendo arquivos...';

  @override
  String autoRejectCountdown(int seconds) {
    return 'Receber estes arquivos? (Rejeição automática em $seconds segundos)';
  }

  @override
  String get rejectAll => 'Rejeitar Todos';

  @override
  String get acceptAll => 'Aceitar Todos';

  @override
  String get networkDiagnosticsReport => 'Relatório de Diagnóstico de Rede';

  @override
  String get localNetworkInterfaces => 'Interfaces de Rede Locais';

  @override
  String get noValidNetworkInterface =>
      'Nenhuma interface de rede válida encontrada';

  @override
  String get privateNetworkAddress => 'Endereço de Rede Privada';

  @override
  String get targetDeviceReachability =>
      'Acessibilidade do Dispositivo de Destino';

  @override
  String get canConnectToTarget => 'Pode conectar ao dispositivo de destino';

  @override
  String get cannotConnectToTarget =>
      'Não é possível conectar ao dispositivo de destino';

  @override
  String get healthCheckTest => 'Teste de Verificação de Saúde';

  @override
  String get healthCheckSuccess => 'Verificação de saúde bem-sucedida';

  @override
  String get healthCheckFailed => 'Verificação de saúde falhou';

  @override
  String get statusCode => 'Código de Status';

  @override
  String get response => 'Resposta';

  @override
  String get internetConnection => 'Conexão com a Internet';

  @override
  String get hasInternetConnection => 'Tem conexão com a internet';

  @override
  String get noInternetConnection => 'Sem conexão com a internet';

  @override
  String get networkConnectionFailed =>
      'Não é possível conectar ao dispositivo de destino, verifique a conexão de rede e o endereço IP';

  @override
  String get networkTimeout =>
      'Tempo de conexão esgotado, o dispositivo de destino pode estar offline ou a rede está instável';

  @override
  String get networkRequestFailed =>
      'Falha na solicitação de rede, verifique a conexão de rede';

  @override
  String get transferTimeout =>
      'Tempo de transferência esgotado, verifique a conexão de rede';

  @override
  String get transferInterrupted =>
      'Transferência interrompida, tente novamente';

  @override
  String get fileNotFound => 'Arquivo não existe';

  @override
  String get fileNotReadable =>
      'Não é possível ler o arquivo, certifique-se de que o arquivo existe e tem permissão de acesso';

  @override
  String get fileAccessError =>
      'Erro de acesso ao arquivo, verifique as permissões do arquivo';

  @override
  String get fileSaveFailed => 'Falha ao salvar arquivo';

  @override
  String get fileSizeMismatch =>
      'Falha ao salvar arquivo: tamanho do arquivo não corresponde';

  @override
  String get invalidFileName => 'Nome do arquivo contém caracteres ilegais';

  @override
  String get downloadsDirectoryUnavailable =>
      'Não é possível acessar o diretório de downloads';

  @override
  String get storageInsufficient =>
      'Espaço de armazenamento insuficiente, não é possível receber arquivo';

  @override
  String get diskFullTitle => 'Disco cheio';

  @override
  String get storageCheckFailed =>
      'Não é possível verificar o espaço de armazenamento';

  @override
  String get networkPermissionDenied =>
      'Permissão de acesso à rede necessária para transferir arquivos';

  @override
  String get storagePermissionDenied =>
      'Permissão de acesso ao armazenamento necessária para salvar arquivos';

  @override
  String serverStartFailed(String reason) {
    return 'Não é possível iniciar o servidor: $reason';
  }

  @override
  String get serverPortsOccupied =>
      'Não é possível iniciar o servidor: todas as portas estão ocupadas';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return 'Não é possível iniciar o servidor: portas $defaultPort-$maxPort estão todas ocupadas';
  }

  @override
  String get serverUnknownError =>
      'Não é possível iniciar o servidor: erro desconhecido';

  @override
  String get transferRejected =>
      'Destinatário rejeitou o recebimento do arquivo';

  @override
  String get fileTooLarge => 'Arquivo muito grande, máximo suportado 2GB';

  @override
  String get fileOrStorageFull =>
      'Arquivo muito grande ou espaço de armazenamento do destinatário insuficiente';

  @override
  String get receiveTimeout =>
      'Tempo de recebimento esgotado, rejeitado automaticamente';

  @override
  String get userRejected => 'Usuário rejeitou o recebimento do arquivo';

  @override
  String get ipAddressEmpty => 'Endereço IP não pode estar vazio';

  @override
  String get ipAddressInvalidFormat =>
      'Formato de endereço IP inválido, use o formato xxx.xxx.xxx.xxx';

  @override
  String get ipAddressInvalidRange =>
      'Formato de endereço IP inválido, cada número deve estar entre 0-255';

  @override
  String get ipAddressSpecial1 =>
      'Não é possível usar 0.0.0.0 como endereço de destino';

  @override
  String get ipAddressSpecial2 =>
      'Não é possível usar o endereço de broadcast 255.255.255.255';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) {
    return '⚠️ Incompatibilidade de segmento de rede\nIP local: $localIP (segmento: $localNetwork.x)\nIP de destino: $targetIP (segmento: $targetNetwork.x)\n\nDica: Os dois dispositivos precisam estar na mesma rede local (mesmo segmento) para transferir arquivos.\nPara endereços IPv4 Classe C, os três primeiros números dos dois endereços IP devem ser iguais, por exemplo, ambos 192.168.2, apenas o último número é diferente\nA maneira mais simples é conectar ambos os dispositivos ao mesmo WiFi ou roteador.\n';
  }

  @override
  String get responseParseError =>
      'Não é possível analisar a resposta do servidor';

  @override
  String get responseInvalidFormat =>
      'Formato de resposta do dispositivo de destino incorreto';

  @override
  String responseStatusCodeError(int statusCode) {
    return 'Servidor retornou código de status de erro: $statusCode';
  }

  @override
  String get fileSelectionError => 'Erro ao selecionar arquivo';

  @override
  String get fileSelectionCancelled => 'Seleção de arquivo cancelada';

  @override
  String genericError(String operation) {
    return 'Falha em $operation';
  }

  @override
  String unexpectedError(String details) {
    return 'Erro inesperado ocorreu: $details';
  }

  @override
  String networkError(String context) {
    return 'Erro de rede: $context';
  }

  @override
  String fileError(String context) {
    return 'Erro de arquivo: $context';
  }

  @override
  String permissionError(String permissionType) {
    return 'Permissão de $permissionType necessária para continuar a operação';
  }

  @override
  String get foregroundServiceChannelName =>
      'Serviço de transferência em segundo plano';

  @override
  String get foregroundServiceChannelDescription =>
      'Mantém o app pronto para receber arquivos LAN e pedidos da área de transferência em segundo plano';

  @override
  String get peerUnreachable =>
      'Não foi possível conectar ao dispositivo de destino';

  @override
  String get peerUnreachableBoth =>
      'Dispositivo inacessível (rede local e retransmissão)';

  @override
  String get peerUnsupported =>
      'A versão do outro dispositivo não suporta emparelhamento';

  @override
  String get identityMismatch =>
      'O código do dispositivo não corresponde à sua chave pública; emparelhamento cancelado';

  @override
  String get cannotPairSelf =>
      'Não é possível emparelhar o dispositivo consigo mesmo';

  @override
  String get pairingTitle => 'Emparelhamento de dispositivos';

  @override
  String get compareHint =>
      'Verifique se os dois dispositivos mostram exatamente o mesmo número. Caso contrário, a conexão pode ter sido adulterada.';

  @override
  String get compareHintRelay =>
      'Este dispositivo não está na mesma rede. Compare os 6 dígitos por telefone ou voz e confirme apenas se forem idênticos. Sem essa conferência não há proteção alguma.';

  @override
  String get pairOverRelay => 'Emparelhar pela retransmissão';

  @override
  String get enterDeviceCode =>
      'Digite o código de 32 caracteres do outro dispositivo';

  @override
  String get invalidDeviceCode =>
      'O código deve ter 32 caracteres hexadecimais';

  @override
  String get alreadyPaired => 'Esse dispositivo já está na lista de confiança';

  @override
  String get peerAlreadyPaired =>
      'The other device still trusts this one; unpair on that device first';

  @override
  String get relayUnavailable =>
      'Conecte-se primeiro ao servidor de retransmissão';

  @override
  String get peerBusy =>
      'O outro dispositivo está tratando de outra solicitação';

  @override
  String get peerPairingBlocked =>
      'The other device has blocked this one; ask them to unblock it first';

  @override
  String get peerRelayPairingOff =>
      'O outro dispositivo não aceita solicitações pela retransmissão';

  @override
  String incomingRequest(String deviceName) {
    return '\"$deviceName\" solicita emparelhamento com este dispositivo';
  }

  @override
  String outgoingRequest(String deviceName) {
    return 'Emparelhando com \"$deviceName\"';
  }

  @override
  String get waitingPeer => 'Aguardando confirmação…';

  @override
  String get peerAccepted => 'O outro dispositivo confirmou';

  @override
  String get peerRejected => 'O outro dispositivo recusou o emparelhamento';

  @override
  String get peerTimeout => 'O outro dispositivo não confirmou a tempo';

  @override
  String get pairingFailed => 'Falha no emparelhamento';

  @override
  String pairingSucceeded(String deviceName) {
    return 'Emparelhamento com \"$deviceName\" concluído';
  }

  @override
  String get codesMatch => 'Os números coincidem, emparelhar';

  @override
  String get codesDiffer => 'Diferentes, cancelar';

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
  String get pairedDevicesTitle => 'Dispositivos emparelhados';

  @override
  String get pairedDevicesEmpty => 'Ainda não há dispositivos emparelhados';

  @override
  String get addPairedDevice => 'Emparelhar novo dispositivo';

  @override
  String get unpair => 'Desemparelhar';

  @override
  String unpairConfirm(String deviceName) {
    return 'Após remover \"$deviceName\" será preciso comparar os números novamente. Continuar?';
  }

  @override
  String get deviceCodeLabel => 'Código deste dispositivo';

  @override
  String get title => 'Servidor de retransmissão';

  @override
  String get description =>
      'Encaminha arquivos pelo seu próprio servidor quando os dispositivos não estão na mesma rede. A conexão direta sempre tem prioridade.';

  @override
  String get encryptionNotice =>
      'Os arquivos são criptografados de ponta a ponta entre os dois dispositivos emparelhados; só eles conseguem descriptografar. O servidor vê apenas o horário e a quantidade de bytes.';

  @override
  String get acceptPairingLabel =>
      'Aceitar solicitações de emparelhamento pela retransmissão';

  @override
  String get acceptPairingHint =>
      'Qualquer dispositivo com o token do servidor pode solicitar emparelhamento com o seu código. Um dispositivo recusado não aparece de novo.';

  @override
  String get iosForegroundNotice =>
      'No iOS só é possível receber pela retransmissão com o aplicativo aberto.';

  @override
  String get enableLabel => 'Ativar retransmissão';

  @override
  String get serverUrlLabel => 'Endereço do servidor';

  @override
  String get tokenLabel => 'Token de acesso';

  @override
  String get invalidUrl => 'O endereço deve começar com http:// ou https://';

  @override
  String get insecureUrlWarning =>
      'Com http:// o tráfego não é criptografado, use só em testes locais';

  @override
  String get testConnection => 'Testar conexão';

  @override
  String get testSucceeded => 'Conexão bem-sucedida';

  @override
  String get save => 'Salvar';

  @override
  String get statusDisabled => 'Desativado';

  @override
  String get statusConnecting => 'Conectando…';

  @override
  String get statusConnected => 'Conectado';

  @override
  String get statusReconnecting => 'Reconectando…';

  @override
  String get statusRejected => 'Rejeitado pelo servidor';

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
      'Não é possível acessar o dispositivo pela rede local';

  @override
  String get relayRouteUnavailable =>
      'Não é possível acessar o dispositivo pelo servidor de retransmissão';

  @override
  String get relayNotConnected => 'Não conectado ao servidor de retransmissão';

  @override
  String get relayPeerOffline =>
      'O destinatário precisa abrir o aplicativo para receber pela retransmissão';

  @override
  String get relayPeerNotPaired =>
      'O destinatário não tem este dispositivo na lista de confiança';

  @override
  String get relayPeerBusy =>
      'O destinatário está processando outro lote de arquivos';

  @override
  String get relayNeedsPairedDevice =>
      'A transferência por retransmissão exige emparelhamento prévio';

  @override
  String get relayNegotiatingSession =>
      'Estabelecendo uma sessão criptografada…';

  @override
  String get relayIdentityMismatch =>
      'Assinatura inválida; pode não ser o dispositivo emparelhado';

  @override
  String get relayTransferNotice =>
      'Transferindo pelo servidor de retransmissão; a velocidade depende da banda dele';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return 'Conexão interrompida, tentando novamente ($attempt/$maxAttempts)…';
  }
}
