import base64
import json
from dataclasses import dataclass

import anthropic

from creds import ANTHROPIC_API_KEY


MODEL = "claude-sonnet-4-5-20250929"

SYSTEM_PROMPT = """You are a food nutrition analyst. Analyze the provided image and estimate its nutritional content. Of the nutritional content the most important one to get right is carbohydrates.

You must respond with ONLY a valid JSON object (no markdown, no code fences, no explanation, no other text).

The JSON must have exactly these fields:
- is_food: boolean, true if the image contains identifiable food, false otherwise
- calories: integer, estimated total calories (0 if is_food is false)
- carbohydrates_grams: integer, estimated carbohydrates in grams (0 if is_food is false)
- protein_grams: integer, estimated protein in grams (0 if is_food is false)
- description: string, brief description of the food (e.g., "burger and fries"), or reason why analysis failed
- confidence: string, exactly one of "high", "medium", or "low"

Set is_food to false if:
- The image does not contain food
- The image is too blurry to analyze
- The food is too obscured to estimate nutritional content

Example response (respond with just the JSON, nothing else):
{"is_food": true, "calories": 650, "carbohydrates_grams": 45, "protein_grams": 35, "description": "burger and fries", "confidence": "high"}"""


@dataclass
class FoodAnalysisResult:
    is_food: bool
    calories: int
    carbohydrates_grams: int
    protein_grams: int
    description: str
    confidence: str


class AnthropicError(Exception):
    """Raised when the Anthropic API returns an error."""
    pass


def analyze_food_image(image_data: bytes) -> FoodAnalysisResult:
    """
    Analyze a food image using Claude.

    Args:
        image_data: JPEG image bytes

    Returns:
        FoodAnalysisResult with nutritional estimates

    Raises:
        AnthropicError: If the Anthropic API returns an error
    """
    client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)

    base64_image = base64.standard_b64encode(image_data).decode("utf-8")

    try:
        response = client.messages.create(
            model=MODEL,
            max_tokens=6000,
            system=SYSTEM_PROMPT,
            thinking={"type": "enabled", "budget_tokens": 4096},
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64_image,
                            },
                        },
                        {
                            "type": "text",
                            "text": "Analyze this food image."
                        }
                    ],
                }
            ],
        )
    except anthropic.APIError as e:
        raise AnthropicError(str(e))

    # Parse JSON from response
    # FIXME: we should have more robust handling here and check if this is correct
    response_text = response.content[-1].text.strip()

    # Handle potential markdown code fences
    if response_text.startswith("```"):
        lines = response_text.split("\n")
        response_text = "\n".join(lines[1:-1])

    try:
        result = json.loads(response_text)
    except json.JSONDecodeError as e:
        raise AnthropicError(f"Failed to parse response as JSON: {e}")

    return FoodAnalysisResult(
        is_food=result["is_food"],
        calories=result["calories"],
        carbohydrates_grams=result["carbohydrates_grams"],
        protein_grams=result["protein_grams"],
        description=result["description"],
        confidence=result["confidence"],
    )
