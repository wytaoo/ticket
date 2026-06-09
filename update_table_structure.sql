-- 客诉工单表结构更新脚本
-- 用于支持运单客诉记录和咨询人客诉记录功能

-- 1. 为客诉工单表添加历史记录关联字段
ALTER TABLE 客诉工单 ADD COLUMN IF NOT EXISTS 相关运单工单历史 TEXT COMMENT '该运单号的历史工单记录JSON';
ALTER TABLE 客诉工单 ADD COLUMN IF NOT EXISTS 相关咨询人工单历史 TEXT COMMENT '该咨询人（邮箱/电话）的历史工单记录JSON';
ALTER TABLE 客诉工单 ADD COLUMN IF NOT EXISTS 咨询人邮箱 VARCHAR(100) COMMENT '咨询人邮箱';
ALTER TABLE 客诉工单 ADD COLUMN IF NOT EXISTS 咨询人电话 VARCHAR(20) COMMENT '咨询人电话';
ALTER TABLE 客诉工单 ADD COLUMN IF NOT EXISTS 咨询人姓名 VARCHAR(50) COMMENT '咨询人姓名';

-- 2. 为index表添加历史记录关联字段
ALTER TABLE index ADD COLUMN IF NOT EXISTS 相关运单工单历史 TEXT COMMENT '该运单号的历史工单记录JSON';
ALTER TABLE index ADD COLUMN IF NOT EXISTS 相关咨询人工单历史 TEXT COMMENT '该咨询人（邮箱/电话）的历史工单记录JSON';
ALTER TABLE index ADD COLUMN IF NOT EXISTS 咨询人邮箱 VARCHAR(100) COMMENT '咨询人邮箱';
ALTER TABLE index ADD COLUMN IF NOT EXISTS 咨询人电话 VARCHAR(20) COMMENT '咨询人电话';
ALTER TABLE index ADD COLUMN IF NOT EXISTS 咨询人姓名 VARCHAR(50) COMMENT '咨询人姓名';

