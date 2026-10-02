<?php

declare(strict_types=1);

namespace Decanet\Tests\Infrastructure;

use Decanet\Infrastructure\ErrorHandler;
use PHPUnit\Framework\TestCase;

final class ErrorHandlerTest extends TestCase
{
    public function testItCanBeConstructedForProductionAndDebugModes(): void
    {
        self::assertInstanceOf(ErrorHandler::class, new ErrorHandler(false));
        self::assertInstanceOf(ErrorHandler::class, new ErrorHandler(true));
    }
}
