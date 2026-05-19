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
        restriction_type : ALL_UNRESTRICT | GLOBAL_RESTRICT | PARTIAL_RESTRICT | PARTIAL_UNRESTRICT
        user_ids         : list of doctor UUIDs
        reason           : optional admin note
    """

    RESTRICTION_TYPE_CHOICES = [
        ('ALL_UNRESTRICT',    'None'),
        ('GLOBAL_RESTRICT',  'Global'),
        ('PARTIAL_RESTRICT', 'Partial'),
        ('PARTIAL_UNRESTRICT', 'Partial Unrestrict'),
    ]

    restriction_type = serializers.ChoiceField(choices=RESTRICTION_TYPE_CHOICES)

    user_ids = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        default=list,
        help_text="Required when restriction_type is PARTIAL_RESTRICT or PARTIAL_UNRESTRICT.",
    )

    reason = serializers.CharField(
        required=False,
        allow_blank=True,
        default='',
        help_text="Optional admin note visible in restriction status responses.",
    )

    def validate(self, data):
        rtype = data['restriction_type']
        uids = data.get('user_ids', [])
        
        if rtype in ['PARTIAL_RESTRICT', 'PARTIAL_UNRESTRICT'] and not uids:
            field_name = 'user_ids'
            raise serializers.ValidationError(
                {field_name: f"{field_name} is required when restriction_type is {rtype}."}
            )
            
        return data


class RestrictStorageSamplesSerializer(serializers.Serializer):
    """
    Validates the body of POST /api/restrictions/restrict-storage-samples/

    Fields:
        restriction_type : ALL_UNRESTRICT | GLOBAL_RESTRICT | PARTIAL_RESTRICT | PARTIAL_UNRESTRICT
        user_ids         : list of storage-employee UUIDs
        reason           : optional admin note
    """

    RESTRICTION_TYPE_CHOICES = [
        ('ALL_UNRESTRICT',    'None'),
        ('GLOBAL_RESTRICT',  'Global'),
        ('PARTIAL_RESTRICT', 'Partial'),
        ('PARTIAL_UNRESTRICT', 'Partial Unrestrict'),
    ]

    restriction_type = serializers.ChoiceField(choices=RESTRICTION_TYPE_CHOICES)

    user_ids = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        default=list,
        help_text="Required when restriction_type is PARTIAL_RESTRICT or PARTIAL_UNRESTRICT.",
    )

    reason = serializers.CharField(
        required=False,
        allow_blank=True,
        default='',
        help_text="Optional admin note visible in restriction status responses.",
    )

    def validate(self, data):
        rtype = data['restriction_type']
        uids = data.get('user_ids', [])
        
        if rtype in ['PARTIAL_RESTRICT', 'PARTIAL_UNRESTRICT'] and not uids:
            field_name = 'user_ids'
            raise serializers.ValidationError(
                {field_name: f"{field_name} is required when restriction_type is {rtype}."}
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
