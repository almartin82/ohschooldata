"""
Tests for pyohschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pyohschooldata
    assert pyohschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pyohschooldata
    assert hasattr(pyohschooldata, 'fetch_enr')
    assert callable(pyohschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pyohschooldata
    assert hasattr(pyohschooldata, 'get_available_years')
    assert callable(pyohschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pyohschooldata
    assert hasattr(pyohschooldata, '__version__')
    assert isinstance(pyohschooldata.__version__, str)
