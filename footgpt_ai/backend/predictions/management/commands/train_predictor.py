from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from predictions.engine.history import load_history_from_db
from predictions.engine.train import train_and_evaluate
from predictions.models import ModelEvaluation


class Command(BaseCommand):
    help = "Train 1X2 models with a chronological split and store evaluation metrics."

    def handle(self, *args, **options):
        history = load_history_from_db()
        if not history:
            raise CommandError("No historical matches in the database. Ingest finished fixtures first.")
        try:
            bundle = train_and_evaluate(history, artifact_path=settings.PREDICTION_MODEL_PATH)
        except ValueError as exc:
            raise CommandError(str(exc)) from exc
        ModelEvaluation.objects.create(
            model_name=bundle["model_name"],
            n_train=bundle["n_train"],
            n_test=bundle["n_test"],
            log_loss=bundle["metrics"]["log_loss"],
            brier_score=bundle["metrics"]["brier_score"],
            accuracy=bundle["metrics"]["accuracy"],
            ece=bundle["metrics"].get("ece"),
            comparison=bundle["comparison"],
            artifact_path=bundle.get("artifact_path", ""),
        )
        self.stdout.write(
            self.style.SUCCESS(
                f"Selected {bundle['model_name']} "
                f"log_loss={bundle['metrics']['log_loss']:.4f} "
                f"brier={bundle['metrics']['brier_score']:.4f} "
                f"(train {bundle['n_train']}, test {bundle['n_test']})."
            )
        )
        for name, metrics in bundle["comparison"].items():
            self.stdout.write(
                f"  {name}: log_loss={metrics['log_loss']:.4f} "
                f"brier={metrics['brier_score']:.4f} acc={metrics['accuracy']:.3f} "
                f"ece={metrics['ece']:.4f}"
            )
