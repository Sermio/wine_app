import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/models/elemento_cata.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateCataScreen extends StatefulWidget {
  const CreateCataScreen({super.key});

  @override
  State<CreateCataScreen> createState() => _CreateCataScreenState();
}

class _CreateCataScreenState extends State<CreateCataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final List<_ElementoCataInput> _elementos = [_ElementoCataInput()];
  DateTime? _fecha;
  bool fechaObligatoria = false;
  bool elementosValidos = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Nueva cata', style: appBarTitleStyle),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: shadowColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(spacingM),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    initialDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _fecha = date;
                      fechaObligatoria = false;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: spacingM,
                    vertical: spacingM,
                  ),
                  margin: const EdgeInsets.only(bottom: spacingS),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(radiusM),
                    border: Border.all(
                      color: fechaObligatoria ? errorColor : dividerColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: elevationS,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: fechaObligatoria ? errorColor : primaryColor,
                      ),
                      const SizedBox(width: spacingM),
                      Text(
                        _fecha == null
                            ? 'Seleccionar fecha'
                            : _fecha!.toLocal().toString().split(' ')[0],
                        style: TextStyle(
                          color: fechaObligatoria
                              ? errorColor
                              : textPrimaryColor,
                          fontSize: 16,
                          fontWeight: _fecha == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _styledTextField(
                controller: nombreController,
                label: 'Nombre de la cata',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Este campo es obligatorio'
                    : null,
              ),
              if (fechaObligatoria)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'La fecha es obligatoria',
                    style: TextStyle(color: errorColor, fontSize: 12),
                  ),
                ),
              const SizedBox(height: spacingM),
              ..._elementos.asMap().entries.map((entry) {
                final index = entry.key;
                final elemento = entry.value;
                return elemento.build(
                  context,
                  index,
                  onRemove: () => setState(() => _elementos.removeAt(index)),
                  onUpdate: () =>
                      setState(() {}), // <- Esto hace que se redibuje
                );
              }),
              const SizedBox(height: spacingL),
              FloatingActionButton(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: elevationM,
                onPressed: () =>
                    setState(() => _elementos.add(_ElementoCataInput())),
                child: const Icon(Icons.add),
              ),
              if (!elementosValidos)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Debe haber al menos un elemento válido',
                    style: TextStyle(color: errorColor),
                  ),
                ),
              const SizedBox(height: spacingL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    bool hasError = false;

                    if (!_formKey.currentState!.validate()) return;

                    if (_fecha == null) {
                      setState(() => fechaObligatoria = true);
                      hasError = true;
                    }

                    final creador = auth.currentUser!.uid;
                    final elementos = <ElementoCata>[];

                    elementosValidos = false;

                    for (var v in _elementos) {
                      v.validate();
                      if (v.isValid()) elementosValidos = true;
                    }

                    if (!elementosValidos) hasError = true;

                    setState(() {});

                    if (hasError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Revisa los campos obligatorios'),
                        ),
                      );
                      return;
                    }

                    for (var entry in _elementos.asMap().entries) {
                      final index = entry.key;
                      final v = entry.value;

                      if (v.isValid()) {
                        elementos.add(
                          ElementoCata(
                            id: const Uuid().v4(),
                            nombreAuxiliar: 'Cata ${index + 1}',
                            nombre: v.nombre.text,
                            descripcion: v.descripcion.text,
                            precio: double.tryParse(v.precio.text) ?? 0,
                            imagenUrl: v.imagenUrl ?? '',
                          ),
                        );
                      }
                    }

                    final nuevaCata = Cata(
                      id: const Uuid().v4(),
                      nombre: nombreController.text.trim(),
                      fecha: _fecha!,
                      creadorId: creador,
                      elementos: elementos,
                    );

                    await firestore.addVotacion(nuevaCata);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cata creada correctamente'),
                      ),
                    );

                    Navigator.pop(context);
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: spacingM),
                    elevation: elevationM,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radiusM),
                    ),
                  ),
                  child: const Text('Crear cata', style: buttonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styledTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: bodyLargeStyle,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textSecondaryColor),
        hintStyle: TextStyle(color: textLightColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: errorColor),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
      ),
      validator: validator,
    );
  }
}

class _ElementoCataInput {
  final nombre = TextEditingController();
  final descripcion = TextEditingController();
  final precio = TextEditingController();
  String? imagenPath;
  String? imagenUrl;
  bool isUploading = false;

  bool showNombreError = false;
  bool showDescripcionError = false;
  bool showPrecioError = false;

  final ImagePicker _picker = ImagePicker();

  void validate() {
    showNombreError = nombre.text.trim().isEmpty;
    showDescripcionError = false;
    showPrecioError = double.tryParse(precio.text) == null;
  }

  bool isValid() => !showNombreError && !showPrecioError;

