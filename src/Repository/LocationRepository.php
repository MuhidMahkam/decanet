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
}
