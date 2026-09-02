<?php

declare(strict_types=1);

namespace Decanet\Security;

use RuntimeException;

final class LegacySessionDatabaseCredentials
{
    /** @param array<string, mixed> $session */
    public static function fromSession(array $session): DatabaseCredentials
    {
        $user = $session['du_name'] ?? null;
        $password = $session['du_pass'] ?? null;
        if (!is_string($user) || !is_string($password)) {
            throw new RuntimeException('Authenticated database credentials are missing.');
        }

        return new DatabaseCredentials(self::decrypt($user), self::decrypt($password));
    }

    private static function decrypt(string $value): string
    {
        $key = hash('sha256', 'secret_key');
        $iv = mb_substr(hash('sha256', 'secret_iv'), 0, 16);
        $decrypted = openssl_decrypt(base64_decode($value, true) ?: '', 'AES-256-CBC', $key, 0, $iv);
        if (!is_string($decrypted) || $decrypted === '') {
            throw new RuntimeException('Unable to decrypt authenticated database credentials.');
        }

        return $decrypted;
    }
}
