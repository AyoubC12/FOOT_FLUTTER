"""Favorite persistence stays on accounts.Favorite.

A dedicated table would require a data migration of existing rows. Keep a
single source of truth until that cut-over is scheduled.
"""
