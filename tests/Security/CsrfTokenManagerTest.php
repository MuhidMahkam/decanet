<?php

declare(strict_types=1);

namespace Decanet\Tests\Security;

use Decanet\Security\CsrfTokenManager;
use Decanet\Security\InvalidCsrfToken;
use PHPUnit\Framework\TestCase;

final class CsrfTokenManagerTest extends TestCase
{
    protected function setUp(): void
    {
        $_SESSION = [];
    }

    public function testItRejectsAnExpiredOrInvalidToken(): void
    {
        $this->expectException(InvalidCsrfToken::class);
        $this->expectExceptionMessage('Invalid CSRF token.');

        (new CsrfTokenManager())->validate('expired-token');
    }

    public function testItRejectsAMalformedToken(): void
    {
        $this->expectException(InvalidCsrfToken::class);
        $this->expectExceptionMessage('Invalid CSRF token.');

        (new CsrfTokenManager())->validate(['unexpected']);
    }

    public function testItRejectsATokenWhenTheSessionTokenIsMissing(): void
    {
        $this->expectException(InvalidCsrfToken::class);

        (new CsrfTokenManager())->validate('submitted-token');
    }
}
