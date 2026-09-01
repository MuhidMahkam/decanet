<?php

declare(strict_types=1);

namespace Decanet\Tests\Security;

use PHPUnit\Framework\TestCase;

final class LegacySessionBootstrapTest extends TestCase
{
    public function testLegacyHelpersDoNotStartAnotherSession(): void
    {
        $source = file_get_contents(__DIR__ . '/../../src/stdfunc.php');

        self::assertIsString($source);
        self::assertStringNotContainsString('session_start(', $source);
    }
}
