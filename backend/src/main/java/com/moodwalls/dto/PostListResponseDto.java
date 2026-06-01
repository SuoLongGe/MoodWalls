package com.moodwalls.dto;

import java.util.ArrayList;
import java.util.List;

public class PostListResponseDto {

    private List<PostSummaryDto> list = new ArrayList<>();
    private long total;
    private int page;
    private int size;
    private boolean hasMore;

    public List<PostSummaryDto> getList() {
        return list;
    }

    public void setList(List<PostSummaryDto> list) {
        this.list = list;
    }

    public long getTotal() {
        return total;
    }

    public void setTotal(long total) {
        this.total = total;
    }

    public int getPage() {
        return page;
    }

    public void setPage(int page) {
        this.page = page;
    }

    public int getSize() {
        return size;
    }

    public void setSize(int size) {
        this.size = size;
    }

    public boolean isHasMore() {
        return hasMore;
    }

    public void setHasMore(boolean hasMore) {
        this.hasMore = hasMore;
    }
}
