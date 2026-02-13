/// States for Blood Bag Request
abstract class BloodBagState {}

class BloodBagInitial extends BloodBagState {}

class BloodBagLoading extends BloodBagState {}

class BloodBagLoaded extends BloodBagState {}

class BloodBagSubmitting extends BloodBagState {}

class BloodBagError extends BloodBagState {
  final String message;
  BloodBagError(this.message);
}
