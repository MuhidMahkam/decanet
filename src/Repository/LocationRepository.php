<?php

declare(strict_types=1);

namespace Decanet\Repository;

use Decanet\Application\Location;

interface LocationRepository
{
    /** @return list<Location> */
    public function countries(): array;

    /** @return list<Location> */
    public function regions(int $countryId): array;

    /** @return list<Location> */
    public function cities(int $regionId): array;

    /** @return list<Location> */
    public function schools(int $cityId): array;

    /** @return list<Location> */
    public function facultets(int $schoolId): array;

    /** @return list<Location> */
    public function divisions(int $facultetId, ?bool $active = null): array;

    /** @return list<Location> */
    public function groups(int $divisionId, ?bool $active = null): array;
}
