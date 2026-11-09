from rest_framework.permissions import BasePermission


class IsOwner(BasePermission):
    def has_object_permission(self, request, view, obj) -> bool:
        owner = getattr(obj, "user", obj)
        return bool(request.user and request.user.is_authenticated and owner == request.user)
