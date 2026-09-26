from app.agents.travelmate.schemas import (
    ChatOutput,
    MemoryExtractionOutput,
    ModelTaskOutput,
    PhotoCopywritingOutput,
    TripPlanningOutput,
    TripReviewOutput,
    parse_model_output,
)


def test_parse_model_output_accepts_chat_contract():
    result = parse_model_output(
        """
        {
          "chat": {
            "replyText": "I can plan a slow night-view trip.",
            "voiceText": "I can plan a slow night-view trip.",
            "avatarState": "planning",
            "emotion": "curious",
            "cards": [{"type": "tripPlan"}],
            "memoryCandidates": [{"title": "No cilantro"}],
            "toolTrace": [{"tool": "model_provider"}],
            "nextActions": [{"type": "confirmMemory"}],
            "syncSuggestions": [{"type": "memory"}],
            "errors": []
          }
        }
        """
    )

    assert isinstance(result, ModelTaskOutput)
    assert isinstance(result.chat, ChatOutput)
    assert result.chat.replyText.startswith("I can plan")
    assert result.chat.avatarState == "planning"
    assert result.fallback is False


def test_parse_model_output_accepts_photo_copywriting_contract():
    result = parse_model_output(
        """
        {
          "photoCopywriting": {
            "photoIds": ["photo-a"],
            "persona": "guide",
            "style": "warm",
            "moments": "Moments copy",
            "xiaohongshu": "XHS copy",
            "diary": "Diary copy",
            "vlogNarration": "Vlog narration",
            "reviewSuggestion": "Use it in the review"
          }
        }
        """
    )

    assert isinstance(result.photoCopywriting, PhotoCopywritingOutput)
    assert result.photoCopywriting.photoIds == ["photo-a"]
    assert result.photoCopywriting.vlogNarration == "Vlog narration"
    assert result.fallback is False


def test_parse_model_output_accepts_trip_review_contract():
    result = parse_model_output(
        """
        {
          "tripReview": {
            "route": "Start -> Viewpoint -> Hotel",
            "highlightPhotos": ["viewpoint"],
            "completedTasks": [{"id": "task-a", "title": "Take a photo"}],
            "reminderHighlights": [{"triggerType": "weather"}],
            "avatarStatusChanges": ["rapport +1"],
            "newMemories": ["prefers night views"],
            "nextTripSuggestions": ["Try a river walk next time"],
            "temporaryMemoryPromotions": [
              {"id": "mem-a", "suggestedScope": "longTerm", "reason": "Repeated"}
            ],
            "profileContext": {"pace": "slow"}
          }
        }
        """
    )

    assert isinstance(result.tripReview, TripReviewOutput)
    assert result.tripReview.route == "Start -> Viewpoint -> Hotel"
    assert result.tripReview.temporaryMemoryPromotions[0]["suggestedScope"] == "longTerm"
    assert result.fallback is False


def test_parse_model_output_normalizes_string_trip_plan_alternatives():
    result = parse_model_output(
        """
        {
          "tripPlanning": {
            "title": "Hangzhou relaxed weekend",
            "destination": "Hangzhou",
            "summary": "Keep the route light and reserve night-view time.",
            "profileMatches": ["slow pace", "night views"],
            "risks": ["weekend crowds"],
            "alternatives": [
              "If West Lake is crowded, switch to a canal night walk.",
              "If walking feels tiring, take a short boat segment."
            ]
          }
        }
        """
    )

    assert result.fallback is False
    assert isinstance(result.tripPlanning, TripPlanningOutput)
    assert result.tripPlanning.alternatives == [
        {
            "id": "alt-1",
            "title": "备选方案 1",
            "summary": "If West Lake is crowded, switch to a canal night walk.",
            "bestFor": "适合在原计划拥挤、天气变化或体力不足时切换。",
        },
        {
            "id": "alt-2",
            "title": "备选方案 2",
            "summary": "If walking feels tiring, take a short boat segment.",
            "bestFor": "适合在原计划拥挤、天气变化或体力不足时切换。",
        },
    ]


def test_parse_model_output_normalizes_memory_scope_aliases():
    result = parse_model_output(
        """
        {
          "memoryExtraction": {
            "candidates": [
              {
                "title": "No cilantro",
                "content": "The user avoids cilantro during this trip.",
                "category": "dietary_preference",
                "recommendedScope": "shortTerm",
                "confidence": 0.82,
                "reason": "The user said no cilantro."
              }
            ]
          }
        }
        """
    )

    assert result.fallback is False
    assert isinstance(result.memoryExtraction, MemoryExtractionOutput)
    assert result.memoryExtraction.candidates[0].recommendedScope == "currentTrip"


def test_parse_model_output_marks_invalid_structured_payload_as_fallback():
    result = parse_model_output('{"photoCopywriting": {"photoIds": ["photo-a"], "moments": "missing fields"}}')

    assert result.fallback is True
    assert "validation" in (result.fallbackReason or "").lower()
    assert result.raw["photoCopywriting"]["photoIds"] == ["photo-a"]
