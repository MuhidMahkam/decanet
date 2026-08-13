<?php
// phinx configuration (simple, file-based)
return [
    'paths' => [
        'migrations' => 'db/migrations',
        'seeds' => 'db/seeds'
    ],

    'environments' => [
        'default_migration_table' => 'phinxlog',
        'default_environment' => 'development',
        'development' => [
            'adapter' => 'mysql',
            'host' => getenv('DB_HOST') ?: '127.0.0.1',
            'name' => getenv('DB_NAME') ?: 'decanet',
            'user' => getenv('DB_USER') ?: 'root',
            'pass' => getenv('DB_PASS') ?: '',
            'port' => getenv('DB_PORT') ?: 3306,
            'charset' => 'utf8mb4',
        ],
    ],

    'version_order' => 'creation'
];
?>