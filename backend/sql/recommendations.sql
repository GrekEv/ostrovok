WITH user_favorite_tags AS (
    SELECT jsonb_array_elements_text(tc.amenities) AS tag,
           COUNT(*) AS tag_weight
    FROM user_swipes us
    JOIN travel_cards tc ON us.card_id = tc.id
    WHERE us.user_id = 'test_user_ios_123' AND us.action = 'like'
    GROUP BY tag
)
SELECT tc.id, tc.name, tc.city, tc.price, tc.ai_summary,
       COALESCE(SUM(uft.tag_weight), 0) AS relevance_score
FROM travel_cards tc
LEFT JOIN user_favorite_tags uft ON uft.tag ?| ARRAY[tc.amenities->>0, tc.amenities->>1, tc.amenities->>2]
WHERE tc.id NOT IN (
    SELECT card_id FROM user_swipes WHERE user_id = 'test_user_ios_123'
)
GROUP BY tc.id, tc.name, tc.city, tc.price, tc.ai_summary
ORDER BY relevance_score DESC, tc.rating DESC
LIMIT 10;
