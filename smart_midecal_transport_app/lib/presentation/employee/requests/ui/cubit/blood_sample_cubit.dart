import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/samples_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/repository/requests_repository.dart';
import 'blood_sample_state.dart';

/// Cubit for Blood Sample Requests
@injectable
class BloodSampleCubit extends Cubit<BloodSampleState> {
  final RequestsRepository requestsRepository;

  BloodSampleCubit({required this.requestsRepository})
    : super(BloodSampleInitial());

  final TextEditingController searchController = TextEditingController();

  SampleEntity? selectedSample;
  String? selectedRoom;
  List<SampleEntity> searchResults = [];

  final List<String> rooms = ['Room A', 'Room B', 'Room C'];

  /// Search samples by ID or exact code
  void searchSamples(String query) async {
    if (query.isEmpty) {
      searchResults = [];
      _emitLoaded();
      return;
    }

    emit(BloodSampleSearchLoading());

    final result = await requestsRepository.getSampleById(query);

    result.fold(
      (failure) {
        searchResults = [];
        emit(BloodSampleError(failure.errorMessage));
        _emitLoaded();
      },
      (response) {
        searchResults = response.data!;
        _emitLoaded();
      },
    );
  }

  /// Select a sample from the dropdown
  void selectSample(SampleEntity sample) {
    selectedSample = sample;
    searchResults = []; // Clear search results after selection
    searchController.text = sample.patientName!; // Update text field
    _emitLoaded();
  }

  /// Select a room
  void selectRoom(String room) {
    selectedRoom = room;
    _emitLoaded();
  }

  /// Load initial data
  Future<void> loadData() async {
    emit(BloodSampleLoading());
    // In a real app, this might fetch some initial state or just emit loaded
    await Future.delayed(const Duration(milliseconds: 100));
    _emitLoaded();
  }

  /// Submit a blood sample request
  Future<void> submitRequest() async {
    print(
      "Submitting request for sample: ${selectedSample?.id}, room: $selectedRoom",
    );
    if (selectedSample == null) {
      emit(BloodSampleError('Please search and select a patient sample'));
      _emitLoaded();
      return;
    }

    if (selectedRoom == null) {
      emit(BloodSampleError('Please select a room'));
      _emitLoaded();
      return;
    }

    emit(BloodSampleSubmitting());

    final result = await requestsRepository.requestSample(
      selectedSample!.sampleCode!,
      selectedRoom!,
    );

    result.fold(
      (failure) {
        emit(BloodSampleError(failure.errorMessage));
        _emitLoaded();
      },
      (success) {
        // Clear form after submission
        searchController.clear();
        selectedSample = null;
        selectedRoom = null;
        searchResults = [];

        emit(BloodSampleSuccess());
        _emitLoaded();
      },
    );
  }

  void _emitLoaded() {
    emit(
      BloodSampleLoaded(
        searchResults: searchResults,
        selectedSample: selectedSample,
        selectedRoom: selectedRoom,
      ),
    );
  }

  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}
