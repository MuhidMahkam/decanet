<?php

declare(strict_types=1);

namespace Decanet\Infrastructure\Config;

use RuntimeException;

final class AppConfig
{
    private function __construct(
        public readonly string $environment,
        public readonly bool $debug,
        public readonly string $databaseHost,
        public readonly int $databasePort,
        public readonly string $databaseName,
        public readonly string $databaseUser,
        public readonly string $databasePassword,
        public readonly int $sessionLifetime,
    ) {
    }

    public static function fromEnvironment(string $projectDirectory): self
    {
        self::loadDotEnv($projectDirectory . '/.env');

        return new self(
            self::value('APP_ENV', 'production'),
            filter_var(self::value('APP_DEBUG', 'false'), FILTER_VALIDATE_BOOL),
            self::value('DB_HOST', 'localhost'),
            (int) self::value('DB_PORT', '3306'),
            self::value('DB_NAME', 'decanet'),
            self::value('DB_USER', ''),
            self::value('DB_PASSWORD', ''),
            (int) self::value('SESSION_LIFETIME', '120'),
        );
    }

    public function isDebug(): bool
    {
        return $this->debug;
    }

    private static function value(string $name, ?string $default = null): string
    {
        $value = getenv($name);
        if ($value !== false) {
            return $value;
        }
        if ($default !== null) {
            return $default;
        }

        throw new RuntimeException(sprintf('Missing required environment variable "%s".', $name));
    }

    private static function loadDotEnv(string $file): void
    {
        if (!is_file($file)) {
            return;
        }

        foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#')) {
                continue;
            }
            [$name, $value] = array_pad(explode('=', $line, 2), 2, '');
            if (preg_match('/^[A-Z][A-Z0-9_]*$/', $name) !== 1) {
                throw new RuntimeException('Invalid environment variable name.');
            }
            putenv(sprintf('%s=%s', $name, trim($value, " \t\n\r\0\x0B\"'")));
        }
    }
}
