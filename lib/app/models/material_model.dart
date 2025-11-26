// lib/app/models/material_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String numId;
  final int cantidad; // <-- ENTERO REAL
  final String descripcion;
  final String marca;
  final String modelo;
  final String ubicacion;
  final String carreraDepto;
  final String clasificacion;
  final String tipoBien;
  final String consecutivo;
  final DateTime fechaRegistro;
  final DateTime? fechaModificacion;
  final String? modificadoPor;

  MaterialModel({
    required this.numId,
    required this.cantidad,
    required this.descripcion,
    required this.marca,
    required this.modelo,
    required this.ubicacion,
    required this.carreraDepto,
    required this.clasificacion,
    required this.tipoBien,
    required this.consecutivo,
    required this.fechaRegistro,
    this.fechaModificacion,
    this.modificadoPor,
  });

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'numId': numId,
      'cantidad': cantidad, // <-- entero
      'descripcion': descripcion,
      'marca': marca,
      'modelo': modelo,
      'ubicacion': ubicacion,
      'carreraDepto': carreraDepto,
      'clasificacion': clasificacion,
      'tipoBien': tipoBien,
      'consecutivo': consecutivo,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'fechaModificacion': fechaModificacion != null
          ? Timestamp.fromDate(fechaModificacion!)
          : null,
      'modificadoPor': modificadoPor,
    };
  }

  // Crear desde Map de Firebase
  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      numId: map['numId']?.toString() ?? '',
      cantidad: _parseCantidad(map['cantidad']),
      descripcion: map['descripcion']?.toString() ?? '',
      marca: map['marca']?.toString() ?? '',
      modelo: map['modelo']?.toString() ?? '',
      ubicacion: map['ubicacion']?.toString() ?? '',
      carreraDepto: map['carreraDepto']?.toString() ?? '',
      clasificacion: map['clasificacion']?.toString() ?? '',
      tipoBien: map['tipoBien']?.toString() ?? '',
      consecutivo: map['consecutivo']?.toString() ?? '',
      fechaRegistro: (map['fechaRegistro'] as Timestamp).toDate(),
      fechaModificacion: map['fechaModificacion'] != null
          ? (map['fechaModificacion'] as Timestamp).toDate()
          : null,
      modificadoPor: map['modificadoPor']?.toString(),
    );
  }

  // Función segura para convertir cantidad
  static int _parseCantidad(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Crear copia con modificaciones
  MaterialModel copyWith({
    String? numId,
    int? cantidad,
    String? descripcion,
    String? marca,
    String? modelo,
    String? ubicacion,
    String? carreraDepto,
    String? clasificacion,
    String? tipoBien,
    String? consecutivo,
    DateTime? fechaRegistro,
    DateTime? fechaModificacion,
    String? modificadoPor,
  }) {
    return MaterialModel(
      numId: numId ?? this.numId,
      cantidad: cantidad ?? this.cantidad,
      descripcion: descripcion ?? this.descripcion,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      ubicacion: ubicacion ?? this.ubicacion,
      carreraDepto: carreraDepto ?? this.carreraDepto,
      clasificacion: clasificacion ?? this.clasificacion,
      tipoBien: tipoBien ?? this.tipoBien,
      consecutivo: consecutivo ?? this.consecutivo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      modificadoPor: modificadoPor ?? this.modificadoPor,
    );
  }
}
