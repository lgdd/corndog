import logging
import re

import litellm
from flask import Blueprint, jsonify, request

logger = logging.getLogger(__name__)

suggestions_bp = Blueprint("suggestions", __name__)

# Full menu catalog — the LLM must pick from these exact names.
MENU_ITEMS = [
    "Classic Corndog", "Spicy Jalapeño Dog", "Cheese-Stuffed Dog",
    "Vegan Dog", "BBQ Bacon Dog", "Corndog Poppers",
    "Crispy Fries", "Onion Rings", "Coleslaw", "Mac & Cheese",
    "Fresh Lemonade", "Iced Tea", "Soda",
    "Classic Combo", "Spicy Combo", "Vegan Combo",
]

FALLBACK = {
    "Classic Corndog": ["Fresh Lemonade", "Crispy Fries"],
    "Spicy Jalapeño Dog": ["Iced Tea", "Onion Rings"],
    "Cheese-Stuffed Dog": ["Soda", "Mac & Cheese"],
    "Vegan Dog": ["Fresh Lemonade", "Coleslaw"],
    "BBQ Bacon Dog": ["Iced Tea", "Crispy Fries"],
    "Corndog Poppers": ["Soda", "Onion Rings"],
}
DEFAULT_SUGGESTIONS = ["Fresh Lemonade", "Crispy Fries"]


@suggestions_bp.route("/api/suggestions", methods=["GET"])
def suggest_pairing():
    """AI-powered menu pairing suggestions using litellm."""
    item = request.args.get("item", "Classic Corndog")

    # Build the list of items to suggest from (exclude the item itself)
    candidates = [m for m in MENU_ITEMS if m != item]
    menu_list = ", ".join(candidates)

    try:
        response = litellm.completion(
            model="gpt-3.5-turbo",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a helpful corndog restaurant assistant. "
                        "You can ONLY suggest items from this menu: "
                        f"{menu_list}. "
                        "Always use the exact menu item names."
                    ),
                },
                {
                    "role": "user",
                    "content": (
                        f"I'm ordering '{item}'. Suggest 2 items from the menu "
                        f"that pair well with it. Reply with exactly 2 item names "
                        f"separated by a comma. No numbering, no explanation."
                    ),
                },
            ],
            timeout=5,
        )
        raw = response.choices[0].message.content
        # Strip numbering (e.g., "1. "), split on commas or newlines
        cleaned = re.sub(r'\d+\.\s*', '', raw)
        parsed = [s.strip().rstrip('.') for s in re.split(r'[,\n]+', cleaned) if s.strip()]
        # Only keep names that match actual menu items
        suggestions = [s for s in parsed if s in MENU_ITEMS and s != item]
        if not suggestions:
            suggestions = FALLBACK.get(item, DEFAULT_SUGGESTIONS)
            return jsonify({"item": item, "suggestions": suggestions, "model": "fallback"})
        logger.info("LLM suggestion for %s: %s", item, suggestions)
        return jsonify(
            {"item": item, "suggestions": suggestions, "model": "gpt-3.5-turbo"}
        )
    except Exception as exc:
        logger.info("LLM unavailable (%s), using fallback for %s", exc, item)
        return jsonify(
            {
                "item": item,
                "suggestions": FALLBACK.get(item, DEFAULT_SUGGESTIONS),
                "model": "fallback",
            }
        )


@suggestions_bp.route("/api/suggestions/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "corndog-suggestions"})
