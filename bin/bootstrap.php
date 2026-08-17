<?php
declare(strict_types=1);

// bin/bootstrap.php
// CLI / CI bootstrap: init autoload and a PDO connection from env vars.

require_once __DIR__ . '/../vendor/autoload.php';

$config = [
  'host'    => getenv('DB_HOST') ?: '127.0.0.1',
  'port'    => getenv('DB_PORT') ?: '3306',
  'db'      => getenv('DB_NAME') ?: 'decanet_test',
  'user'    => getenv('DB_USER') ?: 'root',
  'pass'    => getenv('DB_PASS') ?: 'root',
  'charset' => getenv('DB_CHARSET') ?: 'utf8mb4',
];

try {
    $GLOBALS['APP_PDO'] = new \decanet\Database\PdoDb($config);
} catch (Throwable $e) {
    fwrite(STDERR, "DB init failed: " . $e->getMessage() . PHP_EOL);
    exit(1);
}