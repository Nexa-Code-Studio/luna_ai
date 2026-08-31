import logging
from typing import Any, List

from ai.interfaces.embedding import BaseEmbeddingProvider

logger = logging.getLogger(__name__)


class DefaultEmbeddingProvider(BaseEmbeddingProvider):
    """
    Real 384-dimensional dense vector embedding provider using
    'sentence-transformers/all-MiniLM-L6-v2' via FastEmbed (ONNX).
    """

    def __init__(self, model_name: str = "sentence-transformers/all-MiniLM-L6-v2"):
        self.model_name = model_name
        self.vector_size = 384
        self._model: Any | None = None

    def _load_model(self) -> None:
        if self._model is None:
            try:
                from fastembed import TextEmbedding
            except ImportError as e:
                logger.error("fastembed library is missing. Install fastembed package.")
                raise ImportError("fastembed library is required for DefaultEmbeddingProvider.") from e

            logger.info(f"Loading FastEmbed model '{self.model_name}'...")
            self._model = TextEmbedding(model_name=self.model_name)
            logger.info(f"FastEmbed model '{self.model_name}' loaded successfully.")

    async def embed_query(self, text: str) -> List[float]:
        """
        Generates a real 384-dimensional float vector for a search query.
        """
        self._load_model()
        generators = self._model.embed([text])
        vector = list(next(generators))
        return [float(x) for x in vector]

    async def embed_documents(self, texts: List[str]) -> List[List[float]]:
        """
        Generates a batch of real 384-dimensional float vectors for document texts.
        """
        self._load_model()
        generators = self._model.embed(texts)
        return [[float(x) for x in vec] for vec in generators]
