<?php

declare(strict_types=1);

namespace Decanet\Tests\Security;

use Decanet\Security\SessionCredentialCipher;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class SessionCredentialCipherTest extends TestCase
{
    protected function setUp(): void
    {
        putenv('SESSION_CREDENTIAL_KEY=test-key-that-is-longer-than-thirty-two-characters');
    }

    protected function tearDown(): void
    {
        putenv('SESSION_CREDENTIAL_KEY');
    }

    public function testItEncryptsCredentialsWithRandomNonces(): void
    {
        $first = SessionCredentialCipher::encrypt('password');
        $second = SessionCredentialCipher::encrypt('password');

        self::assertNotSame($first, $second);
        self::assertSame('password', SessionCredentialCipher::decrypt($first));
    }

    public function testItRejectsTamperedCredentials(): void
    {
        $this->expectException(RuntimeException::class);

        SessionCredentialCipher::decrypt(base64_encode('tampered'));
    }
}
