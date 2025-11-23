// lib/app/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/material_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'materiales';

  // Generar el siguiente número ID automáticamente
  Future<String> _generateNextNumId() async {
    try {
      final querySnapshot = await _db
          .collection(_collectionName)
          .orderBy('numId', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return '001'; // Primer registro
      }

      final lastNumId = querySnapshot.docs.first.data()['numId'] as String;
      final lastNumber = int.tryParse(lastNumId) ?? 0;
      final nextNumber = lastNumber + 1;

      return nextNumber.toString().padLeft(3, '0'); // Formato: 001, 002, etc.
    } catch (e) {
      throw Exception('Error al generar ID: $e');
    }
  }

  // Crear un nuevo material
  Future<String> createMaterial(MaterialModel material) async {
    try {
      // Generar nuevo numId si no viene especificado
      String numId = material.numId;
      if (numId.isEmpty) {
        numId = await _generateNextNumId();
      }

      final materialWithId = material.copyWith(
        numId: numId,
        fechaRegistro: DateTime.now(),
      );

      // Usar numId como ID del documento
      await _db
          .collection(_collectionName)
          .doc(numId)
          .set(materialWithId.toMap());

      return numId;
    } catch (e) {
      throw Exception('Error al crear material: $e');
    }
  }

  // Actualizar un material existente
  Future<void> updateMaterial(
      String numId,
      MaterialModel material,
      String modificadoPor,
      ) async {
    try {
      final updatedMaterial = material.copyWith(
        fechaModificacion: DateTime.now(),
        modificadoPor: modificadoPor,
      );

      await _db
          .collection(_collectionName)
          .doc(numId)
          .update(updatedMaterial.toMap());
    } catch (e) {
      throw Exception('Error al actualizar material: $e');
    }
  }

  // Obtener un material por ID
  Future<MaterialModel?> getMaterial(String numId) async {
    try {
      final doc = await _db.collection(_collectionName).doc(numId).get();

      if (!doc.exists) return null;

      return MaterialModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Error al obtener material: $e');
    }
  }

  // Obtener todos los materiales
  Stream<List<MaterialModel>> getAllMaterials() {
    return _db
        .collection(_collectionName)
        .orderBy('numId', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MaterialModel.fromMap(doc.data()))
        .toList());
  }

  // Eliminar un material
  Future<void> deleteMaterial(String numId) async {
    try {
      await _db.collection(_collectionName).doc(numId).delete();
    } catch (e) {
      throw Exception('Error al eliminar material: $e');
    }
  }

  // Verificar si existe un numId
  Future<bool> existsNumId(String numId) async {
    try {
      final doc = await _db.collection(_collectionName).doc(numId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}