<?php

declare(strict_types=1);

namespace Decanet\Http;

final readonly class Response
{
    /** @param array<string, string> $headers */
    public function __construct(
        public string $body = '',
        public int $status = 200,
        public array $headers = [],
    ) {
    }

    public static function redirect(string $location): self
    {
        return new self('', 302, ['Location' => $location]);
    }
}
