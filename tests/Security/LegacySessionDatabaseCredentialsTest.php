<?php

declare(strict_types=1);

namespace Decanet\Tests\Security;

use Decanet\Security\LegacySessionDatabaseCredentials;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class LegacySessionDatabaseCredentialsTest extends TestCase
{
    public function testItRejectsGuestSessionsWithoutAuthenticatedCredentials(): void
    {
        $this->expectException(RuntimeException::class);

        LegacySessionDatabaseCredentials::fromSession([]);
    }
}
