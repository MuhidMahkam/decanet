<?php

declare(strict_types=1);

namespace Decanet\Http;

final class Request
{
    /** @param array<string, mixed> $query */
    /** @param array<string, mixed> $post */
    private function __construct(
        public readonly string $method,
        public readonly string $path,
        public readonly array $query,
        public readonly array $post,
    ) {
    }

    public static function fromGlobals(): self
    {
        $uri = (string) ($_SERVER['REQUEST_URI'] ?? '/');
        $path = parse_url($uri, PHP_URL_PATH);

        return new self(
            strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET')),
            is_string($path) ? $path : '/',
            $_GET,
            $_POST,
        );
    }
}
