<?php

declare(strict_types=1);

namespace Decanet\Repository;

use Decanet\Application\Location;

final class StoredProcedureLocationRepository implements LocationRepository
{
    public function __construct(private readonly ProcedureCaller $procedures)
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

    public function schools(int $cityId): array
    {
        return $this->map($this->procedures->call('SCHOOL_LST', [$cityId]), 'SCHOOL', 'NAME', 'ABBR');
    }

    public function facultets(int $schoolId): array
    {
        return $this->map($this->procedures->call('FACULTET_LST', [$schoolId]), 'FACULTET', 'NAME', 'ABBR');
    }

    public function divisions(int $facultetId, ?bool $active = null): array
    {
        return $this->map(
            $this->procedures->call('DIVISION_LST', [$facultetId, $active === null ? null : (int) $active]),
            'DIVISION',
            'NAME',
            'ABBR',
            'ACTIVE',
        );
    }

    public function groups(int $divisionId, ?bool $active = null): array
    {
        return array_map(
            static fn (array $row): Location => new Location(
                (int) ($row['SGROUP_ID'] ?? 0),
                sprintf('%s (%s)', (string) ($row['SGROUP_AUTONAME'] ?? ''), (string) ($row['SGROUP_PERIOD'] ?? '')),
                null,
                isset($row['SGROUP_ACTIVE']) ? (bool) $row['SGROUP_ACTIVE'] : null,
            ),
            $this->procedures->call('SGROUP_LST', [$divisionId, $active === null ? null : (int) $active]),
        );
    }

    /** @param list<array<string, mixed>> $rows */
    /** @return list<Location> */
    private function map(
        array $rows,
        string $prefix,
        string $nameField = 'NAME',
        ?string $shortNameField = null,
        ?string $activeField = null,
    ): array
    {
        return array_map(
            static fn (array $row) => new Location(
                (int) ($row[$prefix . '_ID'] ?? 0),
                (string) ($row[$prefix . '_' . $nameField] ?? ''),
                $shortNameField === null || !isset($row[$prefix . '_' . $shortNameField])
                    ? null
                    : (string) $row[$prefix . '_' . $shortNameField],
                $activeField === null || !isset($row[$prefix . '_' . $activeField])
                    ? null
                    : (bool) $row[$prefix . '_' . $activeField],
            ),
            $rows,
        );
    }
}
