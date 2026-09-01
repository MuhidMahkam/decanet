<?php

declare(strict_types=1);

namespace Decanet\Repository;

use Decanet\Application\Location;

final class StoredProcedureLocationRepository implements LocationRepository
{
    public function __construct(private readonly StoredProcedureRepository $procedures)
    {
    }

    public function countries(): array
    {
        return $this->map($this->procedures->call('COUNTRY_LST', [1]), 'COUNTRY', 'SNAME');
    }

    public function regions(int $countryId): array
    {
        return $this->map($this->procedures->call('REGION_LST', [$countryId]), 'REGION');
    }

    public function cities(int $regionId): array
    {
        return $this->map($this->procedures->call('CITY_LST', [$regionId]), 'CITY');
    }

    /** @param list<array<string, mixed>> $rows */
    /** @return list<Location> */
    private function map(array $rows, string $prefix, string $nameField = 'NAME'): array
    {
        return array_map(
            static fn (array $row): Location => new Location(
                (int) ($row[$prefix . '_ID'] ?? 0),
                (string) ($row[$prefix . '_' . $nameField] ?? ''),
                isset($row[$prefix . '_SNAME']) ? (string) $row[$prefix . '_SNAME'] : null,
            ),
            $rows,
        );
    }
}
