package com.moodwalls.service;

import com.moodwalls.entity.AiInteraction;
import com.moodwalls.entity.Post;
import com.moodwalls.repository.AiInteractionRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

@Service
public class AiService {

    private static final Logger log = LoggerFactory.getLogger(AiService.class);
    private static final String SYSTEM_PROMPT = "你是校园心理关怀助手「校园倾听树洞」，用温暖、简短、口语化中文回应，不说教。不要添加任何解释、注释或对自身回复的分析。";
    private static final String WEEKLY_SYSTEM_PROMPT = "你是校园心理关怀助手「校园倾听树洞」。请根据用户本周的情绪数据，生成一份温暖、深入、有洞察力的情绪周报。" +
            "周报应该像一位懂你的朋友在认真谈心，字数不少于200字，可以展开到350字。" +
            "内容应包含：1) 本周情绪整体回顾与共鸣 2) 对关键情绪时刻的细致解读 3) 温和的鼓励与下周展望。" +
            "不要只是简单总结数据，要结合帖子内容给出有温度的分析和陪伴感。" +
            "请在合适的位置自然地使用 emoji（如😊💪🌈☀️🍃🌙💤），让周报更有温度，但不要堆砌。";
    /** Level 2: extreme danger — self-harm / suicidal ideation */
    private static final List<String> CRISIS_KEYWORDS = List.of(
            "不想活了", "自杀", "自残", "自伤", "结束生命", "活不下去",
            "想死", "割腕", "跳楼", "没人在乎我", "不想存在", "想放弃一切",
            "想消失", "没意义活着", "想结束", "世界没意义", "没人需要我",
            "死了算了", "活得没劲", "一了百了"
    );
    /** Level 1: mild negative — needs comfort support */
    private static final List<String> CONCERN_KEYWORDS = List.of(
            "伤心", "低落", "难过", "焦虑", "失眠", "压力", "孤单", "迷茫",
            "崩溃", "绝望", "无助", "委屈", "疲惫", "烦躁", "害怕", "后悔",
            "好累", "撑不住", "想哭", "难受", "抑郁", "空虚", "失落",
            "被孤立", "被欺负", "没人理解", "心累", "喘不过气", "不安"
    );

    private static final String COMFORT_NOTE = "我们都有低落的时候，这很正常。先给自己泡杯热饮，什么都不想，安静待一会儿 ☕";
    private static final String CRISIS_NOTE = "你不需要独自承担这些。全国心理援助热线：400-161-9995，24小时在线，随时可以拨打倾诉。";
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
        int riskLevel = detectRiskLevel(post.getContent());

        AiInteraction interaction = new AiInteraction();
        interaction.setUserId(userId);
        interaction.setPostId(post.getId());
        interaction.setScene("post_support");
        interaction.setPromptSnapshot(prompt);
        interaction.setResponseText(responseText);
        interaction.setIsCrisis(riskLevel >= 2 ? 1 : 0);
        aiInteractionRepository.save(interaction);

