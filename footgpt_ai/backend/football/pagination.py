from rest_framework.response import Response


def paginate_results(items: list, page: int, page_size: int) -> dict:
    total = len(items)
    start = (page - 1) * page_size
    end = start + page_size
    return {
        "count": total,
        "page": page,
        "page_size": page_size,
        "num_pages": max(1, (total + page_size - 1) // page_size) if page_size else 1,
        "results": items[start:end],
    }


def football_response(
    payload: dict,
    *,
    page: int = 1,
    page_size: int = 20,
    paginate: bool = True,
) -> Response:
    results = payload.get("results")
    extra = {
        "provider_paging": payload.get("paging"),
        "provider_errors": payload.get("errors") or {},
    }
    if paginate and isinstance(results, list):
        body = paginate_results(results, page, page_size)
        body.update(extra)
        return Response(body)
    return Response({"results": results, **extra})
