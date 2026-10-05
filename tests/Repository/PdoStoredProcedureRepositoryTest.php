<?php

declare(strict_types=1);

namespace Decanet\Tests\Repository;

use Decanet\Repository\PdoStoredProcedureRepository;
use PDO;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class PdoStoredProcedureRepositoryTest extends TestCase
{
    public function testItRejectsInvalidDatabaseNames(): void
    {
        $this->expectException(RuntimeException::class);

        new PdoStoredProcedureRepository($this->createMock(PDO::class), 'decanet; DROP DATABASE decanet');
    }

    public function testItRejectsInvalidProcedureNamesBeforeQuerying(): void
    {
        $repository = new PdoStoredProcedureRepository($this->createMock(PDO::class), 'decanet');

        $this->expectException(RuntimeException::class);
        $repository->call('COUNTRY_LST; DROP TABLE country');
    }
}
