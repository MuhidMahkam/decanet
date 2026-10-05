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

        return new DatabaseCredentials(
            SessionCredentialCipher::decrypt($user),
            SessionCredentialCipher::decrypt($password),
        );
    }
}
