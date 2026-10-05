<?php

declare(strict_types=1);

namespace Decanet\Tests\Security;

use Decanet\Security\CsrfTokenManager;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class CsrfTokenManagerTest extends TestCase
{
    protected function setUp(): void
    {
        $_SESSION = [];
    }

    public function testItRejectsAnExpiredOrInvalidToken(): void
    {
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Invalid CSRF token.');

        (new CsrfTokenManager())->validate('expired-token');
    }

    public function testItRejectsAMalformedToken(): void
    {
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Invalid CSRF token.');

        (new CsrfTokenManager())->validate(['unexpected']);
    }
}
