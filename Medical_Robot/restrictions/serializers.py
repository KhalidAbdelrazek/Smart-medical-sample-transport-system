"""
restrictions/serializers.py

Request serializers for the three restriction APIs.
Response data is a plain dict returned by the service layer — no
response serializer is needed for these simple endpoints.
"""
from rest_framework import serializers


class RestrictDoctorSamplesSerializer(serializers.Serializer):
    """
    Validates the body of POST /api/restrictions/restrict-doctor-samples/

    Fields:
        restriction_type : 'NONE' | 'GLOBAL' | 'PARTIAL'
        doctor_ids       : list of doctor UUIDs — required when PARTIAL
        reason           : optional admin note
    """

    RESTRICTION_TYPE_CHOICES = [
        ('NONE',    'None'),
        ('GLOBAL',  'Global'),
        ('PARTIAL', 'Partial'),
    ]

    restriction_type = serializers.ChoiceField(choices=RESTRICTION_TYPE_CHOICES)

    doctor_ids = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        default=list,
        help_text="Required when restriction_type is PARTIAL.",
    )

    reason = serializers.CharField(
        required=False,
        allow_blank=True,
        default='',
        help_text="Optional admin note visible in restriction status responses.",
    )

    def validate(self, data):
        if data['restriction_type'] == 'PARTIAL' and not data.get('doctor_ids'):
            raise serializers.ValidationError(
                {"doctor_ids": "doctor_ids is required when restriction_type is PARTIAL."}
            )
        return data


class RestrictStorageSamplesSerializer(serializers.Serializer):
    """
    Validates the body of POST /api/restrictions/restrict-storage-samples/

    Fields:
        restriction_type : 'NONE' | 'GLOBAL' | 'PARTIAL'
        employee_ids     : list of storage-employee UUIDs — required when PARTIAL
        reason           : optional admin note
    """

    RESTRICTION_TYPE_CHOICES = [
        ('NONE',    'None'),
        ('GLOBAL',  'Global'),
        ('PARTIAL', 'Partial'),
    ]

    restriction_type = serializers.ChoiceField(choices=RESTRICTION_TYPE_CHOICES)

    employee_ids = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        default=list,
        help_text="Required when restriction_type is PARTIAL.",
    )

    reason = serializers.CharField(
        required=False,
        allow_blank=True,
        default='',
        help_text="Optional admin note visible in restriction status responses.",
    )

    def validate(self, data):
        if data['restriction_type'] == 'PARTIAL' and not data.get('employee_ids'):
            raise serializers.ValidationError(
                {"employee_ids": "employee_ids is required when restriction_type is PARTIAL."}
            )
        return data


class RestrictTransportCarSerializer(serializers.Serializer):
    """
    Validates the body of POST /api/restrictions/restrict-transport-car/

    Fields:
        status : True  → enable restriction (cars cannot be dispatched)
                 False → disable restriction (dispatch allowed again)
        reason : optional admin note
    """

    status = serializers.BooleanField(
        help_text="true = enable dispatch restriction, false = lift it.",
    )

    reason = serializers.CharField(
        required=False,
        allow_blank=True,
        default='',
        help_text="Optional admin note visible in restriction status responses.",
    )
