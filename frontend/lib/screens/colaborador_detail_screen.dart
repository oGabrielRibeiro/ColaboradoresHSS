  Widget _buildDocumentosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documentos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_documentos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('Nenhum documento encontrado.')),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _documentos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = _documentos[index];
              return DocumentoCard(
                documento: doc,
                onOpen: () => _abrirArquivo(doc.arquivoPath),
                onReplace: () => _substituirDocumento(doc),
              );
            },
          ),
      ],
    );
  }

  Future<void> _substituirDocumento(Documento doc) async {
    DateTime? novaData;
    FilePickerResult? arquivoResult;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Substituir Documento', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                // Data de validade
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(novaData == null
                    ? 'Selecionar nova data*'
                    : 'Data: ${DateFormat('dd/MM/yyyy').format(novaData!)}'),
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: const Locale('pt', 'BR'),
                    );
                    if (data != null) setState(() => novaData = data);
                  },
                ),
                const SizedBox(height: 8),
                // Arquivo
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(arquivoResult?.files.single.name ?? 'Selecionar arquivo*'),
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
                      allowMultiple: false,
                    );
                    if (result != null) setState(() => arquivoResult = result);
                  },
                ),
                const SizedBox(height: 16),
                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (novaData != null && arquivoResult != null)
                          ? () async {
                              try {
                                await ApiService.uploadArquivo(
                                  arquivoResult!,
                                  documentoId: doc.id,
                                  novaValidade: novaData!.toIso8601String(),
                                );
                                if (mounted) {
                                  Navigator.pop(context, true);
                                  _carregarDados();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Documento substituído com sucesso!')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  Navigator.pop(context, false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro ao substituir: ${e.toString()}')),
                                  );
                                }
                              }
                            }
                          : null,
                        child: const Text('Substituir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == true) {
      _carregarDados();
    }
  }
