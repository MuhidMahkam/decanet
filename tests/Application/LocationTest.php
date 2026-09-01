<?php

declare(strict_types=1);

namespace Decanet\Tests\Application;

use Decanet\Application\Location;
use PHPUnit\Framework\TestCase;

final class LocationTest extends TestCase
{
    public function testItRepresentsLocationData(): void
    {
        $location = new Location(10, 'Москва', 'МСК');

        self::assertSame(10, $location->id);
        self::assertSame('Москва', $location->name);
        self::assertSame('МСК', $location->shortName);
    }
}