        return new AiResponse(responseText, riskLevel);
    }

    public AiResponse generateOnPublish(Post post, Long userId) {
        String prompt = buildPublishPrompt(post);
        String responseText = callAi(prompt);
        int riskLevel = detectRiskLevel(post.getContent());

        AiInteraction interaction = new AiInteraction();
        interaction.setUserId(userId);
        interaction.setPostId(post.getId());
        interaction.setScene("post_publish");
        interaction.setPromptSnapshot(prompt);
        interaction.setResponseText(responseText);
        interaction.setIsCrisis(riskLevel >= 2 ? 1 : 0);
        aiInteractionRepository.save(interaction);

        return new AiResponse(responseText, riskLevel);
    }

    public WeeklyReportResponse generateWeeklyReport(Long userId, String nickname, List<Post> recentPosts,
                                                       Map<String, Long> moodCounts, long postCount) {
        String prompt = buildWeeklyReportPrompt(nickname, postCount, moodCounts, recentPosts);
        String report = callAi(prompt, WEEKLY_SYSTEM_PROMPT, 800);
        StringBuilder moodSummary = new StringBuilder();
        moodCounts.forEach((mood, count) -> moodSummary.append(moodLabel(mood)).append(count).append("次 "));
        int riskLevel = detectRiskLevel(moodSummary.toString());
        boolean isCrisis = riskLevel >= 2;

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

    private String buildWeeklyReportPrompt(String nickname, long postCount, Map<String, Long> moodCounts, List<Post> recentPosts) {
        StringBuilder moodSummary = new StringBuilder();
        moodCounts.forEach((mood, count) -> moodSummary.append(moodLabel(mood)).append(count).append("次 "));

        StringBuilder contentSnippets = new StringBuilder();
        int snippetCount = 0;
        for (Post post : recentPosts) {
            if (snippetCount >= 5) break;
            String content = post.getContent();
            String snippet = content.length() > 30 ? content.substring(0, 30) + "..." : content;
            contentSnippets.append("- [").append(moodLabel(post.getMood())).append("] ").append(snippet).append("\n");
            snippetCount++;
        }

        return String.format(
                "用户「%s」这一周发了%d条心情帖。\n情绪分布：%s\n部分帖子内容：\n%s\n请根据以上数据，生成一份有深度、有温度的周报。" +
                        "要求：1) 先整体回顾本周情绪状态 2) 结合具体的帖子内容做细致解读 3) 给出真诚的鼓励和下周小建议。" +
                        "至少写200字，可以展开到350字。不要草草了事，语气像朋友谈心，温暖但不敷衍。" +
                        "周报结尾请署名「——心墙」，除此之外不要添加任何注释、备注或「注」。",
                nickname, postCount, moodSummary.toString(), contentSnippets.toString());
    }

    private String callAi(String userPrompt) {
        return callAi(userPrompt, SYSTEM_PROMPT, 200);
    }

    private String callAi(String userPrompt, String systemPrompt, int maxTokens) {
        if (apiKey == null || apiKey.isEmpty()) {
            log.warn("AI API key not configured, using fallback response. apiKey={}", apiKey);
            return FALLBACK_RESPONSE;
        }
        log.info("AI call - model={}, maxTokens={}, prompt length={}", model, maxTokens, userPrompt.length());

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            Map<String, Object> requestBody = Map.of(
                    "model", model,
                    "messages", List.of(
                            Map.of("role", "system", "content", systemPrompt),
                            Map.of("role", "user", "content", userPrompt)
                    ),
                    "max_tokens", maxTokens,
                    "temperature", 0.8
            );

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(apiUrl, request, Map.class);

            if (response.getBody() != null) {
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.getBody().get("choices");
                if (choices != null && !choices.isEmpty()) {
                    Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
                    if (message != null) {
                        String content = (String) message.get("content");
                        log.info("AI response received, length={}", content != null ? content.length() : 0);
                        return content;
                    }
                }
            }
        } catch (Exception e) {
            log.error("AI API call failed: {}", e.getMessage(), e);
        }
        return FALLBACK_RESPONSE;
    }

    /** Returns 0 = normal, 1 = mild concern, 2 = crisis */
    private int detectRiskLevel(String context) {
        String lower = context.toLowerCase();
        if (CRISIS_KEYWORDS.stream().anyMatch(lower::contains)) {
            return 2;
        }
        if (CONCERN_KEYWORDS.stream().anyMatch(lower::contains)) {
            return 1;
        }
        return 0;
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

    public record AiResponse(String responseText, int riskLevel) {}

    public String buildSupportPromptForStream(Post post) {
        return buildSupportPrompt(post);
    }

    public static String getSystemPrompt() {
        return SYSTEM_PROMPT;
    }

    public void streamCallAi(String userPrompt, String systemPrompt, int maxTokens, Consumer<String> onToken) {
        if (apiKey.isEmpty()) {
            for (char c : FALLBACK_RESPONSE.toCharArray()) {
                onToken.accept(String.valueOf(c));
                try { Thread.sleep(30); } catch (InterruptedException e) { Thread.currentThread().interrupt(); break; }
            }
            return;
        }

        try {
            ObjectMapper mapper = new ObjectMapper();
            Map<String, Object> requestBody = Map.of(
                    "model", model,
                    "messages", List.of(
                            Map.of("role", "system", "content", systemPrompt),
                            Map.of("role", "user", "content", userPrompt)
                    ),
                    "max_tokens", maxTokens,
                    "temperature", 0.8,
                    "stream", true
            );
            String jsonBody = mapper.writeValueAsString(requestBody);

            HttpURLConnection conn = (HttpURLConnection) URI.create(apiUrl).toURL().openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Authorization", "Bearer " + apiKey);
            conn.setDoOutput(true);
            conn.setConnectTimeout(20000);
            conn.setReadTimeout(60000);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
            }

            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                StringBuilder content = new StringBuilder();
                while ((line = reader.readLine()) != null) {
                    if (line.startsWith("data: ")) {
                        String data = line.substring(6);
                        if ("[DONE]".equals(data.trim())) {
                            break;
                        }
                        try {
                            Map<String, Object> chunk = mapper.readValue(data, Map.class);
                            @SuppressWarnings("unchecked")
                            List<Map<String, Object>> choices = (List<Map<String, Object>>) chunk.get("choices");
                            if (choices != null && !choices.isEmpty()) {
                                Map<String, Object> delta = (Map<String, Object>) choices.get(0).get("delta");
                                if (delta != null && delta.get("content") != null) {
                                    String token = (String) delta.get("content");
                                    if (!token.isEmpty()) {
                                        content.append(token);
                                        onToken.accept(token);
                                    }
                                }
                            }
                        } catch (Exception e) {
                            log.warn("Failed to parse SSE chunk: {}", data, e);
                        }
                    }
                }
            }
            conn.disconnect();
        } catch (Exception e) {
            log.error("AI streaming call failed", e);
            onToken.accept(FALLBACK_RESPONSE);
        }
    }

    public String getComfortNote(int riskLevel) {
        return switch (riskLevel) {
            case 2 -> CRISIS_NOTE;
            case 1 -> COMFORT_NOTE;
            default -> "";
        };
    }
    public record WeeklyReportResponse(String report, Map<String, Long> moodSummary, long postCount) {}
}
