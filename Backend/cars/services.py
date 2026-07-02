"""
cars/services.py

Service layer for car management and capacity tracking.
"""
from rest_framework.exceptions import NotFound

from cars.models import Car
from transport.models import TransportRequest


def get_car_details(car_id):
    """
    Get car details including occupancy and sample codes.
    
    Returns a dict with:
    - car_id: int
    - car_number: str
    - status: str
    - capacity: int (total slots available)
    - used_capacity: int (slots currently occupied)
    - remaining_capacity: int (free slots)
    - sample_codes: list of str (codes of samples in car slots)
    
    Occupancy includes:
    - All delivery requests (DELIVERY) in LOADED, LOADED_FOR_RETURN, DISPATCHED, or ARRIVED_AT_DOCTOR_DELIVERY
    - All return requests (RETURN) in LOADED_FOR_RETURN or DISPATCHED statuses
    
    Args:
        car_id: int
    
    Returns:
        dict with car details and occupancy
        
    Raises:
        NotFound: if car does not exist
    """
    try:
        car = Car.objects.get(id=car_id)
    except Car.DoesNotExist:
        raise NotFound(f"Car not found with ID: {car_id}")
    
    # Statuses that occupy a slot for delivery requests
    delivery_occupancy_statuses = [
        'LOADED',
        'LOADED_FOR_RETURN',
        'DISPATCHED',
        'ARRIVED_AT_DOCTOR_DELIVERY',
    ]
    
    # Statuses that occupy a slot for return requests
    return_occupancy_statuses = [
        'LOADED_FOR_RETURN',
        'DISPATCHED',
    ]
    
    # Get delivery requests occupying slots
    delivery_requests = list(
        TransportRequest.objects.filter(
            assigned_car=car,
            request_type='DELIVERY',
            status__in=delivery_occupancy_statuses,
        )
        .select_related('sample')
        .values_list('sample__sample_code', flat=True)
    )
    
    # Get return requests occupying slots
    return_requests = list(
        TransportRequest.objects.filter(
            assigned_car=car,
            request_type='RETURN',
            status__in=return_occupancy_statuses,
        )
        .select_related('sample')
        .values_list('sample__sample_code', flat=True)
    )
    
    # Combine sample codes
    all_sample_codes = delivery_requests + return_requests
    
    # Calculate occupancy
    used_capacity = len(all_sample_codes)
    remaining_capacity = max(car.capacity - used_capacity, 0)
    
    return {
        'car_id': car.id,
        'car_number': car.car_number,
        'status': car.status,
        'capacity': car.capacity,
        'used_capacity': used_capacity,
        'remaining_capacity': remaining_capacity,
        'sample_codes': all_sample_codes,
    }
