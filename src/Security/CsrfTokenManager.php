<?php

declare(strict_types=1);

namespace Decanet\Security;

use RuntimeException;

final class CsrfTokenManager
{
    private const SESSION_KEY = '_csrf_token';

    public function token(): string
    {
        if (!isset($_SESSION[self::SESSION_KEY])) {
            $_SESSION[self::SESSION_KEY] = bin2hex(random_bytes(32));
        }

        return $_SESSION[self::SESSION_KEY];
    }

    public function validate(?string $token): void
    {
        if (!is_string($token) || !hash_equals($this->token(), $token)) {
            throw new RuntimeException('Invalid CSRF token.');
        }
    }
}
