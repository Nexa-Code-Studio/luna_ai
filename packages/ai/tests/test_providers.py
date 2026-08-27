import pytest
from packages.ai.factories.llm_factory import LLMFactory
from packages.ai.factories.tts_factory import TTSFactory
from packages.ai.interfaces.llm import LLMMessage
from packages.ai.providers.llm.ollama_llm import OllamaLLMProvider
from packages.ai.providers.tts.edge_tts_provider import EdgeTTSProvider


def test_llm_factory_ollama():
    provider = LLMFactory.get_provider("ollama")
    assert isinstance(provider, OllamaLLMProvider)
    assert provider.model == "qwen3:1.7B"
    assert "100.82.167.100" in provider.base_url


def test_tts_factory_edge():
    provider = TTSFactory.get_provider("edge_tts")
    assert isinstance(provider, EdgeTTSProvider)
    assert provider.default_voice == "id-ID-GadisNeural"



@pytest.mark.asyncio
async def test_ollama_provider_format():
    provider = OllamaLLMProvider(base_url="http://100.82.167.100:11434", model="qwen3:1.7B")
    formatted = provider._format_messages([
        LLMMessage(role="user", content="Halo Luna")
    ])
    assert formatted == [{"role": "user", "content": "Halo Luna"}]
