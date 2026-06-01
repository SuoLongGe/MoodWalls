package com.moodwalls.service;

import com.moodwalls.entity.AiInteraction;
import com.moodwalls.entity.Post;
import com.moodwalls.repository.AiInteractionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Service
public class AiService {

    private static final Logger log = LoggerFactory.getLogger(AiService.class);
    private static final String SYSTEM_PROMPT = "你是校园心理关怀助手「校园倾听树洞」，用温暖、简短、口语化中文回应，不说教，80 字以内。";
    private static final List<String> CRISIS_KEYWORDS = List.of(
            "不想活了", "自杀", "自残", "自伤", "结束生命", "活不下去",
            "想死", "割腕", "跳楼", "没人在乎我"
    );
    private static final String FALLBACK_RESPONSE = "你已经很努力了。先把这份情绪放在这里，慢慢呼吸一下，再给自己一点点缓冲空间。";

    private final RestTemplate restTemplate;
    private final AiInteractionRepository aiInteractionRepository;
    private final String apiUrl;
    private final String apiKey;
    private final String model;

    public AiService(
            AiInteractionRepository aiInteractionRepository,
            @Value("${moodwalls.ai.api-url:https://api.siliconflow.cn/v1/chat/completions}") String apiUrl,
            @Value("${moodwalls.ai.api-key:}") String apiKey,
            @Value("${moodwalls.ai.model:Qwen/Qwen2.5-7B-Instruct}") String model) {
        this.restTemplate = new RestTemplate();
        this.aiInteractionRepository = aiInteractionRepository;
        this.apiUrl = apiUrl;
        this.apiKey = apiKey;
        this.model = model;
    }

    public AiResponse supportPost(Post post, Long userId) {
        String prompt = buildSupportPrompt(post);
        String responseText = callAi(prompt);
        boolean isCrisis = detectCrisis(responseText, post.getContent());

        AiInteraction interaction = new AiInteraction();
        interaction.setUserId(userId);
        interaction.setPostId(post.getId());
        interaction.setScene("post_support");
        interaction.setPromptSnapshot(prompt);
        interaction.setResponseText(responseText);
        interaction.setIsCrisis(isCrisis ? 1 : 0);
        aiInteractionRepository.save(interaction);

        return new AiResponse(responseText, isCrisis);
    }

    public AiResponse generateOnPublish(Post post, Long userId) {
        String prompt = buildPublishPrompt(post);
        String responseText = callAi(prompt);
        boolean isCrisis = detectCrisis(responseText, post.getContent());

        AiInteraction interaction = new AiInteraction();
        interaction.setUserId(userId);
        interaction.setPostId(post.getId());
        interaction.setScene("post_publish");
        interaction.setPromptSnapshot(prompt);
        interaction.setResponseText(responseText);
        interaction.setIsCrisis(isCrisis ? 1 : 0);
        aiInteractionRepository.save(interaction);

        return new AiResponse(responseText, isCrisis);
    }

    public WeeklyReportResponse generateWeeklyReport(Long userId, String nickname, List<Post> recentPosts,
                                                       Map<String, Long> moodCounts, long postCount) {
        StringBuilder moodSummary = new StringBuilder();
        moodCounts.forEach((mood, count) -> moodSummary.append(mood).append(":").append(count).append("次 "));

        String prompt = String.format(
                "用户%s这周发了%d条心情帖，情绪分布：%s。请生成一段温暖的周报小结，80字以内，口语化。",
                nickname, postCount, moodSummary.toString());

        String report = callAi(prompt);
        boolean isCrisis = detectCrisis(report, moodSummary.toString());

        AiInteraction interaction = new AiInteraction();
        interaction.setUserId(userId);
        interaction.setScene("weekly_report");
        interaction.setPromptSnapshot(prompt);
        interaction.setResponseText(report);
        interaction.setIsCrisis(isCrisis ? 1 : 0);
        aiInteractionRepository.save(interaction);

        return new WeeklyReportResponse(report, moodCounts, postCount);
    }

    private String buildSupportPrompt(Post post) {
        return String.format("用户的心情是「%s」，他说：「%s」。请用温暖、简短、口语化中文回应，不说教，80字以内。",
                moodLabel(post.getMood()), post.getContent());
    }

    private String buildPublishPrompt(Post post) {
        return String.format("用户刚发布了一条心情，情绪是「%s」，内容：「%s」。请作为校园倾听树洞回应，温暖简短，80字以内。",
                moodLabel(post.getMood()), post.getContent());
    }

    private String callAi(String userPrompt) {
        if (apiKey.isEmpty()) {
            log.warn("AI API key not configured, using fallback response");
            return FALLBACK_RESPONSE;
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            Map<String, Object> requestBody = Map.of(
                    "model", model,
                    "messages", List.of(
                            Map.of("role", "system", "content", SYSTEM_PROMPT),
                            Map.of("role", "user", "content", userPrompt)
                    ),
                    "max_tokens", 200,
                    "temperature", 0.8
            );

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(apiUrl, request, Map.class);

            if (response.getBody() != null) {
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.getBody().get("choices");
                if (choices != null && !choices.isEmpty()) {
                    Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
                    if (message != null) {
                        return (String) message.get("content");
                    }
                }
            }
        } catch (Exception e) {
            log.error("AI API call failed", e);
        }
        return FALLBACK_RESPONSE;
    }

    private boolean detectCrisis(String response, String context) {
        String combined = (context + " " + response).toLowerCase();
        return CRISIS_KEYWORDS.stream().anyMatch(combined::contains);
    }

    private String moodLabel(String mood) {
        return switch (mood) {
            case "happy" -> "开心";
            case "calm" -> "平静";
            case "moved" -> "感动";
            case "tired" -> "疲惫";
            case "anxious" -> "焦虑";
            case "sad" -> "低落";
            case "angry" -> "生气";
            case "lonely" -> "孤单";
            default -> mood;
        };
    }

    public record AiResponse(String responseText, boolean isCrisis) {}
    public record WeeklyReportResponse(String report, Map<String, Long> moodSummary, long postCount) {}
}
