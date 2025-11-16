package com.aidoai.llmhub.core.model;

import lombok.Data;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * Base entity class
 */
@Data
public class BaseEntity implements Serializable {
    private static final long serialVersionUID = 1L;
    
    private Long id;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}

