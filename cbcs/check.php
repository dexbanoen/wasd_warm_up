<?php
// Diagnostic page: open it first after copying the files to the server.
require 'config.php';
header('Content-Type: text/plain; charset=utf-8');
echo "PHP version: " . PHP_VERSION . "\n";
echo "pdo_mysql loaded: "
    . (extension_loaded('pdo_mysql') ? 'yes' : 'NO (ask AITS, or the site cannot connect)') . "\n";
try {
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME . ';charset=utf8mb4',
        DB_USER,
        DB_PASS,
        array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION)
    );
    echo "Connection: OK, MySQL " . $pdo->query('SELECT VERSION()')->fetchColumn() . "\n";
    echo "Tables: "
        . $pdo->query('SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = \'BASE TABLE\'')->fetchColumn()
        . " (expected 21)\n";
    echo "Triggers: "
        . $pdo->query('SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = DATABASE()')->fetchColumn()
        . " (expected 12)\n";
} catch (PDOException $e) {
    echo "Connection: FAILED - " . $e->getMessage() . "\n";
}
