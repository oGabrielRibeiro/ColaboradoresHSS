import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/theme/app_theme.dart';

class DragAndDropArea extends StatefulWidget {
  final ValueChanged<FilePickerResult?> onFilePicked;
  final String label;
  final String? currentFileName;
  final bool isLoading;

  const DragAndDropArea({
    super.key,
    required this.onFilePicked,
    this.label = 'Arraste e solte seu arquivo aqui ou clique para selecionar',
    this.currentFileName,
    this.isLoading = false,
  });

  @override
  State<DragAndDropArea> createState() => _DragAndDropAreaState();
}

class _DragAndDropAreaState extends State<DragAndDropArea> {
  bool _isHovering = false;

  Future<void> _pickFile() async {
    if (widget.isLoading) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    widget.onFilePicked(result);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // Para plataformas nao-web, apenas um botao para selecionar arquivos
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: widget.isLoading ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: Text(widget.currentFileName ?? 'Selecionar arquivo'),
          ),
          if (widget.currentFileName != null && !widget.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Arquivo atual: ${widget.currentFileName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      );
    }

    // Area de arrastar e soltar especifica para web
    return MouseRegion(
      onHover: (event) {
        if (!_isHovering) {
          setState(() {
            _isHovering = true;
          });
        }
      },
      onExit: (event) {
        setState(() {
          _isHovering = false;
        });
      },
      child: GestureDetector(
        onTap: widget.isLoading ? null : _pickFile,
        child: DragTarget<FilePickerResult>(
          onWillAcceptWithDetails: (details) {
            setState(() => _isHovering = true);
            return true;
          },
          onLeave: (data) {
            setState(() => _isHovering = false);
          },
          onAcceptWithDetails: (details) {
            setState(() => _isHovering = false);
            widget.onFilePicked(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              height: 120,
              decoration: BoxDecoration(
                color: _isHovering
                    ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovering
                      ? AppTheme.primaryGreen
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: widget.isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: _isHovering
                                ? AppTheme.primaryGreen
                                : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.currentFileName != null
                                ? 'Arquivo atual: ${widget.currentFileName}'
                                : widget.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _isHovering
                                      ? AppTheme.primaryGreen
                                      : Colors.grey,
                                ),
                          ),
                          if (widget.currentFileName != null)
                            Text(
                              'Clique ou arraste para substituir',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
