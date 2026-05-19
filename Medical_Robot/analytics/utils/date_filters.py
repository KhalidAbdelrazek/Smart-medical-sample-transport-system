"""
analytics/utils/date_filters.py

Utility functions to compute date ranges for analytics period filters.
Supported periods: 'week', 'month' (default), 'year', 'all_time'
"""
from datetime import date, timedelta


def get_date_range(period: str = 'month'):
    """
    Return (start_date, end_date) for the requested period.

    Args:
        period: One of 'week', 'month', 'year', 'all_time'

    Returns:
        Tuple[date | None, date | None]
        Both None means no date filtering (all_time).
    """
    today = date.today()

    if period == 'week':
        start = today - timedelta(days=6)  # last 7 days inclusive
        end = today
        return start, end

    elif period == 'month':
        start = today.replace(day=1)
        end = today
        return start, end

    elif period == 'year':
        start = today.replace(month=1, day=1)
        end = today
        return start, end

    elif period == 'all_time':
        return None, None

    else:
        # Default to current month for unknown periods
        start = today.replace(day=1)
        end = today
        return start, end


def period_label(period: str) -> str:
    """
    Return a human-readable label for the requested period.
    """
    today = date.today()
    labels = {
        'week': f'Last 7 days (ending {today.isoformat()})',
        'month': f'{today.strftime("%B %Y")}',
        'year': f'{today.year}',
        'all_time': 'All Time',
    }
    return labels.get(period, f'{today.strftime("%B %Y")}')