  Future<void> _selectAndUploadImage(
    BuildContext context,
    String elementoId,
    VoidCallback onUpdate,
  ) async {
    ImageSource? source;

    if (kIsWeb) {
      // En web solo permitimos seleccionar de galería
      source = ImageSource.gallery;
    } else {
      // En móvil mostramos opciones
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de agarre
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text('Seleccionar de galería'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

    if (source == null) return;

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      isUploading = true;
      onUpdate();

      try {
        // Verificar que el usuario esté autenticado
        final auth = Provider.of<AuthService>(context, listen: false);
        if (auth.currentUser == null) {
          throw Exception('Usuario no autenticado');
        }

        if (kIsWeb) {
          // Para web, usar putData en lugar de putFile
          final bytes = await pickedFile.readAsBytes();
          final ref = FirebaseStorage.instance.ref().child(
            'elementos/$elementoId.jpg',
          );

          // Agregar metadata para mejor compatibilidad
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': auth.currentUser!.uid,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          );

          final uploadTask = ref.putData(bytes, metadata);
          final snapshot = await uploadTask;
          final url = await snapshot.ref.getDownloadURL();

          imagenUrl = url;
        } else {
          // Para móvil, usar putFile
          final file = File(pickedFile.path);
          final ref = FirebaseStorage.instance.ref().child(
            'elementos/$elementoId.jpg',
          );

          // Agregar metadata para mejor compatibilidad
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': auth.currentUser!.uid,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          );

          final uploadTask = ref.putFile(file, metadata);
          final snapshot = await uploadTask;
          final url = await snapshot.ref.getDownloadURL();

          imagenPath = file.path;
          imagenUrl = url;
        }

        isUploading = false;
        onUpdate();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen subida correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        isUploading = false;
        onUpdate();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir imagen: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        print('Error detallado al subir imagen: $e');
      }
    }
  }

  Widget build(
    BuildContext context,
    int index, {
    VoidCallback? onRemove,
    VoidCallback? onUpdate,
  }) {
    final elementoId = const Uuid().v4();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: spacingS),
      decoration: cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(spacingM),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Elemento ${index + 1}', style: heading3Style),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: errorColor),
                    onPressed: onRemove,
                    tooltip: 'Eliminar elemento',
                  ),
              ],
            ),
            const SizedBox(height: spacingS),
            _styledField(
              controller: nombre,
              label: 'Nombre',
              errorText: showNombreError ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: spacingS),
            _styledField(controller: descripcion, label: 'Descripción'),
            const SizedBox(height: spacingS),
            _styledField(
              controller: precio,
              label: 'Precio (€)',
              keyboardType: TextInputType.number,
              errorText: showPrecioError ? 'Introduce un número válido' : null,
            ),
            const SizedBox(height: spacingS),
            // Botón dinámico: Subir imagen o Eliminar imagen
            ElevatedButton.icon(
              onPressed: () async {
                if (imagenUrl != null || imagenPath != null) {
                  // Si hay imagen, eliminar
                  imagenUrl = null;
                  imagenPath = null;
                  onUpdate?.call();
                } else {
                  // Si no hay imagen, subir
                  await _selectAndUploadImage(
                    context,
                    elementoId,
                    onUpdate ?? () {},
                  );
                  if (onUpdate != null) onUpdate();
                }
              },
              icon: Icon(
                imagenUrl != null || imagenPath != null
                    ? Icons.delete
                    : Icons.upload,
              ),
              label: Text(
                imagenUrl != null || imagenPath != null
                    ? 'Eliminar imagen'
                    : 'Subir imagen',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: imagenUrl != null || imagenPath != null
                    ? errorColor
                    : primaryColor,
                foregroundColor: Colors.white,
                elevation: elevationS,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusS),
                ),
              ),
            ),
            if (isUploading)
              const Padding(
                padding: EdgeInsets.only(top: spacingS),
                child: SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
              )
            else if (imagenUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: spacingS),
                child: Column(
                  children: [
                    // Preview de la imagen
                    GestureDetector(
                      onTap: () => _showImageModal(context, imagenUrl!),
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 80,
                          maxHeight: 120,
                        ),
                        child: Image.network(
                          imagenUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              constraints: const BoxConstraints(
                                minHeight: 80,
                                maxHeight: 120,
                              ),
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error cargando imagen: $error');
                            print('URL de imagen: $imagenUrl');
                            return Container(
                              constraints: const BoxConstraints(
                                minHeight: 80,
                                maxHeight: 120,
                              ),
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Error al cargar imagen',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Intentar recargar la imagen
                                      onUpdate?.call();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: textColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    child: const Text(
                                      'Reintentar',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (imagenPath != null)
              Padding(
                padding: const EdgeInsets.only(top: spacingS),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radiusS),
                  child: Image.file(
                    File(imagenPath!),
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: bodyLargeStyle,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        labelStyle: TextStyle(color: textSecondaryColor),
        hintStyle: TextStyle(color: textLightColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: errorColor),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
      ),
    );
  }

  void _showImageModal(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isWeb = screenSize.width > 768;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: isWeb
              ? const EdgeInsets.all(40) // Más espacio en web
              : const EdgeInsets.all(20), // Menos espacio en móvil
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Contenido principal
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vista previa de imagen',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textPrimaryColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            tooltip: 'Cerrar',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Imagen con zoom
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: isWeb
                              ? screenSize.height *
                                    0.7 // Más grande en web
                              : screenSize.height * 0.6, // Más pequeño en móvil
                          maxWidth: isWeb
                              ? screenSize.width *
                                    0.8 // Más ancho en web
                              : screenSize.width * 0.9, // Más estrecho en móvil
                        ),
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: isWeb ? 5.0 : 3.0, // Más zoom en web
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text('Error al cargar la imagen'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Instrucciones
                      Text(
                        isWeb
                            ? 'Usa la rueda del ratón o Ctrl + scroll para hacer zoom'
                            : 'Pellizca para hacer zoom',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
