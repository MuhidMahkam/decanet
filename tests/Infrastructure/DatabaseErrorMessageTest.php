<?php

declare(strict_types=1);

namespace Decanet\Tests\Infrastructure;

use Decanet\Infrastructure\DatabaseErrorMessage;
use PHPUnit\Framework\TestCase;

final class DatabaseErrorMessageTest extends TestCase
{
    public function testItReturnsSafeMessageForAccessDenied(): void
    {
        self::assertSame('Доступ к операции запрещен.', DatabaseErrorMessage::forCode(1370));
    }

    public function testItHidesOtherDatabaseErrorDetails(): void
    {
        self::assertStringNotContainsString('1234', DatabaseErrorMessage::forCode(1234));
    }
}
