<?php

declare(strict_types=1);

namespace Decanet\Tests\Security;

use PHPUnit\Framework\TestCase;

final class LegacySecurityHelpersTest extends TestCase
{
    public function testCsrfHelperIsAvailableBeforeOpeningDatabaseConnection(): void
    {
        require_once __DIR__ . '/../../src/stdfunc.php';

        self::assertTrue(function_exists('csrf_token'));
        self::assertTrue(function_exists('getdbrowproc'));
    }
}
