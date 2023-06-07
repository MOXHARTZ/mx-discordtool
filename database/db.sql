CREATE TABLE IF NOT EXISTS `mx_banlist` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(80) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
    `fivem` VARCHAR(20) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
    `xbl` VARCHAR(80) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
    `license` VARCHAR(80) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
    `live` VARCHAR(80) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
    `discord` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
    `tokens` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
    `created` TIMESTAMP NULL DEFAULT current_timestamp(),
    `duration` INT(20) NULL DEFAULT NULL,
    `reason` MEDIUMTEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
    `bannedby` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
    PRIMARY KEY (`id`) USING BTREE
) COLLATE = 'utf8mb4_general_ci' ENGINE = InnoDB AUTO_INCREMENT = 1;

CREATE TABLE `mx_whitelist` (
    `identifier` VARCHAR(70) NOT NULL DEFAULT '0' COLLATE 'utf8mb4_general_ci',
    UNIQUE INDEX `identifier` (`identifier`) USING BTREE
) COLLATE = 'utf8mb4_general_ci' ENGINE = InnoDB;