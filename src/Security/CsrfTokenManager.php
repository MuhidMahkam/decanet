<?php

declare(strict_types=1);

namespace Decanet\Security;

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

    public function validate(mixed $token): void
    {
        $expected = $_SESSION[self::SESSION_KEY] ?? null;
        if (!is_string($expected) || !is_string($token) || !hash_equals($expected, $token)) {
            throw new InvalidCsrfToken('Invalid CSRF token.');
        }
    }
}
