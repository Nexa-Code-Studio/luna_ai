import asyncio
from packages.ai import LLMFactory, TTSFactory, LLMMessage
from packages.ai.providers.llm import MockLLMProvider, OpenAILLMProvider, GeminiLLMProvider
from packages.ai.providers.tts import MockTTSProvider, OpenAITTSProvider, ElevenLabsTTSProvider


async def test_factories():
    print("=== Testing LLM Factory ===")
    mock_llm = LLMFactory.get_provider("mock")
    assert isinstance(mock_llm, MockLLMProvider)
    print("✅ Successfully instantiated MockLLMProvider")

    messages = [LLMMessage(role="user", content="Saya merasa cemas hari ini.")]
    response = await mock_llm.generate_response(messages)
    print(f"Mock Response: {response}")
    assert len(response) > 0

    openai_llm = LLMFactory.get_provider("openai")
    assert isinstance(openai_llm, OpenAILLMProvider)
    print("✅ Successfully instantiated OpenAILLMProvider")

    gemini_llm = LLMFactory.get_provider("gemini")
    assert isinstance(gemini_llm, GeminiLLMProvider)
    print("✅ Successfully instantiated GeminiLLMProvider")

    print("\n=== Testing TTS Factory ===")
    mock_tts = TTSFactory.get_provider("mock")
    assert isinstance(mock_tts, MockTTSProvider)
    print("✅ Successfully instantiated MockTTSProvider")

    audio = await mock_tts.synthesize("Halo, ini tes suara LUNA.")
    assert len(audio) > 0
    print(f"Generated WAV header + audio bytes size: {len(audio)} bytes")

    openai_tts = TTSFactory.get_provider("openai")
    assert isinstance(openai_tts, OpenAITTSProvider)
    print("✅ Successfully instantiated OpenAITTSProvider")

    eleven_tts = TTSFactory.get_provider("elevenlabs")
    assert isinstance(eleven_tts, ElevenLabsTTSProvider)
    print("✅ Successfully instantiated ElevenLabsTTSProvider")

    print("\n🎉 ALL AI PROVIDER FACTORY TESTS PASSED SUCCESSFULLY!")


if __name__ == "__main__":
    asyncio.run(test_factories())
