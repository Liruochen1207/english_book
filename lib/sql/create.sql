
CREATE TABLE `word_table02`  (
                                 `word` varchar(255) CHARACTER SET utf8mb4  NOT NULL,
                                 `voice` varchar(30) CHARACTER SET utf8mb4  NOT NULL,
                                 `mean` varchar(255) CHARACTER SET utf8mb4  NOT NULL,
                                 `type` varchar(20) CHARACTER SET utf8mb4  NOT NULL,
                                 `cet4` tinyint(1) NULL DEFAULT NULL,
                                 `cet6` tinyint(1) NULL DEFAULT NULL,
                                 `gre` tinyint(1) NULL DEFAULT NULL,
                                 `toefl` tinyint(1) NULL DEFAULT NULL,
                                 `ielts` tinyint(1) NULL DEFAULT NULL,
                                 `postgraduate` tinyint(1) NULL DEFAULT NULL,
                                 `id` int(0) NOT NULL AUTO_INCREMENT,
                                 PRIMARY KEY (`id`, `word`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4  ROW_FORMAT = Dynamic;
