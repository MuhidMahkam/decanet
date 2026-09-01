<?php

declare(strict_types=1);

namespace Decanet\Infrastructure;

use ErrorException;
use Throwable;

final class ErrorHandler
{
    public function __construct(private readonly bool $debug)
    {
    }

    public function register(): void
    {
        set_error_handler(static function (int $severity, string $message, string $file, int $line): bool {
            if (!(error_reporting() & $severity)) {
                return false;
            }

            throw new ErrorException($message, 0, $severity, $file, $line);
        });

        set_exception_handler(function (Throwable $exception): void {
            error_log((string) $exception);
            http_response_code(500);
            header('Content-Type: text/plain; charset=UTF-8');
            echo $this->debug ? $exception->getMessage() : 'Internal server error';
        });
    }
}