-- 3. 创建运单客诉记录历史表（可选，用于更高效的历史记录查询）
CREATE TABLE IF NOT EXISTS 运单客诉记录历史 (
    id INT AUTO_INCREMENT PRIMARY KEY,
    运单号 VARCHAR(50) NOT NULL COMMENT '运单号',
    工单号 VARCHAR(50) NOT NULL COMMENT '工单号',
    客诉大类 VARCHAR(50) COMMENT '客诉大类',
    客诉小类 VARCHAR(50) COMMENT '客诉小类',
    工单状态 VARCHAR(50) COMMENT '工单状态',
    处理结果 TEXT COMMENT '处理结果',
    创建时间 DATETIME COMMENT '工单创建时间',
    完结时间 DATETIME COMMENT '工单完结时间',
    创建时间戳 TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间戳',
    INDEX idx_运单号 (运单号),
    INDEX idx_工单号 (工单号),
    INDEX idx_创建时间 (创建时间)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='运单客诉记录历史表';

-- 4. 创建咨询人客诉记录历史表（可选，用于更高效的历史记录查询）
CREATE TABLE IF NOT EXISTS 咨询人客诉记录历史 (
    id INT AUTO_INCREMENT PRIMARY KEY,
    咨询人邮箱 VARCHAR(100) COMMENT '咨询人邮箱',
    咨询人电话 VARCHAR(20) COMMENT '咨询人电话',
    咨询人姓名 VARCHAR(50) COMMENT '咨询人姓名',
    工单号 VARCHAR(50) NOT NULL COMMENT '工单号',
    运单号 VARCHAR(50) COMMENT '运单号',
    客诉大类 VARCHAR(50) COMMENT '客诉大类',
    客诉小类 VARCHAR(50) COMMENT '客诉小类',
    工单状态 VARCHAR(50) COMMENT '工单状态',
    处理结果 TEXT COMMENT '处理结果',
    创建时间 DATETIME COMMENT '工单创建时间',
    完结时间 DATETIME COMMENT '工单完结时间',
    创建时间戳 TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间戳',
    INDEX idx_咨询人邮箱 (咨询人邮箱),
    INDEX idx_咨询人电话 (咨询人电话),
    INDEX idx_工单号 (工单号),
    INDEX idx_创建时间 (创建时间)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='咨询人客诉记录历史表';

-- 5. 添加触发器，在工单创建或更新时自动更新历史记录表
DELIMITER //

CREATE TRIGGER IF NOT EXISTS tr_运单客诉记录历史_insert
AFTER INSERT ON 客诉工单
FOR EACH ROW
BEGIN
    INSERT INTO 运单客诉记录历史 (
        运单号, 工单号, 客诉大类, 客诉小类, 工单状态, 处理结果, 创建时间, 完结时间
    ) VALUES (
        NEW.运单号, NEW.工单号, NEW.客诉大类, NEW.客诉小类, NEW.工单状态, NEW.处理结果, NEW.创建时间, NEW.完结时间
    );
END//

CREATE TRIGGER IF NOT EXISTS tr_运单客诉记录历史_update
AFTER UPDATE ON 客诉工单
FOR EACH ROW
BEGIN
    UPDATE 运单客诉记录历史 
    SET 
        工单状态 = NEW.工单状态,
        处理结果 = NEW.处理结果,
        完结时间 = NEW.完结时间
    WHERE 工单号 = NEW.工单号;
END//

CREATE TRIGGER IF NOT EXISTS tr_咨询人客诉记录历史_insert
AFTER INSERT ON 客诉工单
FOR EACH ROW
BEGIN
    INSERT INTO 咨询人客诉记录历史 (
        咨询人邮箱, 咨询人电话, 咨询人姓名, 工单号, 运单号, 客诉大类, 客诉小类, 工单状态, 处理结果, 创建时间, 完结时间
    ) VALUES (
        NEW.咨询人邮箱, NEW.咨询人电话, NEW.咨询人姓名, NEW.工单号, NEW.运单号, NEW.客诉大类, NEW.客诉小类, NEW.工单状态, NEW.处理结果, NEW.创建时间, NEW.完结时间
    );
END//

CREATE TRIGGER IF NOT EXISTS tr_咨询人客诉记录历史_update
AFTER UPDATE ON 客诉工单
FOR EACH ROW
BEGIN
    UPDATE 咨询人客诉记录历史 
    SET 
        工单状态 = NEW.工单状态,
        处理结果 = NEW.处理结果,
        完结时间 = NEW.完结时间
    WHERE 工单号 = NEW.工单号;
END//

DELIMITER ;

-- 6. 创建视图，方便查询运单客诉记录
CREATE OR REPLACE VIEW v_运单客诉记录 AS
SELECT 
    运单号,
    工单号,
    客诉大类,
    客诉小类,
    工单状态,
    处理结果,
    创建时间,
    完结时间,
    ROW_NUMBER() OVER (PARTITION BY 运单号 ORDER BY 创建时间 DESC) as 记录序号
FROM 运单客诉记录历史
ORDER BY 运单号, 创建时间 DESC;

-- 7. 创建视图，方便查询咨询人客诉记录
CREATE OR REPLACE VIEW v_咨询人客诉记录 AS
SELECT 
    咨询人邮箱,
    咨询人电话,
    咨询人姓名,
    工单号,
    运单号,
    客诉大类,
    客诉小类,
    工单状态,
    处理结果,
    创建时间,
    完结时间,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(咨询人邮箱, 咨询人电话) ORDER BY 创建时间 DESC) as 记录序号
FROM 咨询人客诉记录历史
WHERE 咨询人邮箱 IS NOT NULL OR 咨询人电话 IS NOT NULL
ORDER BY COALESCE(咨询人邮箱, 咨询人电话), 创建时间 DESC;

-- 8. 添加索引优化查询性能
ALTER TABLE 客诉工单 ADD INDEX IF NOT EXISTS idx_咨询人邮箱 (咨询人邮箱);
ALTER TABLE 客诉工单 ADD INDEX IF NOT EXISTS idx_咨询人电话 (咨询人电话);
ALTER TABLE index ADD INDEX IF NOT EXISTS idx_咨询人邮箱 (咨询人邮箱);
ALTER TABLE index ADD INDEX IF NOT EXISTS idx_咨询人电话 (咨询人电话);

-- 9. 创建存储过程，用于获取运单客诉记录
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS sp_获取运单客诉记录(IN p_运单号 VARCHAR(50))
BEGIN
    SELECT 
        工单号,
        客诉大类,
        客诉小类,
        工单状态,
        处理结果,
        创建时间,
        完结时间
    FROM 运单客诉记录历史
    WHERE 运单号 = p_运单号
    ORDER BY 创建时间 DESC;
END//

-- 10. 创建存储过程，用于获取咨询人客诉记录
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS sp_获取咨询人客诉记录(IN p_邮箱 VARCHAR(100), IN p_电话 VARCHAR(20))
BEGIN
    SELECT 
        工单号,
        运单号,
        客诉大类,
        客诉小类,
        工单状态,
        处理结果,
        创建时间,
        完结时间
    FROM 咨询人客诉记录历史
    WHERE (咨询人邮箱 = p_邮箱 OR 咨询人电话 = p_电话)
    ORDER BY 创建时间 DESC;
END//

DELIMITER ;

-- 说明：
-- 1. 此脚本为客诉工单管理系统添加了运单客诉记录和咨询人客诉记录功能
-- 2. 创建了两个历史记录表用于存储客诉历史数据
-- 3. 添加了触发器自动维护历史记录
-- 4. 创建了视图和存储过程方便查询
-- 5. 添加了索引优化查询性能
-- 6. 支持按运单号和咨询人（邮箱/电话）查询历史客诉记录