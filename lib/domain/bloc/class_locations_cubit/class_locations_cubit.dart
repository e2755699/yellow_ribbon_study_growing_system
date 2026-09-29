import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../enum/class_location.dart';
import '../../repo/contracts/class_location_repository.dart';

class ClassLocationsCubit extends Cubit<ClassLocationsState> {
  ClassLocationsCubit(this._repository) : super(const ClassLocationsState());
  final ClassLocationRepository _repository;
  StreamSubscription<List<ClassLocation>>? _subscription;

  void watch() {
    _subscription?.cancel();
    emit(const ClassLocationsState());
    _subscription = _repository
        .watch()
        .listen((locations) => emit(ClassLocationsState(locations: locations)),
            onError: (Object error) {
      print('Error watching class locations: $error');
      emit(ClassLocationsState(
          errorMessage:
              error is FirebaseException && error.code == 'permission-denied'
                  ? '無法讀取據點資料，請確認帳號的存取權限。'
                  : '據點資料載入失敗，請檢查網路連線後重試。'));
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class ClassLocationsState {
  const ClassLocationsState({this.locations, this.errorMessage});

  /// Null while loading.
  final List<ClassLocation>? locations;
  final String? errorMessage;
}
